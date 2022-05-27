package RF::S2P::Measurement::YParam;
use parent 'RF::S2P::Measurement';

use strict;
use warnings;

use Math::Complex;
use Math::Trig;
use Data::Dumper;

sub to_yparam { return shift; }
sub from_yparam { my ($class, $yparam) = @_; return $yparam; }

sub from_sparam
{
	my ($class, $sparam) = @_;

	die "expected SParam class" if ref($sparam) ne 'RF::S2P::Measurement::SParam';

	my $S = $sparam->params;

	my $sqrt_z = Math::Matrix::Complex->scalar(sqrt($sparam->z0), $S->nrow);
	my $sqrt_y = $sqrt_z->inv();
	my $id = Math::Matrix::Complex->id($S->nrow);

	# https://en.wikipedia.org/wiki/Admittance_parameters
	my $Y = $sqrt_y*($id-$S)*(($id+$S)->inv*$sqrt_y);

	my $self = $sparam->clone(__PACKAGE__, params => $Y);

	return $self;
}

sub to_sparam
{
	my $self = shift;

	return $self->{_sparam} if (defined($self->{_sparam}));

	my $Y = $self->params;

	my $sqrt_z = Math::Matrix::Complex->scalar(sqrt($self->z0), $Y->nrow);
	my $sqrt_y = $sqrt_z->inv();
	my $id = Math::Matrix::Complex->id($Y->nrow);

	# https://en.wikipedia.org/wiki/Admittance_parameters
	my $S = ($id-$sqrt_z*$Y*$sqrt_z)*($id+$sqrt_z*$Y*$sqrt_z)->inv;

	$self->{_sparam} = $self->clone('RF::S2P::Measurement::SParam', params => $S);

	return $self->{_sparam};
}

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


1;
