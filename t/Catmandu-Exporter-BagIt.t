#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;
BEGIN {
	$pkg = 'Catmandu::Exporter::BagIt';
	use_ok $pkg;
}
require_ok $pkg;

my $exporter = $pkg->new();

isa_ok $exporter, $pkg;

throws_ok {
	$exporter->add({
		_id => 'bags/demo01'
	});
} 'Catmandu::Error' , qq|caught an error|;

done_testing 4;
