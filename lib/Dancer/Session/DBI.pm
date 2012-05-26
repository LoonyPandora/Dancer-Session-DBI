package Dancer::Session::DBI;

# ABSTRACT: DBI-based session engine for Dancer

=head1 NAME

Dancer::Session::DBI - DBI-based session engine for Dancer

=head1 SYNOPSIS

=head1 USAGE

=cut

use strict;
use parent 'Dancer::Session::Abstract';
use feature 'switch';

use Dancer::Config 'setting';
use Dancer::Logger;
use DBI;
use JSON::XS qw(encode_json decode_json);
use Try::Tiny;

our $VERSION = '0.1.0';


sub create {
    my $self = shift->new;

    $self->flush;

    return $self;
}

sub retrieve {
    my ($self, $session_id) = @_;
    my $settings = setting('session_options');

    my $quoted_table = $self->_dbh->quote_identifier( $settings->{table} );

    my $sth = $self->_dbh->prepare_cached(qq{
        SELECT session_data
        FROM $quoted_table
        WHERE id = ?
    });

    $sth->execute( $session_id );
    my ($session) = $sth->fetchrow_array();

    $session = try {
        $self->_deserialize($session);
    } catch {
        Dancer::Logger::warning("Could not retrieve session ID $session_id - $_");
        return;
    };

    return bless $session, __PACKAGE__ if $session;
}

sub destroy {
    my ($self, $session_id) = @_;
    my $settings = setting('session_options');

    my $quoted_table = $self->_dbh->quote_identifier( $settings->{table} );

    my $sth = $self->_dbh->prepare_cached(qq{
        DELETE FROM $quoted_table
        WHERE id = ?
    });
    $sth->execute( $session_id );
}

sub flush {
    my $self = shift;
    my $settings = setting('session_options');

    my $quoted_table = $self->_dbh->quote_identifier( $settings->{table} );

    # There is no simple cross-database way to do an "upsert"
    # without race-conditions.  So we have to check what database driver
    # we are using, and issue the appropriate syntax
    given(lc $self->_dbh->{Driver}{Name}) {
     	when ('mysql') { 
            my $sth = $self->_dbh->prepare_cached(qq{
                INSERT INTO $quoted_table (id, session_data)
                VALUES (?, ?)
                ON DUPLICATE KEY
                UPDATE session_data = ?
            });

            $sth->execute($self->id, $self->_serialize, $self->_serialize);
        }
        
     	default {
            die "MySQL is the only currently supported database";
        }
    }


    return $self;
}


# Returns a dbh handle, either cached or brand new
sub _dbh {
    my $self = shift;
    my $settings = setting('session_options');

    if (defined $settings->{dbh}) {
        return $settings->{dbh};
    }

    return DBI->connect($settings->{dsn}, $settings->{user}, $settings->{password});
}

# Serializes to JSON
sub _serialize {
    my $self = shift;

    return encode_json( {%$self} );
}

# Deserializes from JSON
sub _deserialize {
    my ($self, $json) = @_;

    return decode_json( $json );
}




=head1 SEE ALSO

L<Dancer>, L<Dancer::Session>


=head1 AUTHOR

James Aitken <jaitken@cpan.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by James Aitken.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


1;
