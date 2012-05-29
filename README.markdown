# NAME

Dancer::Session::DBI - DBI based session engine for Dancer

# SYNOPSIS

This module implements a session engine by serializing the session
into [JSON](http://search.cpan.org/perldoc?JSON), and storing it in a database via [DBI](http://search.cpan.org/perldoc?DBI)

__NOTE: This module is currently only compatible with MySQL. This will change in the future__

JSON was chosen as the serialization format, because it 
is fast, terse, and portable.

In future versions the serialization method may be customizable, but for now JSON
is the only choice. You should look into [Plack::Session::Store::DBI](http://search.cpan.org/perldoc?Plack::Session::Store::DBI) if you
have an immediate need to use a different serializer, and are in a position to
use [Plack](http://search.cpan.org/perldoc?Plack)

# USAGE

In config.yml

    session: "DBI"
    session_options: 
        dsn:      "DBI:mysql:database=testing;host=127.0.0.1;port=3306" # DBI Data Source Name
        table:    "sessions"  # Name of the table to store sessions
        user:     "user"      # Username used to connect to the database
        password: "password"  # Password to connect to the database



Alternatively, you can pass an active DBH connection in your application

    set 'session_options' => {
        dbh   => DBI->connect( 'DBI:mysql:database=testing;host=127.0.0.1;port=3306', 'user', 'password' ),
        table => 'session',
    };

The following MySQL schema is the minimum requirement.

    CREATE TABLE `sessions` (
        `id`           CHAR(40) PRIMARY KEY,
        `session_data` TEXT
    );

If using a MySQL `Memory` table, you must use a `VARCHAR` type for the `session_data` field, as that
table type doesn't support `TEXT`

A timestamp field that updates when a session is updated is recommended, so you can expire sessions
server-side as well as client-side. Something like this

    `last_active` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

This session engine will not automagically remove expired sessions on the server, but with a timestamp
field as above, you should be able to to do this.

# METHODS

## create()

Creates a new session. Returns the session object.

## flush()

Write the session to the database. Returns the session object.

## retrieve($id)

Look for a session with the given id.

Returns the session object if found, `undef` if not. Logs a warning if the
session was found, but could not be deserialized.

## destroy()

Remove the current session object from the database..

# SEE ALSO

[Dancer](http://search.cpan.org/perldoc?Dancer), [Dancer::Session](http://search.cpan.org/perldoc?Dancer::Session), [Plack::Session::Store::DBI](http://search.cpan.org/perldoc?Plack::Session::Store::DBI)



# AUTHOR

James Aitken <jaitken@cpan.org>



# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
