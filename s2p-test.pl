#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Getopt::Long qw(:config bundling);

use RF::S2P;

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


my $s2p = RF::S2P->new;

$s2p->load($ARGV[0]);

if (defined($opts{mhz}))
{
	my $meas = $s2p->get_param($opts{mhz} * 1e6);
	print $meas->tostring($opts{output_format}, $opts{pretty});
	print "\n" if !$opts{pretty};
	print "z-in: " . $meas->z_in(50) . "\n";
	my $y = $meas->to_yparam;

	printf "L=%f nH, C=%f pF, R=%f, Q=%f Xl=%f Xc=%f X=%f\n",
		$y->ind_nH,
		$y->cap_pF,
		$y->resistance,
		$y->Q,
		$y->Xl,
		$y->Xc,
		$y->X;

	if (defined($opts{test}))
	{
		printf "S->S->S error: %g\n", abs($meas->S - $meas->to_sparam->S)->to_row->sum;
		printf "S->Z->S error: %g\n", abs($meas->S - $meas->to_zparam->S)->to_row->sum;
		printf "Y->S->Y error: %g\n", abs($meas->Y - $meas->to_sparam->Y)->to_row->sum;
		printf "T->S->T error: %g\n", abs($meas->T - $meas->to_sparam->T)->to_row->sum;
		printf "S->Y->S error: %g\n", abs($meas->S - $meas->to_yparam->S)->to_row->sum;
		printf "S->T->S error: %g\n", abs($meas->S - $meas->to_tparam->S)->to_row->sum;
		printf "T->S->Y->T error: %g\n", abs($meas->T - $meas->to_sparam->to_yparam->T)->to_row->sum;
		printf "T->Y->S->T error: %g\n", abs($meas->T - $meas->to_yparam->to_sparam->T)->to_row->sum;
		printf "S->Y->T->S error: %g\n", abs($meas->S - $meas->to_yparam->to_tparam->S)->to_row->sum;
		printf "S->T->Y->S error: %g\n", abs($meas->S - $meas->to_tparam->to_yparam->S)->to_row->sum;
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
