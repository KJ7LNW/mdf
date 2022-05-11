#!/usr/bin/perl

use strict;
use lib 'lib';
use Octopart;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
my $o = Octopart->new();
print Dumper $o->get_part_stock('RC0805FR-0710KL');
