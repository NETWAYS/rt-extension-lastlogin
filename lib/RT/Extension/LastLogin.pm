package RT::Extension::LastLogin;

use 5.10.1;
use strict;
use warnings;

our $VERSION = '0.1.0';

=head2 RecordLogin { User => RT::User|RT::CurrentUser }

Stamps the given user's "Last Login" custom field with the current time.
Called from the C<SuccessfulLogin> callback after a successful password
login, and from the C<ExternalAuthSuccessfulLogin> callback after a
successful REMOTE_USER-based external login (SAML, reverse-proxy header
auth, etc.) - see
F<html/Callbacks/RT-Extension-LastLogin/autohandler/SuccessfulLogin> and
F<html/Callbacks/RT-Extension-LastLogin/autohandler/ExternalAuthSuccessfulLogin>.

Always re-loads the user as C<RT-E<gt>SystemUser> rather than trusting the
rights of the user who just logged in - a SelfService/portal user normally
lacks C<SeeCustomField>/C<ModifyCustomField> on themselves. Never dies: any
failure is logged and swallowed, since a broken write here must not break
the login itself.

=cut

sub RecordLogin {
    my ( $class, %args ) = @_;

    my $user_id = $args{User} ? $args{User}->id : undef;
    return unless $user_id;

    eval {
        my $user = RT::User->new( RT->SystemUser );
        $user->Load($user_id);
        die "could not load user $user_id" unless $user->id;

        my $cf_name = RT->Config->Get('LastLogin_CustomFieldName') // 'Last Login';

        my $cf = RT::CustomField->new( RT->SystemUser );
        $cf->LoadByName( Name => $cf_name, LookupType => RT::User->CustomFieldLookupType );
        die "custom field '$cf_name' not found" unless $cf->id;

        return if $class->_ShouldSkip(
            LastValue   => $user->FirstCustomFieldValue($cf_name),
            MinInterval => RT->Config->Get('LastLogin_MinInterval') // 0,
            Now         => time,
        );

        my $now = RT::Date->new( RT->SystemUser );
        $now->SetToNow;

        # W3CDTF with an explicit UTC 'Z' suffix, not ->ISO: RT re-parses
        # stored DateTime CF values via Time::ParseDate, which only
        # reliably resolves the timezone with that suffix present.
        my ( $ok, $msg ) = $user->AddCustomFieldValue(
            Field             => $cf->id,
            Value             => $now->W3CDTF( Timezone => 'UTC' ),
            RecordTransaction => RT->Config->Get('LastLogin_RecordTransaction') ? 1 : 0,
        );
        RT->Logger->warning("RT::Extension::LastLogin: $msg") unless $ok;
    };
    RT->Logger->warning("RT::Extension::LastLogin: $@") if $@;

    return;
}

=head2 _ShouldSkip { LastValue => STR|undef, MinInterval => SECONDS, Now => UNIX_EPOCH }

Pure throttle decision, split out of L</RecordLogin> so it is unit
testable without a database: true if C<LastValue> parses to a time less
than C<MinInterval> seconds before C<Now>. C<MinInterval> of C<0> (the
default) or a missing/unparseable C<LastValue> (first login) never skips.

Parses C<LastValue> with C<< Format => 'iso' >>, not C<'unknown'>: the
value is always one this module wrote itself (via
L<RT::Date/W3CDTF>), so the exact format is known, and C<'unknown'>
would pull in C<Time::ParseDate> for no reason - RT::Date's own docs call
that "a heavyweight operation that should never be called from within
RT's core".

=cut

sub _ShouldSkip {
    my ( $class, %args ) = @_;
    return 0 unless $args{MinInterval} && $args{LastValue};

    my $last_date = RT::Date->new( RT->SystemUser );
    $last_date->Set( Format => 'iso', Value => $args{LastValue} );
    return 0 unless $last_date->Unix;

    return ( $args{Now} - $last_date->Unix ) < $args{MinInterval} ? 1 : 0;
}

1;

__END__

=pod

=head1 NAME

RT::Extension::LastLogin - Records the timestamp of a user's last successful login

=head1 DESCRIPTION

Stamps a global "Last Login" custom field on C<RT::User> with the current
time whenever a user successfully logs in - through the password login form
(SelfService/portal or Staff) or via REMOTE_USER-based external auth (SAML,
reverse-proxy header auth, etc., if C<$WebRemoteUserAuth> is configured).
The value is stored as a standard C<DateTime> custom field, so it is
returned automatically by C<GET /REST/2.0/user/:id> without any REST2
changes.

=head1 RT VERSION

Works with RT 6.0.0 and later.

=head1 INSTALLATION

=over

=item C<perl -I. Makefile.PL>

The C<-I.> is required: modern Perl does not keep C<.> in C<@INC>, and
C<use inc::Module::Install> must find the bundled F<inc/> directory.

=item C<make>

=item C<make install>

May need root permissions.

=item Register the "Last Login" custom field

C<make install> does not load F<etc/initialdata>. Run once per RT instance:

    /opt/rt/sbin/rt-setup-database --action insert \
        --datafile /opt/rt/local/plugins/RT-Extension-LastLogin/etc/initialdata

=item Edit your F</opt/rt/etc/RT_SiteConfig.pm>

    Plugin('RT::Extension::LastLogin');

=item Clear your Mason cache and restart the webserver

    rm -rf /opt/rt/var/mason_data/obj

=back

=head1 CONFIGURATION

All configuration is optional; sensible defaults apply.

=head2 C<$LastLogin_CustomFieldName>

Name of the custom field to update. Default: C<Last Login>.

=head2 C<$LastLogin_RecordTransaction>

If true, also records a transaction on the user for every login (visible in
the user's history). Default: C<0> (update the custom field value only, no
history entry per login).

=head2 C<$LastLogin_MinInterval>

Minimum number of seconds between two recorded updates for the same user;
C<0> (default) always updates.

=head1 CAVEATS

=head2 Renaming the custom field breaks lookup silently

C<RecordLogin> finds the custom field by the name in
C<$LastLogin_CustomFieldName>, not by id. Renaming "Last Login" in
Admin > Custom Fields (without updating the config to match) makes every
login log a C<custom field '...' not found> warning and stop updating the
timestamp - logins themselves are unaffected, but the data goes stale
without any user-visible error.

=head1 AUTHOR

NETWAYS GmbH E<lt>support@netways.deE<gt>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by NETWAYS GmbH

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
