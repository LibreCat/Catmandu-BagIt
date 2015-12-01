#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Digest::MD5;
use POSIX qw(strftime);
use File::Path qw(remove_tree);

use Data::Dumper;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::BagIt';
    use_ok $pkg;
}
require_ok $pkg;

note("in-memory");

note("basic metadata");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    ok !$bagit->path , 'path is null';
    is $bagit->version , '0.97', 'version';
    is $bagit->encoding , 'UTF-8' , 'encoding';
    is $bagit->size , '0.000 KB' , 'size';
    is $bagit->payload_oxum , '0.0' , 'payload_oxum';
}

note("info");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    ok $bagit->add_info('My-First-Tag','one') , 'add_info';
    ok $bagit->add_info('My-First-Tag','two') , 'add_info';
    ok $bagit->add_info('My-Second-Tag','three') , 'add_info';

    is_deeply [sort $bagit->list_info_tags] , [qw(Bag-Size Bagging-Date My-First-Tag My-Second-Tag Payload-Oxum)] , 'list_info_tags';

    my $info = $bagit->get_info('My-First-Tag',',');
    is $info , 'one,two' , 'get_into scalar';

    my @info = $bagit->get_info('My-First-Tag');
    is_deeply [@info] , [qw(one two)] , 'get_info array';

    ok $bagit->remove_info('My-First-Tag') , 'remove_info';

    my $x = $bagit->get_info('My-First-Tag');
    ok !$x , 'get_info is null';

    my @x = $bagit->get_info('My-First-Tag');
    is_deeply [@x] , [] , 'get_info is empty';

    is_deeply [sort $bagit->list_info_tags] , [qw(Bag-Size Bagging-Date My-Second-Tag Payload-Oxum)] , 'list_info_tags';
}

note("tag-sums");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    is_deeply [sort $bagit->list_tagsum] , [qw(bag-info.txt bagit.txt manifest-md5.txt)] , 'list_tagsum';

    my $bagit_txt =<<EOF;
BagIt-Version: 0.97
Tag-File-Character-Encoding: UTF-8
EOF

    is $bagit->get_tagsum('bagit.txt') , Digest::MD5::md5_hex($bagit_txt) , 'get_tagsum(bagit.txt)';

    my $today = strftime "%Y-%m-%d", gmtime;
    my $bag_info_txt =<<EOF;
Bagging-Date: $today
Bag-Size: 0.000 KB
Payload-Oxum: 0.0
EOF

    is $bagit->get_tagsum('bag-info.txt') , Digest::MD5::md5_hex($bag_info_txt) , 'get_tagsum(bag-info.txt)';

    my $manifest_txt = "";
    is $bagit->get_tagsum('manifest-md5.txt') , Digest::MD5::md5_hex($manifest_txt) , 'get_tagsum(manifest-md5.txt)';
}

note("checksums");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    is_deeply [ $bagit->list_checksum ] , [] , 'list_checksum';
}

note("files");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    is_deeply [ $bagit->list_files ] , [] , 'list_files';
}

note("complete & valid");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    ok $bagit->complete , 'complete';

    ok $bagit->valid , 'valid';

    ok !$bagit->errors , 'no errors';
}

note("reading operations");
{
    my $bagit = Catmandu::BagIt->read("bags/demo01");

    ok $bagit , 'read(bags/demo01)';
    ok $bagit->complete , 'complete';
    ok $bagit->valid , 'valid';
    ok !$bagit->errors , 'no errors';
    is $bagit->path , 'bags/demo01' , 'path';
    is $bagit->version , '0.97', 'version';
    is $bagit->encoding , 'UTF-8' , 'encoding';
    is $bagit->size , '90.8 KB' , 'size';
    is $bagit->payload_oxum , '92877.1' , 'payload_oxum';

    my @list_files = $bagit->list_files;

    ok @list_files == 1 , 'list_files';

    my $file = $list_files[0];

    is ref($file)  , 'Catmandu::BagIt::Payload' , 'file is a payload';
    is $file->name , 'Catmandu-0.9204.tar.gz' , 'file->name';
    is ref($file->fh) , 'IO::File' , 'file->fh';
    is $bagit->get_checksum($file->name) , 'c8accb44741272d63f6e0d72f34b0fde' , 'get_checksum';

    my @checksums = $bagit->list_checksum;

    ok @checksums == 1 , 'list_checksum';
    is $checksums[0] , 'Catmandu-0.9204.tar.gz' , 'list_checksum content';

    my @tagsums = sort $bagit->list_tagsum;

    ok @tagsums == 3 , 'list_tagsum';

    is_deeply [ @tagsums ] , [qw(bag-info.txt bagit.txt manifest-md5.txt)] , 'list_tagsum content';

    is $bagit->get_tagsum($tagsums[0]) , '74a18a1c9f491f7f2360cbd25bb2143e' , 'get_tagsum';
    is $bagit->get_tagsum($tagsums[1]) , '9e5ad981e0d29adc278f6a294b8c2aca' , 'get_tagsum';
    is $bagit->get_tagsum($tagsums[2]) , '48e8a074bfe09aa17aa2ca4086b48608' , 'get_tagsum';
}

done_testing;