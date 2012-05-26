package test_app;
use Dancer ':syntax';
use DBI;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
};


get '/dbh' => sub {
    set 'session_options' => {
        dbh => DBI->connect( 'DBI:mysql:database=testing;host=127.0.0.1;port=3306', 'vegrev', 'password' ),
        table => 'session',
    };
    
    template 'index';
};


true;
