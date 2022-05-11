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
print Dumper $o->get_part_stock_detail('RC0805FR-0710KL', %opts);
print Dumper $o->get_part_stock_detail('GQM1555C2DR90BB01D', %opts);
