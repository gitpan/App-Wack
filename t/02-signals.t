use strict;
use warnings;

use Test::More;
my $tests;

plan tests => $tests;

use_ok("App::Wack::Signals");
BEGIN { $tests += 1; }

$ENV{WACK_TESTING} = 1; # no AUTOLOAD printing
can_ok 'App::Wack::Signals', 'on_help_clicked';
BEGIN { $tests += 1; }

{
    ok(1);
    BEGIN { $tests += 1; }
}


