#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;
use Path::Tiny;
use Test::LWP::UserAgent;
use Catmandu::Importer::BagIt;

my $pkg;
BEGIN {
	$pkg = 'Catmandu::Exporter::BagIt';
	use_ok $pkg;
};
require_ok $pkg;

my $exporter = $pkg->new(user_agent => user_agent());

isa_ok $exporter, $pkg;

throws_ok {
	$exporter->add({
		_id => 'bags/demo01'
	});
} 'Catmandu::Error' , qq|caught an error|;

ok $exporter->add({
	_id   => 't/my-bag' ,
	tags  => { 'Foo' => 'Bar' } ,
	fetch => [ { 'http://demo.org/' => 'data/poem.txt'} ] ,
}) , qq|created t/my-bag bag|;

ok $exporter->commit , 'commit';

ok -r 't/my-bag/data/poem.txt' , 'we got a poem.txt';

my $importer = Catmandu::Importer::BagIt->new( bags => ['t/my-bag'] , verify => 1 , include_manifests => 1);

ok $importer , 'created importer';

my $first = $importer->first;

ok $first , 'found the first bag';

is $first->{tags}->{'Foo'} , 'Bar' , 'a Foo is a Bar';

is $first->{is_valid} , 1 , 'the bag is valid';

ok $first->{version} , 'checking version bug';

ok exists $first->{manifest}->{'data/poem.txt'} , 'found a manifest';

ok $exporter->add({
    _id   => 't/my-bag-files' ,
    tags  => { 'Foo' => 'Bar' } ,
    files => [
        { 't/poem.txt' => 'data/poem.txt'},
        { 't/poem2.txt' => 'data/poem2.txt'}
    ] ,
}) , qq|created t/my-bag-files bag|;

ok -r "t/my-bag-files/data/poem.txt", "poem.txt was copied from file";
ok -r "t/my-bag-files/data/poem2.txt", "poem2.txt was copied from file";

$exporter->commit;

done_testing 15;

sub user_agent  {
    my $ua = Test::LWP::UserAgent->new(agent => 'Test/1.0');

    my $text =<<EOF;
Roses are red,
Violets are blue,
Sugar is sweet,
And so are you.
EOF

    $ua->map_response(
        qr{^http://demo.org/$},
        HTTP::Response->new(
            '200' ,
            'OK' ,
            [ 'Content-Type' => 'text/plain'] ,
            $text
        )
    );

    $ua;
}

END {
	my $error = [];
	# Stupid chdir trick to make remove_tree work
	chdir("lib");
	path('../t/my-bag')->remove_tree;
    path('../t/my-bag-files')->remove_tree;
};
