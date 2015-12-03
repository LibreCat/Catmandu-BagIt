package Catmandu::BagIt::Fetch;
use Moo;
use IO::String;
use File::Slurp;

has 'url'      => (is => 'ro');
has 'size'     => (is => 'ro');
has 'filename' => (is => 'ro');

1;

__END__