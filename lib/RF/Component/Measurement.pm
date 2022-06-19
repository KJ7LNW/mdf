package RF::Component::Measurement;

use strict;
use warnings;

use parent 'RF::Component';

use Math::Complex;
use Math::Trig;
use RF::Component::Measurement::SParam;
use RF::Component::Measurement::YParam;
use RF::Component::Measurement::ZParam;
use RF::Component::Measurement::TParam;
use RF::Component::Measurement::AParam;

use Data::Dumper;

our %valid_opts = map { $_ => 1 } qw/component params hz/;

sub new
{
	my ($class, %args) = @_;

	die "$class is not intended to be used directly, instantiate a subclass instead." if ($class eq __PACKAGE__);

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
	$newclass //= $class;

	my %h = %$self;

	# Remove class-privates:
	delete $h{$_} foreach (grep { /^_/ } keys %h);

	# Use existing params if not defined in %args:
	$args{params} = $self->params->clone if (!defined($args{params}));

	die "args{params} is undef: RF parameters (eg, S-parameters) must be provided." if (!defined($args{params}));

	return $newclass->new(%h, %args);
}

###############################################################################
#                                                       Member access functions

# Takes a port# (not an array index), so $self->z0(1) is the impedance at port1.
sub z0
{
	my ($self, $port) = @_;
	$self->{component}->z0($port);
}

sub hz { return shift->{hz}; }



###############################################################################
#                                                          Parameter Conversion

sub to_X_param
{
	my ($self, $type) = @_;

	$type = uc($type);

	$type = "${type}Param";

	my $class = "RF::Component::Measurement::${type}";

	return $class->from_sparam($self->to_sparam);
}

# to_sparam and from_sparam must be implemented in each class.  
# Subclassing from/to_y/z/tparam() functions is optional.  Perhaps
# it would be more efficient in some cases to convert direct from one
# parameter to another without converting to an S-parameter first.  
# If this becomes an issue then implement an to/from function
# in the appropriate subclass.
sub to_sparam { die "to_sparam: not implemented in " . ref(shift); }

sub to_yparam { return shift->to_X_param('y'); }
sub to_zparam { return shift->to_X_param('z'); }
sub to_tparam { return shift->to_X_param('t'); }
sub to_aparam { return shift->to_X_param('a'); }

sub from_sparam { die "from_sparam: not implemented in " . ref(shift); }
sub from_zparam { die "from_zparam: not implemented in " . ref(shift); }
sub from_yparam { die "from_yparam: not implemented in " . ref(shift); }
sub from_tparam { die "from_tparam: not implemented in " . ref(shift); }
sub from_abcd { die "from_abcd: not implemented in " . ref(shift); }



###############################################################################
#                                                        Matrix Index Functions

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
sub ABCD { return shift->to_aparam->params(@_) }

# ABCD helpers:
sub A { return shift->to_aparam->params(1,1) }
sub B { return shift->to_aparam->params(1,2) }
sub C { return shift->to_aparam->params(2,1) }
sub D { return shift->to_aparam->params(2,2) }

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

	my $pretty_param = $1 if ref($self) =~ /::([A-Z]+)Param/;
	my $ret = '';
	for (my $i = 1; $i <= 2; $i++)
	{
		for (my $j = 1; $j <= 2; $j++)
		{
			my $d = shift @data;
			if (defined $pretty)
			{
				$ret .= "$pretty$pretty_param$j$i: [" . join(', ', @$d) . "]\n";
			}
			else
			{
				$ret .= join(' ', @$d) . ' ';
			}
		}
	}

	return $ret;
}


###############################################################################
#                                                      S-Parameter Calculations

# Input impedance.
# https://electronics.stackexchange.com/a/620447
sub z_in
{
	my ($self) = @_;

	my $z0 = $self->z0;

	my $s11 = $self->S(1,1);

	return $z0 * (1+$s11)/(1-$s11);
}



###############################################################################
#                                                      Y-Parameter Calculations

sub inductance
{
	my ($self) = @_;

	return  -Im(1/$self->Y(1,2)) / (2*pi*$self->hz);
}

sub resistance
{
	my $self = shift;

	return -Re(1/$self->Y(1,2));
}

sub ind_nH { return shift->inductance * 1e9; }

sub capacitance
{
	my ($self) = @_;

	return Im($self->Y(1,1)) / (2*pi*$self->hz);
}

sub cap_pF { return shift->capacitance * 1e12; }

sub q_factor
{
	my ($self) = @_;

	return (2*pi*$self->hz) * ($self->inductance / $self->resistance)
}

sub Q { return shift->q_factor }

sub reactance_l
{
	my $self = shift;

	return 2*pi*$self->hz*$self->inductance;
}

sub reactance_c
{
	my $self = shift;

	return 1.0/(2*pi*$self->hz*$self->capacitance);
}

sub reactance
{
	my $self = shift;
	return $self->reactance_l - $self->reactance_c;
}

sub X { return shift->reactance; }
sub Xl { return shift->reactance_l; }
sub Xc { return shift->reactance_c; }

