package RF::S2P::Measurement::YParam;
use parent 'RF::S2P::Measurement';

use strict;
use warnings;

use Math::Complex;
use Math::Trig;

sub from_sparam
{
	my ($class, $sparam) = @_;

	my %h = %$sparam;

	die "expected SParam class" if ref($sparam) ne 'RF::S2P::Measurement::SParam';

	my $self = bless(\%h, $class);

	my ($s11, $s21, $s12, $s22) = @{ $self->{params} };

	my $y0 = 1/$self->{z0};
	my $delta_s = (1+$s11)*(1+$s22) - $s12*$s21;
	die "delta_is 0, cannot compute Y-params" if ($delta_s == 0);

	# Convert to Y-params:
	# https://en.wikipedia.org/wiki/Admittance_parameters#Two_port
	$self->{params} = [ 
			$y0 * ((1-$s11)*(1+$s22)+$s12*$s21)/$delta_s, # Y11
			$y0 * -2*$s12 / $delta_s,                     # Y12
			$y0 * -2*$s21 / $delta_s,                     # Y21
			$y0 * ((1+$s11)*(1-$s22)+$s12*$s21)/$delta_s, # Y22
			 
		];

	return $self;
}

sub inductance
{
	my ($self) = @_;

	my $hz = $self->hz;

	my $z11 = 1/$self->{params}[0]; # 1/y11

	my $L = Im($z11) / (2*pi*$hz);

	return $L;
}

sub ind_nH { return shift->inductance * 1e9; }

sub capacitance
{
	my ($self) = @_;

	my $hz = $self->hz;
	my $z11 = 1/$self->{params}[0]; # 1/y11

	my $C = 1 / (Im($z11)*2*pi*$hz);

	return $C;
}

sub cap_pF { return shift->capacitance * 1e12; }

sub q_factor
{
	my ($self) = @_;

	my $y11 = $self->{params}[0];

	return -(Im($y11)/Re($y11));
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


1;
