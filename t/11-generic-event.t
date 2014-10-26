#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;

use Sentry::Raven;
use Sys::Hostname;
use UUID::Tiny ':std';

local $ENV{SENTRY_DSN} = 'http://key:secret@somewhere.com:9000/foo/123';
my $raven = Sentry::Raven->new();

subtest 'defaults' => sub {
    my $event = $raven->_generate_event();

    is($event->{level}, 'error');
    is($event->{logger}, 'root');
    is($event->{platform}, 'perl');
    is($event->{culprit}, undef);
    is($event->{message}, undef);

    is_deeply($event->{extra}, {});
    is_deeply($event->{tags}, {});

    ok(string_to_uuid($event->{event_id}));
    like($event->{timestamp}, qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$/);
    is($event->{server_name}, hostname());
};

subtest 'overriding defaults' => sub {
    my $event = $raven->_generate_event(
        level       => 'warning',
        logger      => 'mylogger',
        platform    => 'myplatform',
        culprit     => 'myculprit',
        message     => 'mymessage',

        extra       => {
            key1    => 'value1',
            key2    => 'value2',
        },
        tags        => {
            tag1    => 'value1',
            tag2    => 'value2',
        },

        event_id    => 'myeventid',
        timestamp   => 'mytimestamp',
        server_name => 'myservername',
    );

    is($event->{level}, 'warning');
    is($event->{logger}, 'mylogger');
    is($event->{platform}, 'myplatform');
    is($event->{culprit}, 'myculprit');
    is($event->{message}, 'mymessage');

    is_deeply(
        $event->{extra},
        {
            key1    => 'value1',
            key2    => 'value2',
        },
    );

    is_deeply(
        $event->{tags},
        {
            tag1    => 'value1',
            tag2    => 'value2',
        },
    );

    is($event->{event_id}, 'myeventid');
    is($event->{timestamp}, 'mytimestamp');
    is($event->{server_name}, 'myservername');
};

subtest 'invalid options' => sub {
    my $warn_message;
    local $SIG{__WARN__} = sub { $warn_message = $_[0] };

    my $event = $raven->_generate_event(
        level => 'not-a-level',
    );

    is($event->{level}, 'error');
    is($warn_message, "unknown level: not-a-level\n");
};

done_testing();
