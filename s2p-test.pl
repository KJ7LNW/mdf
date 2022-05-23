#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Getopt::Long qw(:config bundling);

use RF::S2P;
#use RF::S2P::Measurement;
#use RF::S2P::Measurement::SParam;
#use RF::S2P::Measurement::YParam;

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
	"format|f=s"   => \$opts{output_format},
	"eval-mhz|z=s" => \$opts{mhz},
	"pretty|p"     => \$opts{pretty},
	"output|o=s"   => \$opts{output},

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
}

if ($opts{output})
{
	$s2p->save($opts{output}, $opts{output_format});
}

exit 0;

###############################################################################
# Subs below here

sub usage
{
	print "usage: $0 [--eval-mhz <146.52> [--pretty]] [--format <db|ma|ri|cx>] [--output <outfile.s2p>] <input.s2p>\n";
	exit 1;
}