# srf: Self-resonating frequency.
#
# This may not be accurate.  While the equasion is a classic
# SRF calculation (1/(2*pi*sqrt(LC)), srf should instead be an RF::Component function and
# scan the frequency lines as follows:
#    "The SRF is determined to be the fre-quency at which the insertion (S21)
#    phase changes from negative through zero to positive."
#    [ https://www.coilcraft.com/getmedia/8ef1bd18-d092-40e8-a3c8-929bec6adfc9/doc363_measuringsrf.pdf ]
sub srf
{
	my $self = shift;

	return 1/sqrt( abs 2*pi*$self->inductance*$self->capacitance);
}



###############################################################################
#                                                             ABCD Calculations

# Convert a serial model to a shunt model.  
# Swaps C <=> 1/B
# https://electronics.stackexchange.com/a/621496/256265
sub serial_to_shunt
{
	my $self = shift;

	my $abcd = $self->to_aparam->clone;
	my $A = $abcd->ABCD;

	warn "Input may not be a serial model, A !~ 1: " . $abcd->A if (abs(1-abs($abcd->A)) > 1e-6);
	warn "Input may not be a serial model, C !~ 0: " . $abcd->C if (abs(0-abs($abcd->C)) > 1e-6);
	warn "Input may not be a serial model, D !~ 1: " . $abcd->D if (abs(1-abs($abcd->D)) > 1e-6);

	my $z = $A->[0][1];
	my $temp = $A->[1][0];
	$A->[1][0] = (1/$z);
	$A->[0][1] = $temp;

	$abcd->{params} = $A;

	return $abcd;
}

# Convert a shunt model to a serial model.  
# Swaps B <=> 1/C
# https://electronics.stackexchange.com/a/621496/256265
sub shunt_to_serial
{
	my $self = shift;

	my $abcd = $self->to_aparam->clone;
	my $A = $abcd->ABCD;

	warn "Input may not be a shunt model, A !~ 1: " . $abcd->A if (abs(1-abs($abcd->A)) > 1e-6);
	warn "Input may not be a shunt model, B !~ 0: " . $abcd->B if (abs(0-abs($abcd->B)) > 1e-6);
	warn "Input may not be a shunt model, D !~ 1: " . $abcd->D if (abs(1-abs($abcd->D)) > 1e-6);

	my $y = $A->[1][0];
	my $temp = $A->[0][1];

	$A->[0][1] = 1/$y;
	$A->[1][0] = $temp;

	$abcd->{params} = $A;

	return $abcd;
}

sub is_lossless
{
	my ($self, $tolerance) = @_;

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# Lossless when diagonal elements are purely Real and off-diagonal are
	# purely imaginary: https://youtu.be/rfbvmGwN_8o
	return (abs(Im($self->A)) < $tolerance && abs(Im($self->D)) < $tolerance
		&& abs(Re($self->B)) < $tolerance && abs(Re($self->C)) < $tolerance);
}

# See reference for symmetrical, reciprocal, open_circuit, short_circuit:
# https://resources.system-analysis.cadence.com/blog/msa2021-abcd-parameters-of-transmission-lines
sub is_symmetrical
{
	my ($self, $tolerance) = @_;

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# A =~ D:
	return abs($self->A - $self->D) < $tolerance;
}

sub is_reciprocal
{
	my ($self, $tolerance) = @_;

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# AD-BC=1
	return abs($self->ABCD->det()) < $tolerance;
}

sub is_open_circuit
{
	my ($self, $tolerance) = @_;

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# A=C=0
	return (abs($self->A) < $tolerance && abs($self->C) < $tolerance);
}

sub is_short_circuit
{
	my ($self, $tolerance) = @_;

	# How small should Im/Re be to be considered zero?
	$tolerance //= 1e-6;

	# B=D=0
	return (abs($self->B) < $tolerance && abs($self->D) < $tolerance);
}


###############################################################################
#                                                 Circuit Compositing Functions

# Works classfully too, since the first array element is the object:
#   $s = $self->serial($c1, $c2, ...);
#     or
#   $s = serial($c1, $c2, ...);
sub serial
{
	my @components = @_;

	my $ret;
	foreach my $c (@components)
	{
		if (!$ret)
		{
			$ret = $c->clone->to_aparam;
		}
		else
		{
			$ret->{params} *= $c->ABCD;
		}
	}

	return $ret;
}

# Works classfully too, since the first array element is the object:
#   $s = $self->parallel($c1, $c2, ...);
#     or
#   $s = parallel($c1, $c2, ...);
sub parallel
{
	my @components = @_;

	my $ret;
	foreach my $c (@components)
	{
		if (!$ret)
		{
			$ret = $c->clone->to_yparam;
		}
		else
		{
			$ret->{params} += $c->Y;
		}
	}

	return $ret;
}


###############################################################################
#                                                    Classless Helper functions

# return the positive phase angle in degrees of a complex number.
sub cang
{
	my $c = shift;

	my $d = arg($c)*180/pi();
	#$d += 360 if $d < 0;

	return $d;
}

1;
