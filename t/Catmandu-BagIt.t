#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Digest::MD5;
use IO::File;
use POSIX qw(strftime);
use File::Path qw(remove_tree);
use utf8;

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

    ok $bagit->is_dirty , 'the bag is now dirty';
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

    ok   $bagit->add_file("test1.txt","abcdefghijklmnopqrstuvwxyz") , 'add_file';
    ok ! $bagit->add_file("test1.txt","abcdefghijklmnopqrstuvwxyz") , 'add_file overwrite failed';
    ok ! $bagit->add_file("../../../etc/passwd","boo") , 'add_file illegal path';
    ok ! $bagit->add_file("passwd | dfs ","boo") , 'add_file illegal path';
    ok   $bagit->add_file("test1.txt","abcdefghijklmnopqrstuvwxyz", overwrite => 1) , 'add_file overwrite success';

    ok   $bagit->is_dirty , 'bag is dirty';

    my @files = $bagit->list_files;

    ok @files == 1 , 'count 1 file';

    is $files[0]->name   , 'test1.txt' , 'file->name';
    ok !$files[0]->is_io , 'file->is_io failes';
    is $files[0]->data   , 'abcdefghijklmnopqrstuvwxyz' , 'file->data';
    is ref($files[0]->fh) , 'IO::String', 'file->fh blessed';

    ok ! $bagit->remove_file("testxxx.txt") , 'remove_file that does not exist failes';
    ok $bagit->remove_file("test1.txt") , 'remove_file';

    @files = $bagit->list_files;
    ok @files == 0 , 'count 0 files';

    ok $bagit->is_dirty , 'bag is still dirty'; 

    ok $bagit->add_file("日本.txt","日本") , 'add_file utf8';  

    is [$bagit->list_files]->[0]->data , '日本' , 'utf8 data test';

    ok $bagit->remove_file("日本.txt") , 'remove_file';

    ok $bagit->add_file('LICENSE', IO::File->new("LICENSE")) , 'add_file(IO::File)';

    my $file = [ $bagit->list_files ]->[0];

    is ref($file->fh) , 'IO::File' , 'file->fh is IO::File'; 
}

note("fetch");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    is_deeply [ $bagit->list_fetch ] , [] , 'list_fetch';

    ok $bagit->add_fetch("http://www.gutenberg.org/cache/epub/1980/pg1980.txt","290000","shortstories.txt") , 'add_fetch';

    my @fetches = $bagit->list_fetch;

    ok @fetches == 1 , 'list_fetch';

    is $fetches[0]->url  , 'http://www.gutenberg.org/cache/epub/1980/pg1980.txt' , 'fetch->url';
    is $fetches[0]->size , 290000 , 'fetch->size';
    is $fetches[0]->filename , 'shortstories.txt' , 'fetch->filename';
}

note("complete & valid");
{
    my $bagit = Catmandu::BagIt->new;
    ok $bagit , 'new';

    ok $bagit->complete , 'complete';

    ok $bagit->valid , 'valid';

    ok !$bagit->errors , 'no errors';
}

note("reading operations demo01 (valid bag)");
{
    my $bagit = Catmandu::BagIt->read("bags/demo01");

    ok $bagit , 'read(bags/demo01)';
    ok $bagit->complete , 'complete';
    ok $bagit->valid , 'valid';
    ok !$bagit->errors , 'no errors';
    ok !$bagit->is_holey , 'bag is not holey';
    ok !$bagit->is_dirty , 'bag is not dirty';
    is $bagit->path , 'bags/demo01' , 'path';
    is $bagit->version , '0.97', 'version';
    is $bagit->encoding , 'UTF-8' , 'encoding';
    like $bagit->size , qr/\d+.\d+ KB/ , 'size';
    is $bagit->payload_oxum , '92877.1' , 'payload_oxum';

    is $bagit->get_info('Bag-Size') , '90.8 KB' , 'Bag-Size info';
    is $bagit->get_info('Bagging-Date') , '2014-10-03' , 'Bagging-Date info';
    is $bagit->get_info('Payload-Oxum') , '92877.1' , 'Payload-Oxum info';

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
    is $bagit->get_tagsum($tagsums[2]) , '1022d7f2b7e65ab49c3aeabc407ce7d9' , 'get_tagsum';
}

note("reading operations demo02 (invalid bag)");
{
    my $bagit = Catmandu::BagIt->read("bags/demo02");

    ok $bagit , 'read(bags/demo02)';
    ok !$bagit->complete , 'bag is not complete';
    ok !$bagit->valid , 'bag is not valid';
    ok $bagit->errors , 'bag contains errors'; 
    ok !$bagit->is_holey , 'bag is not holey';
    ok !$bagit->is_dirty , 'bag is not dirty';
    is $bagit->path , 'bags/demo02' , 'path';
    is $bagit->version , '0.97', 'version';
    is $bagit->encoding , 'UTF-8' , 'encoding';
    like $bagit->size , qr/\d+.\d+ KB/ , 'size';
    is $bagit->payload_oxum , '0.2' , 'payload_oxum';

    is $bagit->get_info('Bag-Size') , '39.6 KB' , 'Bag-Size info';
    is $bagit->get_info('Bagging-Date') , '2014-10-03' , 'Bagging-Date info';
    is $bagit->get_info('Payload-Oxum') , '40447.19' , 'Payload-Oxum info';

    my $text = "\"Well, Prince, so Genoa and Lucca are now just family estates "  . 
               "of the Buonapartes. But I warn you, if you don't tell me that "   .
               "this means war, if you still try to defend the infamies and "     .
               "horrors perpetrated by that Antichrist- I really believe he is "  .
               "Antichrist- I will have nothing more to do with you and you are " .
               "no longer my friend, no longer my 'faithful slave,' as you call " .
               "yourself! But how do you do? I see I have frightened you- sit "   .
               "down and tell me all the news.\"";

    is $bagit->get_info('Test') , $text , 'Test info';

    my @list_files = sort { $a->name cmp $b->name } $bagit->list_files;

    ok @list_files == 2 , 'list_files';

    is $list_files[0]->name , '.gitignore' , 'file->name';
    is $list_files[1]->name , 'empty.txt' , 'file->name';

    my @info = $bagit->list_info_tags;

    is_deeply [@info] , [qw(Payload-Oxum Bagging-Date Bag-Size Test)] , 'list_info_tags';
}

note("reading operations demo03 (holey bag)");
{
    my $bagit = Catmandu::BagIt->read("bags/demo03");
    ok $bagit , 'read(bags/demo03)';
    ok !$bagit->complete , 'bag is not complete';
    ok !$bagit->valid , 'bag is not valid';
    ok !$bagit->is_dirty , 'bag is not dirty';
    ok $bagit->errors , 'bag contains errors'; 
    ok $bagit->is_holey , 'bag is holey';

    my @fetches = $bagit->list_fetch;

    ok @fetches == 1 , 'list_fetch';

    ok ref($fetches[0]) eq 'Catmandu::BagIt::Fetch' , 'fetch isa Catmandu::BagIt::Fetch';
    is $fetches[0]->url , 'http://tools.ietf.org/rfc/rfc1.txt' , 'fetch->url';
    is $fetches[0]->size , 21088 , 'fetch->size';
    is $fetches[0]->filename , 'rfc1.txt' , 'fetch->filename';
}

done_testing;