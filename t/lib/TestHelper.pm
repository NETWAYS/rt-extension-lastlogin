package TestHelper;

use strict;
use warnings;

use lib '/opt/rt/lib', '/opt/rt/local/lib';

# Bootstrap RT just far enough that RT->Config->Get/Set and RT->Logger work
# without touching the database. RT::Init would open a DB connection - we
# explicitly avoid it so unit tests stay hermetic.
require RT;
RT::LoadConfig();
RT::InitLogging();

require RT::Date;
require RT::Extension::LastLogin;

1;
