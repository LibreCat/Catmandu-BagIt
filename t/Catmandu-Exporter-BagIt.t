#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use File::Path qw(remove_tree);
use Catmandu::Importer::BagIt;
use Data::Dumper;

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
	_id   => 'bags/demo03' ,
	tags  => { 'Foo' => 'Bar' } ,
	fetch => [ { 'http://lib.ugent.be' => 'data/ugent.txt'} ] ,
}) , qq|created demo03 bag|;

ok $exporter->commit;

my $importer = Catmandu::Importer::BagIt->new( bags => ['bags/demo03'] , verify => 1 , include_manifests => 1);

ok $importer , 'created importer';

my $first = $importer->first;

ok $first , 'found the first bag';

is $first->{tags}->{'Foo'} , 'Bar' , 'a Foo is a Bar';

is $first->{is_valid} , 1 , 'the bag is valid';

ok $first->{version} , 'checking version bug';

ok exists $first->{manifest}->{'data/ugent.txt'} , 'found a manifest';

done_testing 12;
 
END {
	my $error = [];
	# Stupid chdir trick to make remove_tree work
	chdir("lib");
	remove_tree('../bags/demo03', { error => \$error });
	print STDERR join("\n",@$error) , "\n" if @$error > 0;;
};
