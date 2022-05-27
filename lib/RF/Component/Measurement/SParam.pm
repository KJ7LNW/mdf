package RF::Component::Measurement::SParam;
use parent 'RF::Component::Measurement';

use strict;
use warnings;

use Math::Complex;
use Math::Trig;

sub to_sparam { return shift; }
sub from_sparam { my ($class, $sparam) = @_; return $sparam; }

# Input impedance.
# https://electronics.stackexchange.com/a/620447
sub z_in
{
	my ($self) = @_;

	my $z0 = $self->z0;

	my $s11 = $self->S(1,1);

	return $z0 * (1+$s11)/(1-$s11);
}


1;
