package RF::S2P::Measurement::TParam;
use parent 'RF::S2P::Measurement';

use strict;
use warnings;

use Math::Complex;
use Math::Trig;

sub to_tparam { return shift; }
sub from_tparam { return shift; }

sub from_sparam
{
	my ($class, $sparam) = @_;

	die "expected SParam class" if ref($sparam) ne 'RF::S2P::Measurement::SParam';

	my ($n, $m) = $sparam->params->size;

	die "Cannot convert ${n}x$m SParam to TParam: S-parameters must be 2x2" if ($n != 2 || $m != 2);

	# https://en.wikipedia.org/wiki/Scattering_parameters#Scattering_transfer_parameters
	my $T = Math::Matrix::Complex->new(
		[
			[ -$sparam->S->det / $sparam->S(2,1), $sparam->S(1,1) / $sparam->S(2,1) ],
			[ -$sparam->S(2,2) / $sparam->S(2,1),               1 / $sparam->S(2,1) ]
		]);

	my $self = $sparam->clone(__PACKAGE__, params => $T);

	return $self;
}

sub to_sparam
{
	my ($self, $Zs, $Zl) = @_;

	$Zs //= $self->z0;
	$Zl //= $self->z0;
	
	return $self->{_sparam} if (defined($self->{_sparam}));

	# https://en.wikipedia.org/wiki/Scattering_parameters#Scattering_transfer_parameters
	#   Note that ->det is T11*T22 - T12*T21
	my $S = Math::Matrix::Complex->new(
		[
			[ $self->T(1,2) / $self->T(2,2) ,  $self->T->det / $self->T(2,2) ],
			[             1 / $self->T(2,2) , -$self->T(2,1) / $self->T(2,2) ]
		]);

	$self->{_sparam} = $self->clone('RF::S2P::Measurement::SParam', params => $S);

	return $self->{_sparam};
}

1;
