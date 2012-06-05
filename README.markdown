# NAME

Dancer::Session::DBI - DBI based session engine for Dancer

# SYNOPSIS

This module implements a session engine by serializing the session, 
and storing it in a database via [DBI](https://metacpan.org/module/DBI). The default serialization method is [JSON](https://metacpan.org/module/JSON),
though one can specify any serialization format you want. [YAML](https://metacpan.org/module/YAML) and [Storable](https://metacpan.org/module/Storable) are
viable alternatives.

JSON was chosen as the default serialization format, as it is fast, terse, and portable.

__NOTE: This module is currently only compatible with MySQL and SQLite. This will change in the future__

# USAGE

In config.yml

    session: "DBI"
    session_options: 
        dsn:      "DBI:mysql:database=testing;host=127.0.0.1;port=3306" # DBI Data Source Name
        table:    "sessions"  # Name of the table to store sessions
        user:     "user"      # Username used to connect to the database
        password: "password"  # Password to connect to the database

Alternatively, you can set the database handle in your application, by passing
an anonymous sub that returns an active DBH connection. Specifying a custom
serializer / deserializer is also possible

    set 'session_options' => {
        dbh          => sub { DBI->connect( 'DBI:mysql:database=testing;host=127.0.0.1;port=3306', 'user', 'password' ); },
        serializer   => sub { YAML::Dump(@_); },
        deserializer => sub { YAML::Load(@_); },
        table        => 'sessions',
    };

The following schema is the minimum requirement.

    CREATE TABLE `sessions` (
        `id`           CHAR(40) PRIMARY KEY,
        `session_data` TEXT
    );

If using a `Memory` table, you must use a `VARCHAR` type for the `session_data` field, as that
table type doesn't support `TEXT`

A timestamp field that updates when a session is updated is recommended, so you can expire sessions
server-side as well as client-side.

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

[Dancer](https://metacpan.org/module/Dancer), [Dancer::Session](https://metacpan.org/module/Dancer::Session), [Plack::Session::Store::DBI](https://metacpan.org/module/Plack::Session::Store::DBI)



# AUTHOR

James Aitken <jaitken@cpan.org>



# COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
