# RT::Extension::LastLogin

Records the timestamp of a user's last successful login on
[Request Tracker 6](https://bestpractical.com/rt).

Stamps a global "Last Login" custom field on `RT::User` with the current
time whenever a user successfully logs in through the password login form
(SelfService/portal or Staff). The value is stored as a standard `DateTime`
custom field, so it is returned automatically by `GET /REST/2.0/user/:id`
without any REST2 changes.

Only password logins (`RT::Interface::Web::AttemptPasswordAuthentication`)
are covered. SAML/external-auth logins fire a separate callback
(`ExternalAuthSuccessfulLogin`) that this extension does not hook.

## Installation

```sh
perl -I. Makefile.PL
make
make install
```

`make install` does not load `etc/initialdata`. Register the "Last Login"
custom field once per RT instance:

```sh
/opt/rt/sbin/rt-setup-database --action insert \
    --datafile /opt/rt/local/plugins/RT-Extension-LastLogin/etc/initialdata
```

Edit `/opt/rt/etc/RT_SiteConfig.pm`:

```perl
Plugin('RT::Extension::LastLogin');
```

Clear the Mason cache and restart the webserver:

```sh
rm -rf /opt/rt/var/mason_data/obj
```

## Configuration

All optional; sensible defaults apply.

```perl
Set($LastLogin_CustomFieldName,   'Last Login');  # default
Set($LastLogin_RecordTransaction, 0);             # default: no history entry per login
Set($LastLogin_MinInterval,       0);             # default: always update
```

## Why a custom field, not an attribute or a new column

`GET /REST/2.0/user/:id` serializes `CustomFields` automatically; it does
not serialize generic `RT::Attribute` values at all, and a new core-table
column would need the same kind of REST2 resource work an attribute would.
A global `DateTime` custom field is the only option that satisfies both "no
REST2 changes" and "no core-class overlay" at once.

Trade-off worth knowing: unlike a hand-rolled attribute, the value is not
read-only - it shows up as an editable field on Admin > Users > Modify and
can be overwritten via `PUT /REST/2.0/user/:id` by anyone with
`AdminUsers` + `ModifyCustomField`. It is not a tamper-proof audit trail.

Reading it via REST also requires `SeeCustomField` in addition to
`AdminUsers` (or being the user themselves) - RT grants neither globally by
default.

Also note: the extension looks up the field by **name**
(`$LastLogin_CustomFieldName`), not by id. Renaming "Last Login" in
Admin > Custom Fields without updating the config makes every login log a
warning and silently stop updating the timestamp.

## Author

NETWAYS GmbH <support@netways.de>

## License and copyright

This software is Copyright (c) 2026 by NETWAYS GmbH

This is free software, licensed under:

The GNU General Public License, Version 2, June 1991
