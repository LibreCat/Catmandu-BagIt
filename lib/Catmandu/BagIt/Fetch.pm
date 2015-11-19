package Catmandu::BagIt::Fetch;
use Moo;
use IO::String;
use File::Slurp;

has 'url'      => (is => 'rw');
has 'size'     => (is => 'rw');
has 'filename' => (is => 'rw');

1;

__END__