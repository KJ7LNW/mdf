package RF::S2P::Measurement;

use strict;
use warnings;

use Math::Complex;
use Math::Trig;
use RF::S2P::Measurement::SParam;
use RF::S2P::Measurement::YParam;
use RF::S2P::Measurement::ZParam;
use RF::S2P::Measurement::TParam;

use Data::Dumper;

our %valid_opts = map { $_ => 1 } qw/z0 params hz/;

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

sub clone
{
	my ($self, $newclass, %args) = @_;

	my $class = ref($self);

	my %h = %$self;

	# Remove class-privates:
	delete $h{$_} foreach (grep { /^_/ } keys %h);

	return $newclass->new(%h, %args);
}

# Member access functions:
sub z0 { return shift->{z0}; }

sub hz { return shift->{hz}; }



sub to_X_param
{
	my ($self, $type) = @_;

	$type = uc($type);

	my $class = "RF::S2P::Measurement::${type}Param";

	return $class->from_sparam($self->to_sparam);
}

# to_sparam and from_sparam must be implemented in each class.  
# Subclassing from/to_y/z/tparam() functions is optional:
sub to_sparam { die "to_sparam: not implemented in " . ref(shift); }

sub to_yparam { return shift->to_X_param('y'); }
sub to_zparam { return shift->to_X_param('z'); }
sub to_tparam { return shift->to_X_param('t'); }

sub from_sparam { die "from_sparam: not implemented in " . ref(shift); }
sub from_zparam { die "from_zparam: not implemented in " . ref(shift); }
sub from_yparam { die "from_yparam: not implemented in " . ref(shift); }

# srf: Self-resonating frequency.
#
# This may not be accurate.  While the equasion is a classic
# SRF calculation (1/(2*pi*sqrt(LC)), srf should instead be an RF::S2P function and 
# scan the frequency lines as follows:
#    "The SRF is determined to be the fre-quency at which the insertion (S21)
#    phase changes from negative through zero to positive."
#    [ https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363_measuringsrf.pdf ]
sub srf
{
	my $self = shift;

	return 1/sqrt( abs 2*pi*$self->inductance*$self->capacitance);
}

# For example, to get S21:
#   $s21 = $self->params(2,1) 
#
# or for the matrix object:
#   $m = $self->params;
sub params
{
	my ($self, $j, $i) = @_;

	if (defined($j) and defined($i))
	{
		return $self->{params}->[$j-1][$i-1];
	}
	else
	{
		return $self->{params};
	}
}

# Shortcut to matrix or index functions:
sub S { return shift->to_sparam->params(@_) }
sub Y { return shift->to_yparam->params(@_) }
sub Z { return shift->to_zparam->params(@_) }
sub T { return shift->to_tparam->params(@_) }

# Functions converting to flat arrays in touchstone-format column-major order:
sub params_array
{
	return  @{ shift->params->to_col()->to_row()->[0] };
}

sub ri
{
	return map { [ Re($_), Im($_) ] } shift->params_array;
}

sub db_ang
{
	return map { [ 20*log(abs($_))/log(10), cang($_) ] } shift->params_array;
}

sub mag_ang
{
	return map { [ abs($_), cang($_) ] } shift->params_array;
}

sub tostring
{
	my ($self, $fmt, $pretty) = @_;

	my %fmts =
	(
		db => 1,
		ma => 1,
		ri => 1,
		complex => 1,
		cx => 1,
	);

	$fmt = lc($fmt);

	die "unknown format: $fmt" if (!defined($fmts{$fmt}));

	my @data;
	@data = $self->db_ang if $fmt eq 'db';
	@data = $self->mag_ang if $fmt eq 'ma';
	@data = $self->ri if $fmt eq 'ri';
	@data = map { [$_] } $self->params_array if ($fmt eq 'complex' or $fmt eq 'cx');

	my $pretty_param = $1 if ref($self) =~ /::([A-Z])Param/;
	my $ret = '';
	for (my $i = 1; $i <= 2; $i++)
	{
		for (my $j = 1; $j <= 2; $j++)
		{
			my $d = shift @data;
			if ($pretty)
			{
				$ret .= "$pretty_param$j$i: [" . join(', ', @$d) . "]\n";
			}
			else
			{
				$ret .= join(' ', @$d) . ' ';
			}
		}
	}

	return $ret;
}

# Helper functions

# return the positive phase angle in degrees of a complex number.
sub cang
{
	my $c = shift;

	my $d = arg($c)*180/pi();
	#$d += 360 if $d < 0;

	return $d;
}

1;
