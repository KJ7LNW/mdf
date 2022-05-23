package RF::S2P::Measurement::SParam;
use parent 'RF::S2P::Measurement';

use strict;
use warnings;

use Math::Complex;
use Math::Trig;

sub to_sparam { return shift; }
sub from_sparam { return shift; }

# Input impedance.
# https://electronics.stackexchange.com/a/620447
sub z_in
{
	my ($self, $z0) = @_;

	$z0 //= 50;

	my $s11 = $self->S(1,1);

	return $z0 * (1+$s11)/(1-$s11);
}


1;
