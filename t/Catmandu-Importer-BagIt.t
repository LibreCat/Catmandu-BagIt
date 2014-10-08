#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use Data::Dumper;

my $pkg;
BEGIN {
	$pkg = 'Catmandu::Importer::BagIt';
	use_ok $pkg;
}
require_ok $pkg;

my $importer = $pkg->new(bags => ['bags/demo01','bags/demo02'] , verify => 1);

isa_ok $importer, $pkg;

#is  $importer->count , 2 , 'reading 2 bags';

$importer->each(sub {
	my $item = shift;
	print Dumper($item);
});

done_testing 3;