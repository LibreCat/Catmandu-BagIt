package Catmandu::Exporter::BagIt;

=head1 NAME

Catmandu::Exporter::BagIt - Package that exports data as BagIts

=head1 SYNOPSIS

   use Catmandu::Exporter::BagIt

   my $exporter = Catmandu::Exporter::BagIt->new(
                            overwrite     => 0 ,
                            skip_manifest => 0,
                  );

   $exporter->add($bagit_record);

   $exporter->commit;

=head1 BagIt

The parsed BagIt record is a HASH containing the key '_id' containing the BagIt directory name
and one or more fields:

    {
          '_id' => 'bags/demo01',
          'version' => '0.97',
          'tags' => {
                      'Bagging-Date' => '2014-10-03',
                      'Bag-Size' => '90.8 KB',
                      'Payload-Oxum' => '92877.1'
                    },
           }, 
           'fetch' => [
               { 'http://server/download1.pdf'  => 'data/my_download1.pdf' } ,
               { 'http://server2/download2.pdf' => 'data/my_download2.pdf' } ,
           ],
    };

All URL's in the fetch array will be mirrored and added to the bag. All payload files should
be put in the 'data' subdirectory as shown in the example above.

=head1 METHODS

This module inherits all methods of L<Catmandu::Exporter>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Exporter> the exporter can
be configured with the following parameters:

=over

=item overwrite

Optional. Throws an Catmandu::Error when the exporter tries to overwrite an existing directory.

=item skip_manifest

Optional. Skips the re-calculation of MD5 manifest checksums in case BagIt directories get overwritten. Use this
option for instance when overwriting only the tags of a bag.

=back

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Exporter>

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use namespace::clean;
use Catmandu::Sane;
use Archive::BagIt;
use File::Path qw(make_path remove_tree);
use LWP::Simple;
use Moo;

with 'Catmandu::Exporter';

has overwrite     => (is => 'ro' , default => sub { 0 });
has skip_manifest => (is => 'ro' , default => sub { 0 });

sub add {
	my ($self, $data) = @_;
	my $directory = $data->{_id};
    $directory =~ s{\/$}{};

	Catmandu::Error->throw("$directory exists") if -d $directory && ! $self->overwrite;

    my ($bag,$isnew) = $self->write_bag($directory);

    if (exists $data->{tags}) {
        my $tags = $data->{tags};
        delete $tags->{'Bagging-Date'};
        delete $tags->{'Bag-Software-Agent'};
        $bag->_write_baginfo($directory,%$tags);
       
    }

    if (exists $data->{fetch}) {
        for my $fetch (@{$data->{fetch}}) {
            my ($url) = keys %$fetch;
            my $file  = $fetch->{$url};

            unless ((my $code = mirror($url,"$directory/$file")) == RC_OK) {
                Catmandu::Error->throw("failed to mirror $url to $directory/$file : $code ");
            }

            $isnew = 0;
        }
    }

    if ($isnew) {}
    elsif ($self->skip_manifest) {}
    else {
        $bag->_manifest_md5($directory);
    }

    $bag->_tagmanifest_md5($directory);

    1;
}

sub write_bag {
	my ($self,$directory) = @_;

    my $isnew = 1;
	my $bag;

	# If the directory contains a bagit.txt file we assume it is already a bag
	if (-d $directory && -d $directory . "bagit.txt") {
    	$bag = Archive::BagIt->new($directory);
        $isnew = 0;
    }
    elsif (-d $directory) {
    	$bag = Archive::BagIt->make_bag($directory);
        $isnew = 0;
    }
    else {
    	make_path($directory, { error => \my $err });

    	Catmandu::Error->throw("$directory creation failed") if @$err;
    	 
    	$bag = Archive::BagIt->make_bag($directory);

        $isnew = 1;
    }

    ($bag,$isnew);
}

sub commit { 1 }

1;