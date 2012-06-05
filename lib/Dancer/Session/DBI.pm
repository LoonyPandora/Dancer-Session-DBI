package Dancer::Session::DBI;

# ABSTRACT: DBI based session engine for Dancer

=head1 NAME

Dancer::Session::DBI - DBI based session engine for Dancer

=head1 SYNOPSIS

This module implements a session engine by serializing the session, 
and storing it in a database via L<DBI>. The default serialization method is L<JSON>,
though one can specify any serialization format you want. L<YAML> and L<Storable> are
viable alternatives.

JSON was chosen as the default serialization format, as it is fast, terse, and portable.

B<NOTE: This module is currently only compatible with MySQL and SQLite. This will change in the future>

=head1 USAGE

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

If using a C<Memory> table, you must use a C<VARCHAR> type for the C<session_data> field, as that
table type doesn't support C<TEXT>

A timestamp field that updates when a session is updated is recommended, so you can expire sessions
server-side as well as client-side.

    `last_active` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

This session engine will not automagically remove expired sessions on the server, but with a timestamp
field as above, you should be able to to do this.

=cut

use strict;
use parent 'Dancer::Session::Abstract';
use feature qw(switch);

use Dancer qw(:syntax);
use DBI;
use Try::Tiny;

our $VERSION = '1.0.0';


=head1 METHODS

=head2 create()

Creates a new session. Returns the session object.

=cut

sub create {
    my $self = shift->new;

    $self->flush;

    return $self;
}


=head2 flush()

Write the session to the database. Returns the session object.

=cut

sub flush {
    my $self = shift;

    my $quoted_table = $self->_quote_table;

    # There is no simple cross-database way to do an "upsert"
    # without race-conditions. So we will have to check what database driver
    # we are using, and issue the appropriate syntax. Eventually. TODO
    given(lc $self->_dbh->{Driver}{Name}) {
     	when ('mysql') { 
            my $sth = $self->_dbh->prepare_cached(qq{
                INSERT INTO $quoted_table (id, session_data)
                VALUES (?, ?)
                ON DUPLICATE KEY
                UPDATE session_data = ?
            });

            $sth->execute($self->id, $self->_serialize, $self->_serialize);
            $sth->finish();
        }

        when ('sqlite') {
            my $sth = $self->_dbh->prepare_cached(qq{
                INSERT OR REPLACE INTO $quoted_table (id, session_data) 
                VALUES (?, coalesce( (SELECT session_data FROM $quoted_table WHERE id = ?), ?) )
            });

            $sth->execute($self->id, $self->id, $self->_serialize);
            $sth->finish();        
        }

     	default {
            die "MySQL and SQLite are the only currently supported databases";
        }
    }

    return $self;
}


=head2 retrieve($id)

Look for a session with the given id.

Returns the session object if found, C<undef> if not. Logs a warning if the
session was found, but could not be deserialized.

=cut

sub retrieve {
    my ($self, $session_id) = @_;

    my $session = try {
        my $quoted_table = $self->_quote_table;

        my $sth = $self->_dbh->prepare_cached(qq{
            SELECT session_data
            FROM $quoted_table
            WHERE id = ?
        });

        $sth->execute( $session_id );
        my ($session) = $sth->fetchrow_array();
        $sth->finish();

        $self->_deserialize($session);        
    } catch {
        warning("Could not retrieve session ID $session_id - $_");
        return;
    };

    return bless $session, __PACKAGE__ if $session;
}


=head2 destroy()

Remove the current session object from the database..

=cut

sub destroy {
    my $self = shift;

    my $quoted_table = $self->_quote_table;

    my $sth = $self->_dbh->prepare_cached(qq{
        DELETE FROM $quoted_table
        WHERE id = ?
    });

    $sth->execute($self->id);
    $sth->finish();
}



# Returns a dbh handle, either created from the DSN
# or using the one passed as a DBH argument.
sub _dbh {
    my $self = shift;
    my $settings = setting('session_options');

    # Prefer an active DBH over a DSN.
    return $settings->{dbh}->() if defined $settings->{dbh};

    # Check the validity of the DSN if we don't have a handle
    my $valid_dsn = DBI->parse_dsn($settings->{dsn} || '');

    die "No valid DSN specified" if !$valid_dsn;

    if (!defined $settings->{user} || !defined $settings->{password}) {
        die "No user or password specified";
    }

    # If all the details check out, return a fresh connection
    return DBI->connect($settings->{dsn}, $settings->{user}, $settings->{password});
}


# Quotes table names to prevent SQLi,
# and check that we have a table name specified
sub _quote_table {
    my $self = shift;
    my $settings = setting('session_options');

    die "No table selected for session storage" if !$settings->{table};

    return $self->_dbh->quote_identifier( $settings->{table} );
}


# Default Serialize method
sub _serialize {
    my $self = shift;
    my $settings = setting('session_options');

    if (defined $settings->{serializer}) {
        return $settings->{serializer}->({%$self});
    }

    # A session is by definition ephemeral - Store it compactly
    return to_json({%$self}, { pretty => 0 });
}


# Default Deserialize method
sub _deserialize {
    my ($self, $json) = @_;
    my $settings = setting('session_options');

    if (defined $settings->{deserializer}) {
        return $settings->{deserializer}->($json);
    }

    return from_json($json);
}



=head1 SEE ALSO

L<Dancer>, L<Dancer::Session>, L<Plack::Session::Store::DBI>


=head1 AUTHOR

James Aitken <jaitken@cpan.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1;
