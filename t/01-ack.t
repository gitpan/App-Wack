use strict;
use warnings;

use Test::More;
my $tests;

plan tests => $tests;

use lib 'ack'; # for the development environment

use_ok("App::Ack");
BEGIN { $tests += 1; }

{
    my @ack_methods = qw(
        print
        print_first_filename
        print_blank_line
        print_separator
        print_filename
        print_line_no
        print_count
        print_count0
    );
    foreach my $method (@ack_methods) {
        can_ok 'App::Ack', $method;
    }
    BEGIN { $tests += 8; }
}


