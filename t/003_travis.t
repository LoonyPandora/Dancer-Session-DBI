use Test::More;

use strict;
use warnings;
use utf8;

use Dancer::Session::DBI;
use Dancer qw(:syntax :tests);
use DBI;
use Data::Dump qw(dump);

unless ( !$ENV{TRAVIS_TESTING} ) {
    plan( skip_all => "Travis CI specific tests not required for installation" );
}


set session => 'DBI';

for my $config (
    {dsn => "DBI:mysql:database=myapp_test;host=127.0.0.1", user => "root"},
    {dsn => "DBI:Pg:dbname=myapp_test;host=127.0.0.1", user => "postgres"},
    {dsn => "DBI:SQLite:dbname=:memory:", user => "" }
) {

    set 'session_options' => {
        table    => 'session',
        dsn      => $config->{dsn},
        user     => $config->{user},
        password => "",
    };

    ok(session(testing => "123"), "Can set something in the session");
    is(session('testing'), '123', "Can retrieve something from the session"); 

    ok(session(utf8 => "☃"), "Can set UTF8");
    is(session('utf8'), '☃', "Can get UTF8 back");    
}

done_testing(12);
