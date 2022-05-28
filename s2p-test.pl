#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Getopt::Long qw(:config bundling);

use RF::Touchstone;
use RF::Component::Measurement::AParam;

use Math::Complex;

$|++;

$SIG{__DIE__} = \&backtrace;

sub _build_stack
{
	my $i = 0;
	my $stackoff = 1;

	my @msg;
	while (my @c = caller($i++)) {
		my @c0     = caller($i);
		my $caller = '';

		$caller = " ($c0[3])" if (@c0);
		push @msg, "  " . ($i - $stackoff) . ". $c[1]:$c[2]:$caller while calling $c[3]" if $i > $stackoff;
	}

	return reverse @msg;
}

sub backtrace
{
	my $self = shift;
	my $fh = shift || \*STDERR;

	foreach my $l (reverse _build_stack()) {
		print $fh "$l\n";
	}
}

my %opts;
GetOptions(
	"mhz|f=s"             => \$opts{mhz},
	"pretty|p"            => \$opts{pretty},
	"output|o=s"          => \$opts{output},
	"output-format|O=s"   => \$opts{output_format},
	"output-param|P=s"   => \$opts{output_param},
	"test|t"              => \$opts{test}
	#"" => \$opts{},
) or usage();

usage() if !@ARGV;

$opts{output_format} //= 'db';
$opts{output_format} = lc($opts{output_format});


my $s2p = RF::Touchstone->new;

$s2p->load($ARGV[0]);

if (defined($opts{mhz}))
{
	my $meas = $s2p->get_param($opts{mhz} * 1e6);

	#$meas = $meas->serial($meas->serial_to_shunt);
	#$meas = $meas->serial($meas);
	#$meas = $meas->parallel($meas->to_shunt);
	#$meas = $meas->parallel($meas);

	print "S-Parameters at $opts{mhz} MHz:\n";
	printf "\tInput impedance Zin (S11): " . $meas->z_in() . "\n";
	print $meas->to_sparam->tostring($opts{output_format}, "\t");

	printf "\nY-Parameter Calculations (Y12):\n";
	printf "\tL=%-3.2f nH\n", $meas->ind_nH;
	printf "\tC=%-3.2f pF\n", $meas->cap_pF;
	printf "\tR=%-3.2f Ohms\n", $meas->resistance;
	printf "\tQ=%-3.2f\n", $meas->Q;
	printf "\tXl=%-3.2f     Xc=%-3.2f     X=%-3.2f (X=XL-XC)\n",
		$meas->Xl,
		$meas->Xc,
		$meas->X;

	printf "\nABCD Calculations:\n";
	printf "  short circuit: %d\n", $meas->is_short_circuit(1e-3);
	printf "   open circuit: %d\n", $meas->is_open_circuit(1e-3);
	printf "    symmetrical: %d\n", $meas->is_symmetrical(1e-3);
	printf "     reciprocal: %d\n", $meas->is_reciprocal(1e-3);
	printf "       lossless: %d\n", $meas->is_lossless(1e-3);

	if (defined($opts{test}))
	{
		printf "\nConversion error summary, smaller is better:\n";
		printf "        S->S->S error: %g\n", abs($meas->S - $meas->to_sparam->S)->to_row->sum;
		printf "        S->Z->S error: %g\n", abs($meas->S - $meas->to_zparam->S)->to_row->sum;
		printf "        S->Y->S error: %g\n", abs($meas->S - $meas->to_yparam->S)->to_row->sum;
		printf "        S->T->S error: %g\n", abs($meas->S - $meas->to_tparam->S)->to_row->sum;
		printf "     S->ABCD->S error: %g\n", abs($meas->S - $meas->to_aparam->S)->to_row->sum;
		printf "     T->S->Y->T error: %g\n", abs($meas->T - $meas->to_sparam->to_yparam->T)->to_row->sum;
		printf "     T->Y->S->T error: %g\n", abs($meas->T - $meas->to_yparam->to_sparam->T)->to_row->sum;
		printf "     S->Y->T->S error: %g\n", abs($meas->S - $meas->to_yparam->to_tparam->S)->to_row->sum;
		printf "     S->T->Y->S error: %g\n", abs($meas->S - $meas->to_tparam->to_yparam->S)->to_row->sum;
		printf "     S->shunt->serial->S error: %g\n",
			abs($meas->S - $meas->serial_to_shunt->shunt_to_serial->S)->to_row->sum;
	}
}


if ($opts{output})
{
	$s2p->save($opts{output}, $opts{output_format}, $opts{output_param});
}

exit 0;

###############################################################################
# Subs below here

sub usage
{
	print "usage: $0 [--mhz <146.52> [--pretty]] [--output-format <db|ma|ri|cx>] [--output-param <s|y|z> [--output <outfile.s2p>] <input.s2p>\n";
	exit 1;
}
