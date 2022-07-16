package RF::IO::Touchstone;

use strict;
use warnings;
use 5.010;
use Carp;

use Math::Complex;
use Math::Matrix::Complex;

use RF::Component;
use RF::Component::Measurement;
use RF::Component::Measurement::SParam;
use RF::Component::Measurement::YParam;
use RF::Component::Measurement::ZParam;
use RF::Component::Measurement::TParam;

sub snp_load
{
	my ($fn, %args) = @_;

	my $class;
	my ($funit, $param_type, $fmt, $R, $z0);
	my $n_ports;

	open(my $in, $fn) or croak "$fn: $!";

	my $n = 0;
	my $line;

	my @measurements;
	my $component = RF::Component->new(%args, measurements => \@measurements, filename => $fn);
	while (defined($line = <$in>))
	{
		chomp($line);
		$n++;

		$line =~ s/^\s+|\s+$//g;

		next if !length($line);

		if ($line =~ /^!/)
		{
			push @{ $component->{comments} }, $line;
			next;
		}

		if ($line =~ s/^#\s*//)
		{
			($funit, $param_type, $fmt, $R, $z0) = split /\s+/, $line;

			$param_type = uc($param_type);
			croak "$fn:$n: expected 'R' before z0, but found: $R" if $R ne 'R';
			next;
		}

		if ($line !~ /^\d/)
		{
			carp "$fn:$n: unexpected line $n: $line\n";
			next;
		}

		if ($param_type eq 'S') {
			$class = 'RF::Component::Measurement::SParam';
		}
		elsif ($param_type eq 'Y') {
			$class = 'RF::Component::Measurement::YParam';
		}
		elsif ($param_type eq 'Z') {
			$class = 'RF::Component::Measurement::ZParam';
		}
		elsif ($param_type eq 'T') {
			# T is not a standard s2p matrix type, but we can load it:
			$class = 'RF::Component::Measurement::TParam';
		}
		elsif ($param_type eq 'A') {
			# A is not a standard s2p matrix type, but we can load it:
			$class = 'RF::Component::Measurement::AParam';
		}
		else
		{
			croak "$fn:$n: $param_type-parameter type is not implemented.";
		}

		my @params = split(/\s+/, $line);
		my $hz = shift(@params);
		my @params_cx;

		foreach my $pair (pairs(@params))
		{
			push @params_cx, params_to_complex($fmt, @$pair);
		}

		$hz = scale_to_hz($funit, $hz);

		my $sqrt_n_params = sqrt(scalar @params_cx);

		if (!defined($n_ports))
		{
			$n_ports = $sqrt_n_params;

			# Maybe these should be functions to set semi-private static fields?
			$component->{n_ports} = $n_ports;
			$component->{z} = [ map { $z0 } (1..$n_ports) ];
		}

		if ($sqrt_n_params != $n_ports)
		{
			croak "$fn:$n: expected $n_ports fields of port data but found $sqrt_n_params: $n_ports != $sqrt_n_params";
		}

		my $m = [];
		for (my $i = 0; $i < $n_ports; $i++)
		{
			for (my $j = 0; $j < $n_ports; $j++)
			{
				$m->[$j][$i] = shift @params_cx;
			}
		}

		$m = Math::Matrix::Complex->new($m);

		push @measurements, $class->new(component => $component, hz => $hz, params => $m);
	}

	return $component;
}

sub snp_save_fd
{
	my (%opts) = @_;

	my ($component, $fmt, $type, $fd) = @opts{qw/component format type fd/};

	croak "component must be defined" if !defined $component;

	$fmt //= 'ri';
	$type //= 'S';

	my %fmts = map { $_ => 1 } qw/db ma ri/;

	$fmt = lc($fmt);
	croak "Unknown format: $fmt" if (!defined($fmts{$fmt}));
	$fmt = uc($fmt);

	$type = uc($type); # S, Y, Z, T, A (H and G not yet implemented)

	my $z0 = $component->z0;

	my $out = $opts{fd} or croak "file descriptor must be defined";

	print $out "# MHz $type $fmt R $z0\n";
	print $out join("\n", $component->comments) . "\n";


	foreach my $meas ($component->measurements)
	{
		$meas = $meas->to_X_param($type);
		print $out "" . ($meas->{hz}/1e6) . " " . $meas->tostring($fmt) . "\n";
	}
}

sub snp_save
{
	my (%opts) = @_;

	my $fn = $opts{filename};

	croak "filename must be defined" if !defined $fn;

	open(my $out, '>', $fn) or croak "$fn: $!";

	my $ret = snp_save_fd(%opts, fd => $out);

	close($out);

	return $ret;
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

	croak "Unknown frequency scale: $fscale" if !$fscale;

	return $n*$fscale;
}

# https://physics.stackexchange.com/questions/398988/converting-magnitude-ratio-to-complex-form
sub params_to_complex
{
	my ($fmt, $a, $b) = @_;

	my %conv = (
		'RI' => sub {
				return Math::Complex->make($a, $b);
			},

		'MA' => sub {
				return Math::Complex->make($a*cos($b*pi()/180), $a*sin($b*pi()/180));
			},
		'DB' => sub {
				my $mag = 10**($a/20);
				return Math::Complex->make($mag*cos($b*pi()/180), $mag*sin($b*pi()/180));
			}
	);

	my $f = $conv{uc($fmt)};
	croak "Unknown s-parameter format: $fmt" if !$f;

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
