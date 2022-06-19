package RF::Component;

use strict;
use warnings;

use Math::Complex;
use Math::Matrix::Complex;

our %valid_opts = map { $_ => 1 } qw/measurements z n_ports comments/;

sub new
{
	my ($class, %args) = @_;

	foreach (keys %args)
	{
		die "$class: invalid class option: $_ => $args{$_}" if !defined($valid_opts{$_});
	}

	my $self = bless(\%args, $class);

	return $self;
}

# Takes a port# (not an array index), so $component->z0(1) is the impedance at port1.
sub z0
{
	my ($self, $port) = @_;

	$port //= 1;

	my $z = $self->{z}[$port-1];

	die "z0 is not defined for port $port" if (!defined $z);

	return $z;
}

sub n_ports
{
	return shift->{n_ports};
}

sub comments
{
	return @{ shift->{comments} // [] };
}

sub measurements
{
	return @{ shift->{measurements} // [] };
}


sub get_measurement
{
	my ($self, $hz) = @_;

	my $prev;
	my $cur;
	for my $s (@{ $self->{measurements} })
	{
		$cur = $s;
		#print "hz=$hz cur=" . $cur->hz . "\n";
		if ($cur->hz >= $hz)
		{
			last;
		}

		$prev = $cur;
	}

	# Exact match, return this one:
	return $cur if ($cur->hz == $hz);

	die "unable to find Hz for evaluation at $hz" if (!defined $prev);

	my $prev_hz = $prev->hz;
	my $cur_hz = $cur->hz;

	#print "prev: $prev_hz=" . $prev->tostring('ma') . "\n";
	#print "cur : $cur_hz=" . $cur->tostring('ma') . "\n";

	my $hz_diff = $cur_hz - $prev_hz;
	my $hz_off = $hz - $prev_hz;

	# Return the complex matrix scaled $p percent of the way between $prev and $cur:
	# https://math.stackexchange.com/q/4451400/983059
	my $p = ($hz - $prev_hz)/$hz_diff;
	my $ret = (1-$p)*$prev->params + $p*$cur->params;

	# If interpolated, instatiate a new class instance
	# and make sure it is the same class type because
	# 'params' could be S-, Y-, Z-params, etc.
	return $cur->clone(ref($cur), params => $ret);
}

