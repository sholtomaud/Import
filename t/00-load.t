#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 7;

BEGIN {
    use_ok( 'Logger' ) || print "Bail out!\n";
    use_ok( 'Time::Local' ) || print "Bail out!\n";
    use_ok( 'Import' ) || print "Bail out!\n";
    use_ok( 'Import::Config' ) || print "Bail out!\n";
    use_ok( 'DBI' ) || print "Bail out!\n";
    use_ok( 'Text::CSV_XS' ) || print "Bail out!\n";
    use_ok( 'Hydstra' ) || print "Bail out!\n";
}

diag( "Testing Import $Import::VERSION, Perl $], $^X" );
