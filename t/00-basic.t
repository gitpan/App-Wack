#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
my $tests;
plan tests => $tests;

use Data::Dumper;
use lib 'ack'; # for the development environment

use App::Wack;


#{
#    can_ok 'App::Wack', '_get_config_file';
#    like App::Wack::_get_config_file(), qr{wack.yml$}, 'old config file';
#    my $config_file = App::Wack::_get_config_file();
#
#    like $config_file, qr/wack\.yml$/, 'default config file name';
#    BEGIN { $tests += 3; }
#}



my $config_file = 'test.yml';
unlink $config_file;
{
    no warnings 'redefine';
#    *{App::Wack::_get_config_file} = sub {
#        return $config_file;
#    }
    sub App::Wack::_get_config_file {
        return $config_file;
    }
}

{
    my $test_config_file = App::Wack::_get_config_file();
    is $test_config_file, 'test.yml', 'test config file name';
    BEGIN { $tests += 1; }
}

{
    my $help = App::Wack::get_help();
    like $help, qr/Copyright/, 'help has copyright';
    BEGIN { $tests += 1; }
}

# TODO: test the App::Wack::setup() method:
#  create a separate test file
#  create a predefined config.yml file
#  run setup() and check if it set the values as needed in the config hash

App::Wack::setup();
my $config = App::Wack::get_config();
is_deeply $config, { 
                conf            => { max_search_history => 10 },
                recent_searches => [],
            }, 'default config is cool';
BEGIN { $tests += 1; }

{
    foreach my $o (qw(i v w Q all)) {
        App::Wack::set_option($o, 1);
        is $config->{opts}{$o}, 1, "option $o";
    }

    #diag Dumper $config;
    # TODO: this should fail at some point
    App::Wack::set_option('nosuch', 1);
    TODO: {
        local $TODO = "don't allow invalid options";
        ok !defined $config->{opts}{nosuch}, "nosuch option";
    }

    # turn off
    foreach my $o (qw(i v w Q all)) {
        App::Wack::set_option($o);
        ok !exists $config->{opts}{$o}, "option $o removed";
    }

    BEGIN { $tests += 5 * 2 + 1; }
}

our @result;
{
    no warnings 'redefine';
    sub App::Ack::print_first_filename { push @::result,  ['first_filename', @_]; }
    sub App::Ack::print_separator      { push @::result,  ['separator',      @_]; }
    sub App::Ack::print                { push @::result,  ['print',          @_]; }
    sub App::Ack::print_filename       { push @::result,  ['filename',       @_]; }
    sub App::Ack::print_line_no        { push @::result,  ['line_no',        @_]; }
}

{
    @result = ();
    App::Wack::set_option('all', 1);
    App::Wack::ack('third', 't/files');
    is_deeply \@result, 
                   [
                     [
                       'filename',
                       't/files/b.txt',
                       ':'
                     ],
                     [
                       'line_no',
                       '3',
                       ':'
                     ],
                     [
                       'print',
                       "There is a third line too.\n"
                     ]
                   ] or diag Dumper \@result;
    BEGIN { $tests += 1; }
}

# there is a bug in App::Ack (/o) that currently does not let us change
# the regex
#{
#    @result = ();
#    App::Wack::ack('second', 't/files');
#    diag Dumper \@result;
#}


{
    App::Wack::save_config();
    ok -e $config_file;
    # todo shall we check if the files was saved with the correct data?
    BEGIN { $tests += 1; }
}



