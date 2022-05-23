package RF::S2P;

use strict;
use warnings;

use Math::Complex;
use Math::Matrix::Complex;
use Data::Dumper;

use RF::S2P::Measurement::SParam;
use RF::S2P::Measurement::YParam;

sub new
{
	my ($class, %args) = @_;

	my $self = bless(\%args, $class);

	return $self;
}

sub get_param
{
	my ($self, $hz) = @_;

	my $prev;
	my $cur;
	for my $s (@{ $self->{params} })
	{
		$cur = $s;
		#print "hz=$hz cur=" . $cur->hz . "\n";
		if ($cur->hz >= $hz)
		{
			last;
		}

		$prev = $cur;
	}

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

	# if interpolated, instatiate a new class instance
	# and make sure it is the same class type because
	# 'params' could be S-, Y-, Z-params, etc.
	my $class = ref($cur);
	my %opts = %$cur;
	delete $opts{params};
	delete $opts{hz};
	return $class->new(%opts, hz => $hz, params => $ret);
}

sub load
{
	my ($self, $fn) = @_;

	my $class;
	my ($funit, $param, $fmt, $R, $z0);

	open(my $in, $fn) or die "$fn: $!";

	my $n = 0;
	my $line;
	while (defined($line = <$in>))
	{
		chomp($line);
		$n++;

		if ($line =~ /^!/)
		{
			push @{ $self->{comments} }, $line;
			next;
		}

		#print "$line\n";

		warn "unknown line $n: $line\n" if ($line !~ /\s*\d+/);

		if ($line =~ s/^#\s*//)
		{
			($funit, $param, $fmt, $R, $z0) = split /\s+/, $line;

			die "z0 != 50 ohms: $z0" if $z0 != 50;
			die "param != S: $param" if $param ne 'S';
			die "R != R: $R" if $R ne 'R';
			next;
		}

		$self->{z0} = $z0;
		$self->{param_type} = $param;

		if ($self->{param_type} eq 'S') {
			$class = 'RF::S2P::Measurement::SParam';
		}
		elsif ($self->{param_type} eq 'Y') {
			$class = 'RF::S2P::Measurement::YParam';
		}
		else
		{
			warn "$self->{param_type}-parameter type is not implemented, using base class.";
			$class = 'RF::S2P::Measurement';
		}

		$line =~ s/^\s+|\s+$//g;
		my @params = split(/\s+/, $line);
		my $hz = shift(@params);
		my @params_cx;

		foreach my $pair (pairs(@params))
		{
			push @params_cx, params_to_complex($fmt, @$pair);
		}

		$hz = scale_to_hz($funit, $hz);

		my $n_ports = sqrt(scalar @params_cx);

		#my $m = Math::Matrix->new(map {[]} (1..$n_ports));

		my $m = [];
		for (my $i = 0; $i < $n_ports; $i++)
		{
			for (my $j = 0; $j < $n_ports; $j++)
			{
				$m->[$j][$i] = shift @params_cx;
			}
		}

		$m = Math::Matrix::Complex->new($m);

		push @{ $self->{params} },
			$class->new(z0 => $z0, hz => $hz, params => $m);
	}
}

sub save
{
	my ($self, $fn, $fmt) = @_;

	open(my $out, '>', $fn) or die "$fn: $!";

	my %fmts =
	(
		db => 1,
		ma => 1,
		ri => 1,
	);

	$fmt = lc($fmt);
	die "unknown format: $fmt" if (!defined($fmts{$fmt}));
	$fmt = uc($fmt);

	print $out join("\n", @{ $self->{comments} // [] }) . "\n";
	print $out "# MHz $self->{param} $fmt R $self->{z0}\n";
	foreach my $meas (@{ $self->{params} })
	{
		print $out "" . ($meas->{hz}/1e6) . " " . $meas->tostring($fmt) . "\n";
	}
	close($out);
}

sub scale_to_hz
{
	my ($funit, $n) = @_;

	my %scale = 
	(
		hz => 1,
		khz => 1e3,
		mhz => 1e6,
		ghz => 1e9,
		thz => 1e12,
	);

	my $fscale = $scale{lc($funit)};

	die "Unknown frequency scale: $fscale" if !$fscale;

	return $n*$fscale;
}

# https://physics.stackexchange.com/questions/398988/converting-magnitude-ratio-to-complex-form
sub params_to_complex
{
	my ($fmt, $a, $b) = @_;

	my %conv = (
		'RI' => sub {
				return Math::Complex->make($a, $b);
			},

		'MA' => sub {
				return Math::Complex->make($a*cos($b*pi()/180), $a*sin($b*pi()/180));
			}
	);

	my $f = $conv{uc($fmt)};
	die "Unknown s-parameter format: $fmt" if !$f;

	return $f->();
}

sub pairs
{
	my @in = @_;
	my @ret;
	while (@in)
	{
		push @ret, [ shift @in, shift @in ];
	}

	return @ret;
}

1;
