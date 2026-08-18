# Change Log

## v0.0.9 (2026-08-18)

Initial release.

- Record a global "Last Login" `DateTime` custom field on `RT::User` after a
  successful password login (SelfService/portal or Staff), via the
  `SuccessfulLogin` callback. SAML/external-auth logins are not covered.
- Written via `RT->SystemUser` so it works for unprivileged users who lack
  `ModifyCustomField` on themselves.
- Value is exposed automatically by `GET /REST/2.0/user/:id` as a standard
  custom field - no REST2 changes needed.
