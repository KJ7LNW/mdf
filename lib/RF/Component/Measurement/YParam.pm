package RF::Component::Measurement::YParam;
use parent 'RF::Component::Measurement';

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

	die "expected SParam class" if ref($sparam) ne 'RF::Component::Measurement::SParam';

	my $S = $sparam->params;

	my $sqrt_z = Math::Matrix::Complex->scalar(sqrt($sparam->z0), $S->nrow);
	my $sqrt_y = $sqrt_z->inv();
	my $id = Math::Matrix::Complex->id($S->nrow);

	# https://en.wikipedia.org/wiki/Admittance_parameters
	my $Y = $sqrt_y*($id-$S)*(($id+$S)->inv*$sqrt_y);

	# http://qucs.sourceforge.net/tech/node98.html
	# Alternate Y calculation:
	#my $z_ref = Math::Matrix::Complex->scalar($sparam->z0, $S->nrow);
	#my $g_ref = Math::Matrix::Complex->scalar((1/sqrt(Re($sparam->z0))), $S->nrow);
	#my $Y = $g_ref->inv*($S*$z_ref+$z_ref)->inv() * ($id-$S)*$g_ref;
	#my $Y = $g_ref->inv*$z_ref->inv*($S+$id)->inv() * ($id-$S)*$g_ref;

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

	$self->{_sparam} = $self->clone('RF::Component::Measurement::SParam', params => $S);

	return $self->{_sparam};
}

1;
