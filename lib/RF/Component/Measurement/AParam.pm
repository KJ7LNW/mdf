# ABCD Matrix

package RF::Component::Measurement::AParam;
use parent 'RF::Component::Measurement';

use strict;
use warnings;

use Math::Complex;
use Math::Trig;
use Data::Dumper;

sub to_aparam { return shift; }
sub from_aparam { my ($class, $abcd) = @_; return $abcd; }

sub from_sparam
{
	my ($class, $s) = @_;

	die "expected SParam class" if ref($s) ne 'RF::Component::Measurement::SParam';

	# shorthand call to the S matrix:
	my $S = sub { $s->params(@_) };

	my $z01 = Math::Complex->make($s->z0, 0);
	my $z02 = $z01;

	my $z01_conj = ~$z01;
	my $z02_conj = ~$z02;

	# https://www.researchgate.net/publication/3118645
	# "Conversions Between S, Z, Y, h, ABCD, and T Parameters
	#   which are Valid for Complex Source and Load Impedances"
	# March 1994 IEEE Transactions on Microwave Theory and Techniques 42(2):205 - 211
	my $ABCD = Math::Matrix::Complex->new(
		[
		  [
		    # A
		    (($z01_conj + $S->(1,1)*$z01) * (1 - $S->(2,2)) + $S->(1,2)*$S->(2,1)*$z01)
		       / # over
		    (2*$S->(2,1)*sqrt(Re($z01)*Re($z02))),
    
		    # B
		    (($z01_conj + $S->(1,1)*$z01)*($z02_conj+$S->(2,2)*$z02) - $S->(1,2)*$S->(2,1)*$z01*$z02)
		       / # over
		    (2*$S->(2,1)*sqrt(Re($z01)*Re($z02)))
		  ],
		  [
		    # C
		    (( 1 - $S->(1,1) )*( 1 - $S->(2,2) ) - $S->(1,2)*$S->(2,1))
		       / # over
		    (2*$S->(2,1)*sqrt(Re($z01)*Re($z02))),

		    # D
		    ((1-$S->(1,1))*($z02_conj+$S->(2,2)*$z02) + $S->(1,2)*$S->(2,1)*$z02)
		       / # over
		    (2*$S->(2,1)*sqrt(Re($z01)*Re($z02))),

		  ]
		]);

	my $self = $s->clone(__PACKAGE__, params => $ABCD);

	return $self;
}

sub to_sparam
{
	my $self = shift;

	return $self->{_sparam} if (defined($self->{_sparam}));

	my $z01 = Math::Complex->make($self->z0, 0);
	my $z02 = $z01;

	my $z01_conj = ~$z01;
	my $z02_conj = ~$z02;

	my ($A, $C, $B, $D) = $self->params_array();

	my $S = Math::Matrix::Complex->new(
		[
		  [
			# S11
			($A*$z02 + $B - $C*$z01_conj*$z02 - $D*$z01_conj)
				/ # over
			($A*$z02 + $B + $C*$z01*$z02 + $D*$z01),

			# S12
			(2*($A*$D-$B*$C)*sqrt(Re($z01)*Re($z02)))
				/ # over
			($A*$z02 + $B + $C*$z01*$z02 + $D*$z01)
		  ],
		  [
		  	# S21
			(2*sqrt(Re($z01)*Re($z02)))
				/ # over
			($A*$z02 + $B + $C*$z01*$z02 + $D*$z01),

		  	# S22
			(-$A*$z02_conj + $B - $C*$z01*$z02_conj + $D*$z01)
				/ # over
			($A*$z02 + $B + $C*$z01*$z02 + $D*$z01)
		  ]
		]);

	$self->{_sparam} = $self->clone('RF::Component::Measurement::SParam', params => $S);

	return $self->{_sparam};
}

1;
