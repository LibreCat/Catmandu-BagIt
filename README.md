# NAME

Catmandu::BagIt - Low level Catmandu interface to the BagIt packages.

# SYNOPSIS

    use Catmandu::BagIt;

    # Assemble a new bag
    my $bagit = Catmandu::BagIt->new;

    # Read an existing
    my $bagit = Catmanu::BagIt->read($directory);

    $bag->read('t/bag');

    printf "path: %s\n", $bagit->path;
    printf "version: %s\n"  , $bagit->version;
    printf "encoding: %s\n" , $bagit->encoding;
    printf "size: %s\n", $bagit->size;
    printf "payload-oxum: %s\n", $bagit->payload_oxum;

    printf "tags:\n";
    for my $tag ($bagit->list_info_tags) {
        my @values = $bagit->get_info($tag);
        printf " $tag: %s\n" , join(", ",@values); 
    }

    printf "tag-sums:\n";
    for my $file ($bagit->list_tagsum) {
        my $sum = $bagit->get_tagsum($file);
        printf " $file: %s\n" , $sum; 
    }

    # Read the file listing as found in the manifest file
    printf "file-sums:\n";
    for my $file ($bagit->list_checksum) {
        my $sum = $bagit->get_checksum($file);
        printf " $file: %s\n" , $sum; 
    }

    # Read the real listing of files as found on the disk
    printf "files:\n";
    for my $file ($bagit->list_files) {
        my $stat = [$file->data->stat];
        printf " name: %s\n", $file->name;
        printf " size: %s\n", $stat->[7];
        printf " last-mod: %s\n", scalar(localtime($stat->[9]));
    }

    my $file = $bagit->get_file("mydata.txt");
    my $fh   = $file->fh;

    while (<$fh>) {
       ....
    }

    print "dirty?\n" if $bagit->is_dirty;

    if ($bagit->complete) {
        print "bag is complete\n";
    }
    else {
        print "bag is not complete!\n";
    }

    if ($bagit->valid) {
        print "bag is valid\n";
    }
    else {
        print "bag is not valid!\n";
    }

    if ($bagit->is_holey) {
        print "bag is holey\n";
    }
    else {
        print "bag isn't holey\n";
    }

    if ($bagit->errors) {
        print join("\n",$bagit->errors);
    }

    # Write operations
    $bagit->add_info('My-Tag','fsdfsdfsdf');
    $bagit->add_info('My-Tag',['dfdsf','dfsfsf','dfdsf']);
    $bagit->remove_info('My-Tag');

    $bagit->add_file("test.txt","my text");
    $bagit->add_file("data.pdf", IO::File->new("/tmp/data.pdf"));
    $bagit->remove_file("test.txt");

    $bagit->add_fetch("http://www.gutenberg.org/cache/epub/1980/pg1980.txt","290000","shortstories.txt");
    $bagit->remove_fetch("shortstories.txt");

    $bagit->write("bags/demo04"); # fails when the bag already exists
    $bagit->write("bags/demo04", new => 1); # recreate the bag when it already existed
    $bagit->write("bags/demo04", overwrite => 1); # overwrites an exiting bag

# CATMANDU MODULES

- [Catmandu::Importer::BagIt](https://metacpan.org/pod/Catmandu::Importer::BagIt)
- [Catmandu::Exporter::BagIt](https://metacpan.org/pod/Catmandu::Exporter::BagIt)

# SEE ALSO

[Catmandu::Importer::BagIt](https://metacpan.org/pod/Catmandu::Importer::BagIt) , [Catmandu::Exporter::BagIt](https://metacpan.org/pod/Catmandu::Exporter::BagIt)

# AUTHOR

Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
