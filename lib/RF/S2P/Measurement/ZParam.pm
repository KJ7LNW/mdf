package RF::S2P::Measurement::ZParam;
use parent 'RF::S2P::Measurement';

use strict;
use warnings;

use Math::Complex;
use Math::Trig;
use Data::Dumper;

sub to_zparam { return shift; }
sub from_zparam { my ($class, $zparam) = @_; return $zparam; }

sub from_sparam
{
	my ($class, $sparam) = @_;

	die "expected SParam class" if ref($sparam) ne 'RF::S2P::Measurement::SParam';

	my $S = $sparam->params;


	# We are converting to Y and then Z because it seems to yield
	# a smaller S->Z->S conversion error.  This may not always hold true,
	# but it does for the Coilcraft 0402DC-121 inductor and the Murata
	# GQM1555C2D100JB01 capacitor:
	my $Z = $sparam->Y->inv();

	# These are alternate but equivalent Z->S conversions, but see comment above:
	# https://en.wikipedia.org/wiki/Impedance_parameters
	#my $z0 = $sparam->z0;
	#my $G_ref = 1 / sqrt(Re($sparam->z0));
	#my $sqrt_z = Math::Matrix::Complex->scalar(sqrt($sparam->z0), $S->nrow);
	#my $id = Math::Matrix::Complex->id($S->nrow);
	#
	#my $Z = $sqrt_z * ($id+$S) * (($id-$S)->inv()) * $sqrt_z;
	#my $Z = $sqrt_z * ($id-$S)->inv() * ($id+$S) * $sqrt_z;
	# http://qucs.sourceforge.net/tech/node98.html
	#my $Z = (1/$G_ref) * ($id-$S)->inv() * ($S*$z0+$z0) * (1/$G_ref);
	
	my $self = $sparam->clone(__PACKAGE__, params => $Z);

	return $self;
}

sub to_sparam
{
	my $self = shift;

	return $self->{_sparam} if (defined($self->{_sparam}));

	my $Z = $self->params;

	# We are converting to Y and then S because it seems to yield
	# a smaller S->Z->S conversion error.  This may not always hold true,
	# but it does for the Coilcraft 0402DC-121 inductor and the Murata
	# GQM1555C2D100JB01 capacitor:
	my $Y = $self->clone('RF::S2P::Measurement::YParam', params =>
	$Z->inv);
	$self->{_sparam} = $Y->to_sparam;

	# These are alternate but equivalent Z->S conversions, but see comment above:
	# https://en.wikipedia.org/wiki/Admittance_parameters
	#my $z0 = $self->z0;
	#my $G_ref = 1 / sqrt(Re($self->z0));
	#my $sqrt_z = Math::Matrix::Complex->scalar(sqrt($self->z0), $Z->nrow);
	#my $sqrt_y = $sqrt_z->inv();
	#my $id = Math::Matrix::Complex->id($Z->nrow);
	#
	#my $S = ($sqrt_y*$Z* $sqrt_y - $id) * (($sqrt_y*$Z*$sqrt_y + $id)->inv());
	#my $S = (($sqrt_y*$Z* $sqrt_y + $id)->inv()) * ($sqrt_y*$Z*$sqrt_y - $id);
	#my $S = $G_ref * ($Z - $z0) * ($Z+$z0)->inv() * (1/$G_ref);
	#$self->{_sparam} = $self->clone('RF::S2P::Measurement::SParam', params => $S);

	return $self->{_sparam};
}

1;
