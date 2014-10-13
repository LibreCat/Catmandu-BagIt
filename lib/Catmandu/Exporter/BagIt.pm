package Catmandu::Exporter::BagIt;

use namespace::clean;
use Catmandu::Sane;
use Archive::BagIt;
use File::Path qw(make_path remove_tree);
use Moo;

with 'Catmandu::Exporter';

has overwrite => (is => 'ro' , default => sub { 0 });

sub add {
	my ($self, $data) = @_;
	my $directory = $data->{_id};

	Catmandu::BadArg->throw("$directory exists") if -d $directory && ! $self->overwrite;

    my $bag = $self->write_bag($directory);
}

sub write_bag {
	my ($self,$directory) = @_;

	my $bag;

	# If the directory contains a bagit.txt file we assume it is already a bag
	if (-d $directory && -d $directory . "bagit.txt") {
    	$bag = Archive::BagIt->new($directory);
    }
    elsif (-d $directory) {
    	$bag = Archive::BagIt->make_bag($directory);
    }
    else {
    	make_path($directory, { error => \my $err });

    	Catmandu::BadArg->throw("$directory creation failed") if @$err;
    	 
    	$bag = Archive::BagIt->make_bag($directory);
    }

    $bag;
}

1;