#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Getopt::Long qw(:config bundling);

use RF::S2P;
use RF::S2P::Measurement;
use Math::Complex;

my %opts;
GetOptions(
	"format|f=s" => \$opts{output_format},
	"eval-mhz|z=s" => \$opts{mhz},
	"pretty|p" => \$opts{pretty},
	"output|o=s" => \$opts{output},
	#"" => \$opts{},
) or usage();

usage() if !@ARGV;

$opts{output_format} //= 'db';
$opts{output_format} = lc($opts{output_format});


my $s2p = RF::S2P->new;

$s2p->load($ARGV[0]);

if (defined($opts{mhz}))
{
	my $meas = $s2p->sparam($opts{mhz} * 1e6);
	print $meas->tostring($opts{output_format}, $opts{pretty});
	print "\n" if !$opts{pretty};
	print "z-in: " . $meas->z_in(50) . "\n";
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
