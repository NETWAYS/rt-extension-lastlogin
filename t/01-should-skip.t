use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestHelper;

my $now = 1_755_500_000;    # arbitrary fixed epoch, see perlfunc/time

is(
    RT::Extension::LastLogin->_ShouldSkip(
        LastValue => undef, MinInterval => 300, Now => $now,
    ),
    0,
    'no previous value (first login) -> never skip'
);

is(
    RT::Extension::LastLogin->_ShouldSkip(
        LastValue   => RT::Date->new->W3CDTF( Timezone => 'UTC' ),
        MinInterval => 0,
        Now         => $now,
    ),
    0,
    'MinInterval 0 -> never skip regardless of LastValue'
);

subtest 'recent previous value within the interval -> skip' => sub {
    my $recent = RT::Date->new;
    $recent->Unix( $now - 60 );    # 60s ago
    is(
        RT::Extension::LastLogin->_ShouldSkip(
            LastValue   => $recent->W3CDTF( Timezone => 'UTC' ),
            MinInterval => 300,
            Now         => $now,
        ),
        1,
        '60s ago, 300s interval -> skip'
    );
};

subtest 'old previous value outside the interval -> do not skip' => sub {
    my $old = RT::Date->new;
    $old->Unix( $now - 600 );    # 600s ago
    is(
        RT::Extension::LastLogin->_ShouldSkip(
            LastValue   => $old->W3CDTF( Timezone => 'UTC' ),
            MinInterval => 300,
            Now         => $now,
        ),
        0,
        '600s ago, 300s interval -> do not skip'
    );
};

is(
    RT::Extension::LastLogin->_ShouldSkip(
        LastValue => 'not a date', MinInterval => 300, Now => $now,
    ),
    0,
    'unparseable LastValue -> do not skip (fail open, same as first login)'
);

done_testing;
