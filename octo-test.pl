#!/usr/bin/perl

use strict;
use lib 'lib';
use API::Octopart;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
my $o = API::Octopart->new(
	token => (sub { my $t = `cat ~/.octopart/token`; chomp $t; return $t})->(),
	cache => "$ENV{HOME}/.octopart/cache",
	ua_debug => 1,
	);
my %opts = (
	currency => 'USD',
	max_moq => 100,
	min_qty => 10,
	max_price => 4,
	#mfg => 'Murata',
);

if (!@ARGV)
{
	print STDERR "usage: $0 part-model1 [part-model2] ...\n";
	exit 1;
}

foreach my $model (@ARGV)
{
	print STDERR Dumper($o->get_part_stock_detail($model, %opts));
	print STDERR sprintf("$model: %d stock\n", $o->has_stock($model, %opts));
}

print STDERR "Octopart.com API queries: " . $o->octo_query_count() . "\n";
