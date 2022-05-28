package RF::Component::Measurement::SParam;
use parent 'RF::Component::Measurement';

use strict;
use warnings;

use Math::Complex;
use Math::Trig;

sub to_sparam { return shift; }
sub from_sparam { my ($class, $sparam) = @_; return $sparam; }

1;
