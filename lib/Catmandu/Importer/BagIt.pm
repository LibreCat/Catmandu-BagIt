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
    	my $bag = Archive::BagIt->new($dir);

    	return undef unless $dir;
        { _id => $dir };
    };
}

1;