package Catmandu::Store::File::BagIt::Index;

our $VERSION = '1.0602';

use Catmandu::Sane;
use Moo;
use Path::Tiny;
use Carp;
use POSIX qw(ceil);
use Path::Iterator::Rule;
use File::Spec;
use namespace::clean;

use Data::Dumper;

with 'Catmandu::Bag', 'Catmandu::FileBag::Index', 'Catmandu::Droppable';

sub generator {
    my ($self) = @_;

    my $root       = $self->store->root;
    my $keysize    = $self->store->keysize;
    my @root_split = File::Spec->splitdir($root);

    my $mindepth = ceil($keysize / 3);

    unless (-d $root) {
        $self->log->error("no root $root found");
        return sub {undef};
    }

    $self->log->debug("creating generator for root: $root");

    my $rule = Path::Iterator::Rule->new;
    $rule->min_depth($mindepth);
    $rule->max_depth($mindepth);
    $rule->directory;

    return sub {
        state $iter = $rule->iter($root, {depthfirst => 1});

        my $path = $iter->();

        return undef unless defined($path);

        # Strip of the root part and translate the path to an identifier
        my @split_path = File::Spec->splitdir($path);
        my $id = join("", splice(@split_path, int(@root_split)));

        unless ($self->store->uuid) {
            $id =~ s/^0+//;
        }

        $self->get($id);
    };
}

sub exists {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    $self->log->debug("Checking exists $id");

    my $path = $self->store->path_string($id);

    defined($path) && -d $path;
}

sub add {
    my ($self, $data) = @_;

    croak "Need an id" unless defined $data && exists $data->{_id};

    my $id = $data->{_id};

    if (exists $data->{_stream}) {
        croak "Can't add a file to the index";
    }

    my $path = $self->store->path_string($id);

    unless (defined $path) {
        my $err
            = "Failed to create path from $id need a number of max "
            . $self->store->keysize
            . " digits";
        $self->log->error($err);
        Catmandu::BadArg->throw($err);
    }

    $self->log->debug("Generating path $path for key $id");

    # Throws an exception when the path can't be created
    path($path)->mkpath;

    return $self->get($id);
}

sub get {
    my ($self, $id) = @_;

    croak "Need an id" unless defined $id;

    my $path = $self->store->path_string($id);

    unless ($path) {
        $self->log->error(
                  "Failed to create path from $id need a number of max "
                . $self->store->keysize
                . " digits");
        return undef;
    }

    $self->log->debug("Loading path $path for id $id");

    return undef unless -d $path;

    my @stat = stat $path;

    return +{_id => $id,};
}

sub delete {
    my ($self, $id) = @_;

    croak "Need a key" unless defined $id;

    my $path = $self->store->path_string($id);

    unless ($path) {
        $self->log->error("Failed to create path from $id");
        return undef;
    }

    $self->log->debug("Destoying path $path for key $id");

    return undef unless -d $path;

    # Throws an exception when the path can't be created
    path($path)->remove_tree;

    1;
}

sub delete_all {
    my ($self) = @_;

    $self->each(
        sub {
            my $key = shift->{_id};
            $self->delete($key);
        }
    );
}

sub drop {
    $_[0]->delete_all;
}

sub commit {
    return 1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::BagIt::Index - Index of all "Folders" in a Catmandu::Store::File::BagIt

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('File::BagIt' , root => 't/data');

    my $index = $store->index;

    # List all containers
    $index->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new folder
    $index->add({_id => '1234'});

    # Delete a folder
    $index->delete(1234);

    # Get a folder
    my $folder = $index->get(1234);

    # Get the files in an folder
    my $files = $index->files(1234);

    $files->each(sub {
        my $file = shift;

        my $name         = $file->_id;
        my $size         = $file->size;
        my $content_type = $file->content_type;
        my $created      = $file->created;
        my $modified     = $file->modified;

        $file->stream(IO::File->new(">/tmp/$name"), file);
    });

    # Add a file
    $files->upload(IO::File->new("<data.dat"),"data.dat");

    # Retrieve a file
    my $file = $files->get("data.dat");

    # Stream a file to an IO::Handle
    $files->stream(IO::File->new(">data.dat"),$file);

    # Delete a file
    $files->delete("data.dat");

    # Delete a folders
    $index->delete("1234");

=head1 DESCRIPTION

A L<Catmandu::Store::File::BagIt::Index> contains all "folders" available in a
L<Catmandu::Store::File::BagIt> FileStore. All methods of L<Catmandu::Bag>,
L<Catmandu::FileBag::Index> and L<Catmandu::Droppable> are
implemented.

Every L<Catmandu::Bag> is also an L<Catmandu::Iterable>.

=head1 FOLDERS

All files in a L<Catmandu::Store::File::BagIt> are organized in "folders". To add
a "folder" a new record needs to be added to the L<Catmandu::Store::File::BagIt::Index> :

    $index->add({_id => '1234'});

The C<_id> field is the only metadata available in BagIt stores. To add more
metadata fields to a BagIt store a L<Catmandu::Plugin::SideCar> is required.

=head1 FILES

Files can be accessed via the "folder" identifier:

    my $files = $index->files('1234');

Use the C<upload> method to add new files to a "folder". Use the C<download> method
to retrieve files from a "folder".

    $files->upload(IO::File->new("</tmp/data.txt"),'data.txt');

    my $file = $files->get('data.txt');

    $files->download(IO::File->new(">/tmp/data.txt"),$file);

=head1 METHODS

=head2 each(\&callback)

Execute C<callback> on every "folder" in the BagIt store. See L<Catmandu::Iterable> for more
iterator functions

=head2 exists($id)

Returns true when a "folder" with identifier $id exists.

=head2 add($hash)

Adds a new "folder" to the BagIt store. The $hash must contain an C<_id> field.

=head2 get($id)

Returns a hash containing the metadata of the folder. In the BagIt store this hash
will contain only the "folder" idenitifier.

=head2 files($id)

Return the L<Catmandu::Store::File::BagIt::Bag> that contains all "files" in the "folder"
with identifier $id.

=head2 delete($id)

Delete the "folder" with identifier $id, if exists.

=head2 delete_all()

Delete all folders in this store.

=head2 drop()

Delete the store.

=head1 SEE ALSO

L<Catmandu::Store::File::BagIt::Bag> ,
L<Catmandu::Store::File::BagIt> ,
L<Catmandu::FileBag::Index> ,
L<Catmandu::Plugin::SideCar> ,
L<Catmandu::Bag> ,
L<Catmandu::Droppable> ,
L<Catmandu::Iterable>

=cut
