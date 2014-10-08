package Catmandu::Importer::BagIt;

use namespace::clean;
use Catmandu::Sane;
use Archive::BagIt;
use Moo;

with 'Catmandu::Importer';

has bags              => (is => 'ro' , default => sub { [] } );
has include_manifests => (is => 'ro' , default => sub { undef });
has include_payloads  => (is => 'ro' , default => sub { undef });
has verify            => (is => 'ro' , default => sub { undef }); 

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

    my $item = { 
        _id               => $dir ,
        base              => $dir ,
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
        $item->{non_payload_files} =  [ map { substr($_,length($dir) + 1) } $bag->non_payload_files ];
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
    warn $file;
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