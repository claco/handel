#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 180;

    use_ok('Handel::Checkout');
    use_ok('Handel::Subclassing::Checkout');
    use_ok('Handel::Subclassing::CheckoutStash');
    use_ok('Handel::Subclassing::Stash');
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Checkout::TestMessage');
};


## This is a hack, but it works. :-)
&run('Handel::Checkout');
&run('Handel::Subclassing::Checkout');
&run('Handel::Subclassing::CheckoutStash');

sub run {
    my ($subclass) = @_;


    ## test for Handel::Exception::Argument where message is not a scalar
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});

            $checkout->add_message([1, 2, 3]);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not.*text message/i, 'not text message in message');
        } otherwise {
            fail('other exception thrown');
        };
    };


    ## test for Handel::Exception::Argument where message is not a Handel::Checkout;:Message subclass
    {
        try {
            local $ENV{'LANGUAGE'} = 'en';
            my $fake = bless {}, 'FakeModule';
            my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});

            $checkout->add_message($fake);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass('caught argument exception');
            like(shift, qr/not.*Handel::Checkout::Message/i, 'notmessage object in message');
        } otherwise {
            fail('other exception thrown');
        };
    };


    ## create a message and test new %options
    {
        my $message = Handel::Checkout::Message->new(
            text => 'My Message',
            otherproperty => 'foo'
        );

        isa_ok($message, 'Handel::Checkout::Message');
        is($message->text, 'My Message', 'got message');
        is($message->otherproperty, 'foo', 'got other property');
    };


    ## add a message that isa Apache::AxKit::Exception::Error
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});
        my $axkitmessage = bless {text => 'Foo'}, 'Apache::AxKit::Exception::Error';

        $checkout->add_message($axkitmessage);

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1, 'have 1 message');

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text . '', 'Foo', 'got message text');

        ok($message->filename, 'has filename');
        ok($message->line, 'has line');

        $checkout->clear_messages;
        @messages = @{$checkout->messages};
        is(scalar @messages, 0, 'has 0 messages');
    };


    ## add a message using a scalar
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});

        $checkout->add_message('This is a message');

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1, 'have 1 message');

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text, 'This is a message', 'got text');

        ok($message->filename, 'has filename');
        ok($message->line, 'has line');

        $checkout->clear_messages;
        @messages = @{$checkout->messages};
        is(scalar @messages, 0, 'has no messsages');
    };


    ## add a message using Handel::Checkout::Message object
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});
        my $newmessage = Handel::Checkout::Message->new(
            text => 'This is a new message',
            package => 'package',
            filename => 'filename',
            line => 'line'
        );

        $checkout->add_message($newmessage);

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1, 'has 1 message');

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text, 'This is a new message', 'has text message');
        is($messages[0]->package, 'package', 'has package');
        is($messages[0]->filename, 'filename', 'has filename');
        is($messages[0]->line, 'line', 'has line');
    };


    ## add a message using Handel::Checkout::Message object with existing package/file/line
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});
        my $newmessage = Handel::Checkout::Message->new(text => 'This is a new message');

        $checkout->add_message($newmessage);

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1, 'has 1 message');

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text, 'This is a new message', 'has message text');

        ok($message->filename, 'has filename');
        ok($message->line, 'has line');
    };


    ## add a message using Handel::Checkout::Message subclass
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});
        my $newmessage = Handel::Checkout::TestMessage->new(text => 'This is a new message');

        $checkout->add_message($newmessage);

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1, 'has 1 message');

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text, 'This is a new message', 'has message text');

        ok($message->filename, 'has filename');
        ok($message->line, 'has line');

        is("$message", 'This is a new message', 'message stringifies to message text');

        $message->{'text'} = undef;
        is("$message", ref $message, 'message stringifies to object in lue of text');
    };


    ## Check returns in list and scalar context
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});

        $checkout->add_message('Message1');
        $checkout->add_message('Message2');

        my @messages = @{$checkout->messages};
        is(scalar @messages, 2, 'has 2 messages');

        isa_ok($messages[0], 'Handel::Checkout::Message');
        is($messages[0]->text, 'Message1', 'has message text');
        is($messages[0], 'Message1', 'has message text');
        ok($messages[0]->filename, 'has filename');
        ok($messages[0]->line, 'has line');

        isa_ok($messages[1], 'Handel::Checkout::Message');
        is($messages[1]->text, 'Message2', 'has message text');
        is($messages[1], 'Message2', 'has message text');
        ok($messages[1]->filename, 'has filename');
        ok($messages[1]->line, 'has line');

        my $messagesref = $checkout->messages;
        isa_ok($messagesref, 'ARRAY');
        isa_ok($messagesref->[0], 'Handel::Checkout::Message');
        is($messagesref->[0]->text, 'Message1', 'has message text');
        is($messagesref->[0], 'Message1', 'has message text');
        ok($messagesref->[0]->filename, 'has filename');
        ok($messagesref->[0]->line, 'has line');

        is($messagesref->[1]->text, 'Message2', 'has message text');
        is($messagesref->[1], 'Message2', 'has message text');
        ok($messagesref->[1]->filename, 'has filename');
        ok($messagesref->[1]->line, 'has line');
    };

};


package Apache::AxKit::Exception::Error;
use strict;
use warnings;
use overload
    '""' => sub{shift->{'text'}},
    fallback => 1;

1;
