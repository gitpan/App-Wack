package App::Wack;
use strict;
use warnings;

use Gtk2 -init;
use Gtk2::Helper;

use App::Ack;

use File::HomeDir ();
use YAML          ();
use File::Spec    ();
use Data::Dumper  qw(Dumper);
use List::Util    qw(max min);

use App::Wack::Glade;

sub say { print @_, "\n";}

our $VERSION = '0.05';

my @content;

my $tag;
my $config;

sub setup {
    read_config();
    set_defaults();
    return;
}

sub _get_config_file {
    my $home  = File::HomeDir->my_home;
    return File::Spec->catfile($home, 'wack.yml');
}
sub save_config {
    my $file = _get_config_file();
    YAML::DumpFile($file, $config);
    return;
}

sub read_config {
    my $file = _get_config_file();
    if (-e $file) {
        $config = YAML::LoadFile($file);
    }

    return;
}
sub set_defaults {
    $config->{conf}{max_search_history} ||= 10;
    $config->{recent_searches}          ||= [];
}


sub get_config {
    return $config;
}

sub get_help {
    my $f = join "\n",  App::Ack::filetypes_supported();
    # TODO: get the copyright from ack automatically
    #my $ack_copyrioght = App::Ack::version_statement($COPYRIGHT);
    #my $ack_copyright = App::Ack::get_copyright();
    my $thppt = App::Ack::_get_thpppt();

    my $ack_version = $App::Ack::VERSION;
    my $warning = '';
    my $dev_version = '1.78';
    if ($ack_version ne $dev_version) {
        $warning =  "\nThis version of Wack was developed with ack version $dev_version.\n";
        $warning .= "As you are currently using version $ack_version, there might be\n";
        $warning .= "some issues related to the version mismatch\n";
    }
    my $help = <<"END_HELP";
This is version $VERSION of wack
Using ack version $App::Ack::VERSION
Gtk version: $Gtk2::VERSION
Perl version: $]

wack, Copyright 2007-2008 Gabor Szabo http://search.cpan.org/dist/App-Wack
ack,  Copyright 2005-2008 Andy Lester http://search.cpan.org/dist/ack
Gtk2, Copyright 2003-2008 the gtk2-perl team http://search.cpan.org/dist/Gtk2
perl, Copyright 1987-2008 Larry Wall http://search.cpan.org/dist/perl

$thppt

$warning

There are currently two ways of using Wack.

Ack mode:
Select a directory (or a file) by pressing the Browse button.
Type in a search string or regular expression.
Select one or more of the checkboxes on the left and select the
before and after context values.
Click on search.


In-memory mode:
Select a single file by pressing the Browse button.
Check the "In memory" checkbox. The files should be loaded in the viewer.
Type in a search string or regular expression and check (or uncheck) the options.
Currently supporting the
Invert Match, Ignore Case checkboxes and the before and after context selectors.
The matching lines should be displayed as you make your changes.


END_HELP

    return $help;
}

sub _update_regex_history {
    my ($regex) = @_;

    my @recent_searches = @{ $config->{recent_searches} };
    if ($regex) {
        my @temp = grep {$regex ne $_} @recent_searches;
        if (@temp != @recent_searches) {
            @recent_searches = @temp;
        } elsif (@recent_searches >= $config->{conf}{max_search_history}) {
            shift @recent_searches;
        }
        push @recent_searches, $regex;
    }
    $config->{recent_searches} = \@recent_searches;
    return \@recent_searches;
}

sub _validate_regex {
    my ($regex) = @_;
    if (not $config->{opts}{Q}) {    # literal
        eval "qr/$regex/";           ## no critic
        if ($@) {
            (my $error = $@) =~ s/ at \(eval \d+\).*//;
            die "$error\n";
        }
    }
    return 1;
}

   
#sub directory_changed_cb {
#    exit;
#}

# see t/module.t in ack distro
sub fill_type_wanted {
    for my $i ( App::Ack::filetypes_supported() ) {
        $App::Ack::type_wanted{ $i } = undef;
    }
}


