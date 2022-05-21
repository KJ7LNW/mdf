package RF::S2P::Measurement;

use strict;
use warnings;

use Math::Complex;
use Math::Trig;

sub new
{
	my ($class, %args) = @_;

	my $self = bless(\%args, $class);

	return $self;
}

sub hz
{
	return shift->{hz};
}

sub sdata
{
	return @{ shift->{sdata} };
}

sub ri
{
	return map { [ Re($_), Im($_) ] } shift->sdata;
}

sub db_ang
{
	return map { [ 20*log(abs($_)), cang($_) ] } shift->sdata;
}

sub mag_ang
{
	return map { [ abs($_), cang($_) ] } shift->sdata;
}

# Input impedance.
# https://electronics.stackexchange.com/a/620447
sub z_in
{
	my ($self, $z0) = @_;

	$z0 //= 50;

	my $s11 = $self->{sdata}[0];

	return $z0 * (1+$s11)/(1-$s11);
}

# return the positive phase angle in degrees of a complex number.
sub cang
{
	my $c = shift;
	
	my $d = arg($c)*180/pi();
	#$d += 360 if $d < 0;

	return $d;
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
	@data = map { [$_] } $self->sdata if $fmt eq 'complex' or $fmt eq 'cx';

	my $ret = '';
	for (my $i = 1; $i <= 2; $i++)
	{
		for (my $j = 1; $j <= 2; $j++)
		{
			my $d = shift @data;
			if ($pretty)
			{
				$ret .= "S$j$i: [" . join(', ', @$d) . "]\n";
			}
			else
			{
				$ret .= join(' ', @$d) . ' ';
			}
		}
	}

	return $ret;
}

# Return the complex number $pct percent of the way between $c1 and $c2.
# https://math.stackexchange.com/q/4451400/983059
sub interpolate
{
	my ($c1, $c2, $pct) = @_;

	return (1-$pct)*$c1 + $pct*$c2;
}

1;
