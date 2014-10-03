#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;
BEGIN {
	$pkg = 'Catmandu::Importer::BagIt';
	use_ok $pkg;
}
require_ok $pkg;

my $importer = $pkg->new(bags => ['bags/demo01','bags/demo02']);

isa_ok $importer, $pkg;

is  $importer->count , 2 , 'reading 2 bags';

done_testing 4;