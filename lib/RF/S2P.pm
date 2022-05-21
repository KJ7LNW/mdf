package RF::S2P;

use strict;
use warnings;

use RF::S2P::SParam;
use Math::Complex;
use Data::Dumper;

sub new
{
	my ($class, %args) = @_;

	my $self = bless(\%args, $class);

	return $self;
}

sub sparam
{
	my ($self, $hz) = @_;

	my $prev;
	my $cur;
	for my $s (@{ $self->{sdata} })
	{
		$cur = $s;
		#print "hz=$hz cur=" . $cur->hz . "\n";
		if ($cur->hz >= $hz)
		{
			last;
		}

		$prev = $cur;
	}

	return $cur if ($cur->hz == $hz);
		
	die "unable to find Hz for evaluation at $hz" if (!defined $prev);

	my @prev = $prev->sdata;
	my @cur = $cur->sdata;

	my $prev_hz = $prev->hz;
	my $cur_hz = $cur->hz;

	#print "prev: $prev_hz=" . $prev->tostring('ma') . "\n";
	#print "cur : $cur_hz=" . $cur->tostring('ma') . "\n";
	
	my $hz_diff = $cur_hz - $prev_hz;
	my $hz_off = $hz - $prev_hz;

	my @ret;
	my $p = ($hz - $prev_hz)/$hz_diff;
	#print "pct=$p\n";
	while (@prev)
	{
		my $c1 = shift @prev;
		my $c2 = shift @cur;

		push(@ret, RF::S2P::Measurement::interpolate($c1, $c2, $p));
	}

	return RF::S2P::SParam->new(hz => $hz, sdata => \@ret);

}

sub load
{
	my ($self, $fn) = @_;

	my ($funit, $param, $fmt, $R, $zref);

	open(my $in, $fn) or die "$fn: $!";

	my $n = 0;
	my $line;
	while (defined($line = <$in>))
	{
		chomp($line);
		$n++;

		if ($line =~ /^!/)
		{
			push @{ $self->{comments} }, $line;
			next;
		}

		#print "$line\n";

		warn "unknown line $n: $line\n" if ($line !~ /\s*\d+/);

		if ($line =~ s/^#\s*//)
		{
			($funit, $param, $fmt, $R, $zref) = split /\s+/, $line;

			die "zref != 50 ohms: $zref" if $zref != 50;
			die "param != S: $param" if $param ne 'S';
			die "R != R: $R" if $R ne 'R';
			next;
		}

		$self->{zref} = $zref;
		$self->{param} = $param;

		$line =~ s/^\s+|\s+$//g;
		my @sdata = split(/\s+/, $line);
		my $hz = shift(@sdata);
		my @sdata_cx;

		foreach my $pair (pairs(@sdata))
		{
			push @sdata_cx, sdata_to_complex($fmt, @$pair);
		}

		$hz = scale_to_hz($funit, $hz);

		push @{ $self->{sdata} }, RF::S2P::SParam->new(hz => $hz, sdata => \@sdata_cx);
	}
}

sub save
{
	my ($self, $fn, $fmt) = @_;

	open(my $out, '>', $fn) or die "$fn: $!";

	my %fmts =
	(
		db => 1,
		ma => 1,
		ri => 1,
	);

	$fmt = lc($fmt);
	die "unknown format: $fmt" if (!defined($fmts{$fmt}));
	$fmt = uc($fmt);

	print $out join("\n", @{ $self->{comments} // [] }) . "\n";
	print $out "# MHz $self->{param} $fmt R $self->{zref}\n";
	foreach my $meas (@{ $self->{sdata} })
	{
		print $out "" . ($meas->{hz}/1e6) . " " . $meas->tostring($fmt) . "\n";
	}
	close($out);
}

sub scale_to_hz
{
	my ($funit, $n) = @_;

	my %scale = 
	(
		hz => 1,
		khz => 1e3,
		mhz => 1e6,
		ghz => 1e9,
		thz => 1e12,
	);

	my $fscale = $scale{lc($funit)};

	die "Unknown frequency scale: $fscale" if !$fscale;

	return $n*$fscale;
}

# https://physics.stackexchange.com/questions/398988/converting-magnitude-ratio-to-complex-form
sub sdata_to_complex
{
	my ($fmt, $a, $b) = @_;

	my %conv = (
		'RI' => sub {
				return Math::Complex->make($a, $b);
			},

		'MA' => sub {
				return Math::Complex->make($a*cos($b*pi()/180), $a*sin($b*pi()/180));
			}
	);

	my $f = $conv{uc($fmt)};
	die "Unknown s-parameter format: $fmt" if !$f;

	return $f->();
}

sub pairs
{
	my @in = @_;
	my @ret;
	while (@in)
	{
		push @ret, [ shift @in, shift @in ];
	}

	return @ret;
}

1;
