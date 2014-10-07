package Catmandu::Importer::BagIt;

use namespace::clean;
use Catmandu::Sane;
use Archive::BagIt;
use Moo;

with 'Catmandu::Importer';

has bags => (is => 'ro' , default => sub { [] } );

sub generator {
    my ($self) = @_;
    my @bags = @{ $self->bags };

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

	{ 
        _id               => $dir ,
        base              => $dir ,
        version           => $bag->version ,
        payload_files     => [ map { substr($_,length($dir) + 1) } $bag->payload_files ] ,
        non_payload_files => [ map { substr($_,length($dir) + 1) } $bag->non_payload_files ] ,
        manifest          => \%manifests ,
        tagmanifest       => \%tagmanifests ,
    };
}

1;