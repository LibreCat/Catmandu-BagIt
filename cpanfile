requires 'perl', '5.008005';

# requires 'Some::Module', 'VERSION';

on test => sub {
  requires 'Test::Deep', '0.112';
  requires 'Test::Exception', '0.32';
  requires 'Test::More', '1.001003';
};

requires 'Catmandu','0.9209';
requires 'LWP::Simple','6.00';
requires 'File::Slurper','0';
requires 'File::Path','2.09';
requires 'File::Copy','0';
requires 'File::Path','0';

recommends 'Log::Log4perl', '1.44';
recommends 'Log::Any::Adapter::Log4perl', '0.06';