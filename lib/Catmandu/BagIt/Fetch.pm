package Catmandu::BagIt::Fetch;
use Moo;
use IO::String;

has 'url'      => (is => 'ro');
has 'size'     => (is => 'ro');
has 'filename' => (is => 'ro');

1;

__END__