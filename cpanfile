requires 'perl', '5.008005';

# requires 'Some::Module', 'VERSION';

on test => sub {
  requires 'Test::Deep', '0.112';
  requires 'Test::Exception', '0.32';
  requires 'Test::More', '1.001003';
};

requires 'Catmandu','0.9204';
requires 'Archive::BagIt', '0.045';