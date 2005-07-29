#!perl -wT
# $Id$
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::Checkout::TestMessage;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 22;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Exception', ':try');
};


## test for Handel::Exception::Argument where message is not a scalar
{
    try {
        my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});

        $checkout->add_message([1, 2, 3]);

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument where message is not a Handel::Checkout;:Message subclass
{
    try {
        my $fake = bless {}, 'FakeModule';
        my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});

        $checkout->add_message($fake);

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## create a message and test new %options
{
    my $message = Handel::Checkout::Message->new(
        text => 'My Message',
        otherproperty => 'foo'
    );

    isa_ok($message, 'Handel::Checkout::Message');
    is($message->text, 'My Message');
    is($message->otherproperty, 'foo');
};


## add a message using a scalar
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});

    $checkout->add_message('This is a message');

    my @messages = @{$checkout->messages};
    is(scalar @messages, 1);

    my $message = $messages[0];
    isa_ok($message, 'Handel::Checkout::Message');
    is($messages[0]->text, 'This is a message');

    ok($message->filename);
    ok($message->line);
};


## add a message using Handel::Checkout::Message object
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});
    my $newmessage = Handel::Checkout::Message->new(text => 'This is a new message');

    $checkout->add_message($newmessage);

    my @messages = @{$checkout->messages};
    is(scalar @messages, 1);

    my $message = $messages[0];
    isa_ok($message, 'Handel::Checkout::Message');
    is($messages[0]->text, 'This is a new message');

    ok($message->filename);
    ok($message->line);
};


## add a message using Handel::Checkout::Message subclass
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});
    my $newmessage = Handel::Checkout::TestMessage->new(text => 'This is a new message');

    $checkout->add_message($newmessage);

    my @messages = @{$checkout->messages};
    is(scalar @messages, 1);

    my $message = $messages[0];
    isa_ok($message, 'Handel::Checkout::Message');
    is($messages[0]->text, 'This is a new message');

    ok($message->filename);
    ok($message->line);
};