sub ack {
    my ($regex, $dir) = @_;
    #say $regex;
    #say $dir;
#    $gladexml->get_widget('stop-button')->activate;

#    my $count = 0;
    #$gladexml->get_widget('stop-button')->set('sensitive', 1);
#    $gladexml->get_widget('stop-button')->sensitive(1);
    #return;

#   if (open my $ACK, "ack $str $dir |") { ## no critic
#        $tag = Gtk2::Helper->add_watch( fileno( $ACK ), in => sub {
#            if ( $stop_now or eof( $ACK ) ) {
#                close( $ACK );
#                #$gladexml->get_widget('stop-button')->set('sensitive', 0);
#                Gtk2::Helper->remove_watch( $tag );
#            } else {
#                my $line = <$ACK>;
#                $cb->($line);
#            }
#            return 1;
#        } );
#
#    } else {
#        show_error("Could not find the ack executable.");
#    }
#    return;

    my $config = get_config();
    my %opts = %{ $config->{opts} };

    $opts{regex} = $regex;
    if (-f $dir) {
        $opts{all} = 1;
    }
#    print Dumper \%opts;

    my $what = App::Ack::get_starting_points( [$dir], \%opts );
    fill_type_wanted();
#    $App::Ack::type_wanted{cc} = 1;

    #$opts{show_filename} = 1;
#    $opts{follow} = 0;
    my $iter = App::Ack::get_iterator( $what, \%opts );
    App::Ack::filetype_setup();
    App::Ack::print_matches( $iter, \%opts );
}


sub search {
    my ($search) = @_;
    my $opts = get_options();
    my $modifiers = '' . ($opts->{i} ? 'i' : '');
    my $invert = $opts->{v};
    
    my $regex = eval "qr/$search/$modifiers"; ## no critic
    # turn on some visible but not inturisve flag that indicates the current regex is invalid?
    die $@ if $@;

    my @selected;
    my $last_line;
    for my $i (0..@content-1) {
        my $add = $invert ? $content[$i] !~ /$regex/ : $content[$i] =~ /$regex/;
        if ($add) {
            for my $j ( max(0, $i - $opts->{before_context}) .. min($#content, $i + $opts->{after_context}) ) {
                if (not defined $last_line or $j > $last_line) {
                    push @selected, "$j: $content[$j]";
                    $last_line = $j;
                }
            }
        }
    }
    return join '', @selected;
}

sub get_options {
    my $config = get_config();
    return $config->{opts};
}

sub set_option {
    my ($name, $value) = @_;

    if (defined $value and $value ne '') {
        $config->{opts}{$name} = $value;
    } else {
        delete $config->{opts}{$name};
    }

    return;
}


sub read_file {
    my ($file) = @_;
    open my $fh, '<', $file or return;

    @content = <$fh>;
    return join '', @content;
}



=head1 NAME

App::Wack - the wisual ack

=head1 SYNOPSIS

You should only use the 

 wack

command and not the module itself.

=head1 DESCRIPTION

App::Wack is the implementation of the Gtk2 and GladeXML based 
GUI around L<ack>, the grep-like text finder.

=head1 DEVELOPMENT

Subversion repository:
L<http://svn1.hostlocal.com/szabgab/trunk/wack/>

Bugs L<https://rt.cpan.org/> 
Email: bug-app-wack to rt.cpan.org

=head1 TODO

add more of the available flags as checkboxes

add the selected file type list as a configuration option
File selection available in ack:

 -  default
 -a all files
    
Show some sign that search is still in progress (and/or that search ended) 

Allow the user to abort search in the middle

Highlight the matches.

Allow loading a file into memory and allow "work as I type the regex" mode meaning
the results are updated after every change in the regex.

Remember previous regexes
Remember previously search file and directory names

Bug: If the file/directory window is closed by ESC or by clicking on the x 
it cannot be opened again.

=head1 COPYRIGHT

Copyright 2007-2008 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

