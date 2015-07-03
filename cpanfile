requires 'perl', '5.008005';

# requires 'Some::Module', 'VERSION';

on test => sub {
  requires 'Test::Deep', '0.112';
  requires 'Test::Exception', '0.32';
  requires 'Test::More', '1.001003';
};

requires 'Catmandu','0.9209';
requires 'Archive::BagIt','0.052';
requires 'LWP::Simple','6.00';
requires 'File::Path','2.09';
