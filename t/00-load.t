use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;

ok( $RT::Extension::LastLogin::VERSION, 'module loaded with VERSION set' );
can_ok( 'RT::Extension::LastLogin', qw(RecordLogin) );

done_testing;
