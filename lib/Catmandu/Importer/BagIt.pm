package Catmandu::Importer::BagIt;

=head1 NAME

Catmandu::Importer::BagIt - Package that imports BagIt data

=head1 SYNOPSIS

   use Catmandu::Importer::BagIt

   my $importer = Catmandu::Importer::BagIt->new(
                        bags => "/my/bags/*" ,
                  );

   my $importer = Catmandu::Importer::BagIt->new(
                        bags => ["directory1","directory2"] ,
                        include_manifests => 0 ,
                        include_payloads  => 0 ,
                        verify            => 1
                  );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

To convert BagIt directories into a JSON representation with the L<catmandu> command line client:

    # Use a glob to find all directories in /my/path/
    catmandu convert BagIt --bags '/my/path/*' --verify 1 

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

          # If the verify option is true
          'is_valid' => 1,

          # If the include_payloads option is true
          'payload_files' => [
                               'data',
                               'data/Catmandu-0.9204.tar.gz'
                             ],

          'non_payload_files' => [],

          # If the include_manifests option is true
          'manifest' => {
                          'data/Catmandu-0.9204.tar.gz' => 'c8accb44741272d63f6e0d72f34b0fde'
                        },
  
          'tagmanifest' => {
                             'manifest-md5.txt' => '48e8a074bfe09aa17aa2ca4086b48608',
                             'bag-info.txt' => '74a18a1c9f491f7f2360cbd25bb2143e',
                             'bagit.txt' => '9e5ad981e0d29adc278f6a294b8c2aca'
                           }, 
    };

=head1 METHODS

This module inherits all methods of L<Catmandu::Importer> and by this
L<Catmandu::Iterable>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Importer> the importer can
be configured with the following parameters:

=over

=item bags

Required. An array reference pointing to zero or more BagIt directories. Or, a string that can
be used as a glob pointing to zero more more directories.

=item include_manifests 

If set to a true value, then all manifest files will be parsed and included into the BagIt record.
Be aware, these checksums will be invalid as soon a you manipulate the BagIt record or files on disk.

=item include_payloads

If set to a true value, then all payloads locations will be parsed and included in the BagIt record.
Be aware, changing the payload sections will be store new data on disk.

=back

=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Importer>

=head1 AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use namespace::clean;
use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Archive::BagIt;
use Moo;

with 'Catmandu::Importer';

has bags              => (is => 'ro' , required => 1);
has include_manifests => (is => 'ro' , default => sub { undef });
has include_payloads  => (is => 'ro' , default => sub { undef });
has verify            => (is => 'ro' , default => sub { undef }); 

sub generator {
    my ($self) = @_;
    my @bags;

    if (is_array_ref($self->bags)) {
        @bags = @{ $self->bags };
    }
    else {
        for (glob($self->bags)) {
            push @bags , $_ if -d $_; 
        }
    }

    sub {
    	my $dir = shift @bags;

    	return undef unless defined $dir && -r $dir;

    	my $bag = $self->read_bag($dir);
    	return undef unless defined $bag;
        
        $bag;
    };
}

sub read_bag {
    my ($self,$dir) = @_;
    my $bag = Archive::BagIt->new($dir);

    my $item = { 
        _id               => $dir ,
        version           => $bag->version ,
    };

    if ($self->verify) {
        eval {
            $bag->verify_bag;
        };
        if ($@) {
            $item->{is_valid} = 0;
        }
        else {
            $item->{is_valid} = 1;
        }
    }

    my $tags = $self->read_tagfile("$dir/bag-info.txt");
    $item->{tags} = $tags;

    if ($self->include_payloads) {
        $item->{payload_files}     = [ map { substr($_,length($dir) + 1) } $bag->payload_files ];
        $item->{non_payload_files} = [ map { substr($_,length($dir) + 1) } $bag->non_payload_files ];
    }

    if ($self->include_manifests) {
        my %manifests = ();

        if ($bag->manifest_files) {
            for my $f ($bag->manifest_files) {
                open(my $fh , '<' , $f);
                while(<$fh>) {
                    chomp;
                    my ($sum,$file) = split(/\s+/,$_,2);
                    $manifests{$file} = $sum; 
                }
                close($fh);
            }
        }

        my %tagmanifests = ();

        if ($bag->tagmanifest_files) {
            for my $f ($bag->tagmanifest_files) {
                open(my $fh , '<' , $f);
                while(<$fh>) {
                    chomp;
                    my ($sum,$file) = split(/\s+/,$_,2);
                    $tagmanifests{$file} = $sum; 
                }
                close($fh);
            }
        }

        $item->{manifest}    = \%manifests;
        $item->{tagmanifest} = \%tagmanifests;
    }

    $item;
}

sub read_tagfile {
    my ($self,$file) = @_;

    open(my $fh, '<:encoding(UTF-8)' , $file) || die "failed to open $file";
    my %tags = ();
    my $prev_tag = undef;

    while(<$fh>) {
        chomp;
        my ($tag,$data);

        if (/^(\S+)\s*:\s*(.*)/) {
            $tag = $1;
            $data = $2;
        }
        elsif (/^\s+/ && defined $prev_tag) {
            $tag  = $prev_tag;
            $data = $_;
        }

        if (defined $tag && defined $data) {
            $tags{$tag} .= $data;
        }

        $prev_tag = $tag;
    }
    close($fh);

    \%tags;
}

1;