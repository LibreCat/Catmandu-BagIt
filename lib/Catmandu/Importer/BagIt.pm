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
	{ _id => $dir };
}

1;