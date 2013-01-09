use Test::More;

use strict;
use warnings;

use Dancer::Session::DBI;
use Dancer qw(:syntax :tests);
use DBI;


unless ( !$ENV{TRAVIS_TESTING} ) {
    plan( skip_all => "Travis CI specific tests not required for installation" );
}


# MySQL
# my $mysql_dbh  = DBI->connect("DBI:mysql:database=myapp_test;host=127.0.0.1", "root", "");
# my $pgsql_dbh  = DBI->connect("DBI:Pg:dbname=myapp_test;host=127.0.0.1", "postgres", "");
# my $sqlite_dbh = DBI->connect("DBI:SQLite:dbname=:memory:", "", "");





eval {
    set session => 'DBI';
    set 'session_options' => {
        table    => 'session',
        dsn      => 'DBI:mysql:database=testing;host=127.0.0.1',
        user     => "vegrev",
        password => "password",
    };
    session->create();
    
    session(testing => 123);
};
like $@, qr{No table selected for session storage}i,
    'Should fail with no table selected';


done_testing();
