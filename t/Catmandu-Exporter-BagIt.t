#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use File::Path qw(remove_tree);
use Catmandu::Importer::BagIt;

my $pkg;
BEGIN {
	$pkg = 'Catmandu::Exporter::BagIt';
	use_ok $pkg;
};
require_ok $pkg;

my $exporter = $pkg->new();

isa_ok $exporter, $pkg;

throws_ok {
	$exporter->add({
		_id => 'bags/demo01'
	});
} 'Catmandu::Error' , qq|caught an error|;

ok $exporter->add({
	_id  => 'bags/demo03' ,
	tags => { 'Foo' => 'Bar' } ,
}) , qq|created demo03 bag|;

ok $exporter->commit;

my $importer = Catmandu::Importer::BagIt->new( bags => ['bags/demo03'] , verify => 1);

ok $importer , 'created importer';

my $first = $importer->first;

ok $first , 'found the first bag';

is $first->{tags}->{'Foo'} , 'Bar' , 'a Foo is a Bar';

is $first->{is_valid} , 1 , 'the bag is valid';

done_testing 10;
 
END {
	my $error = [];
	# Stupid chdir trick to make remove_tree work
	chdir("lib");
	remove_tree('../bags/demo03', { verbose => 1, error => \$error });
	print STDERR join("\n",@$error) , "\n" if @$error > 0;;
};
