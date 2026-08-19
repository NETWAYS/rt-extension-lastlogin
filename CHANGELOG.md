# Change Log

## v0.1.0 (2026-08-19)

- Also record logins via `ExternalAuthSuccessfulLogin` (REMOTE_USER-based
  external auth: SAML, reverse-proxy header auth, etc.), not just password
  logins. Verified end-to-end in the devkit with a temporary PSGIWrap test
  harness injecting REMOTE_USER (not part of this extension).

## v0.0.9 (2026-08-18)

Initial release.

- Record a global "Last Login" `DateTime` custom field on `RT::User` after a
  successful password login (SelfService/portal or Staff), via the
  `SuccessfulLogin` callback. SAML/external-auth logins are not covered.
- Written via `RT->SystemUser` so it works for unprivileged users who lack
  `ModifyCustomField` on themselves.
- Value is exposed automatically by `GET /REST/2.0/user/:id` as a standard
  custom field - no REST2 changes needed.
