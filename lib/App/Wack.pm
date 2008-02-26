package App::Wack;
use strict;
use warnings;

use Gtk2 -init;
use Gtk2::GladeXML;
use App::Ack;
use App::Wack::Glade;
use Cwd;

our $VERSION = '0.04';

my $gladexml;

sub run {
    my ($class) = @_;
     
    $gladexml = Gtk2::GladeXML->new_from_buffer(App::Wack::Glade::get_xml());
    $gladexml->signal_autoconnect_from_package("App::Wack");

    $gladexml->get_widget('directory')->set_text(cwd);
    Gtk2->main;
}

AUTOLOAD {
    our $AUTOLOAD;
	print $AUTOLOAD . "\n";
}
sub DESTROY {
}

sub on_help_clicked {

    my $f = join "\n",  App::Ack::filetypes_supported();
    # TODO: get the copyright from ack automatically
    #my $ack_copyrioght = App::Ack::version_statement($COPYRIGHT);
    #my $ack_copyright = App::Ack::get_copyright();
    my $thppt = App::Ack::_get_thpppt();

    my $ack_version = $App::Ack::VERSION;
    my $warning = '';
    my $dev_version = '1.76';
    if ($ack_version ne $dev_version) {
        $warning =  "\nThis version of Wack was developed with ack version $dev_version.\n";
        $warning .= "As you are currently using version $ack_version, there might be\n";
        $warning .= "some issues related to this version mismatch\n";
    }
    my $help = <<"END_HELP";
This is version $VERSION of wack
Using ack version $App::Ack::VERSION
Gtk version: $Gtk2::VERSION
Perl version: $]

wack, Copyright 2007-2008 Gabor Szabo http://search.cpan.org/dist/App-Wack
ack,  Copyright 2005-2007 Andy Lester http://search.cpan.org/dist/App-Ack
Gtk2, Copyright 2003-2008 the gtk2-perl team http://search.cpan.org/dist/Gtk2
perl, Copyright 1987-2008 Larry Wall http://search.cpan.org/dist/perl

$thppt

$warning

END_HELP
    _set_result($help);
    return;
}

sub _set_result {
    my ($text) = @_;

    my $result = $gladexml->get_widget('results')->get_buffer;
    $result->delete($result->get_start_iter, $result->get_end_iter,);
    $result->set_text($text);  
    return;
}

sub on_activate {
    on_search_clicked();
}

sub on_search_activate {
    on_search_clicked();
}

sub check_toggled {
    $gladexml->get_widget('search-text')->grab_focus;
}

sub on_search_clicked {
    my $result = $gladexml->get_widget('results')->get_buffer;
    my $search = $gladexml->get_widget('search-text');
    my $text   = $search->get_text;
    my $dir    = $gladexml->get_widget('directory')->get_text();

    my $before = $gladexml->get_widget('before')->get_text();
    my $after  = $gladexml->get_widget('after')->get_text();
    $before = $before ? "-B $before" : '';
    $after  = $after  ? "-A $after"  : '';


    my %options = (
        'check-case-sensitive' => '-i',
        'check-invert-match'   => '-v',
        'check-word-regexp'    => '-w',
        'check-literal'        => '-Q',
        'check-subdirs'        => '-n',
        'check-all-types'      => '-a',
    );
    foreach my $widget (keys %options) {
        if ($gladexml->get_widget($widget)->get_active) {
            $text .= " $options{$widget} ";
        }
    }
    $text .= " $before $after ";
    
    my $out = '';
    ack($dir, $text, sub {$out .= shift});
    _set_result($out); 
}

sub on_main_destroy {
	Gtk2->main_quit;
    exit;
}
sub on_quit_clicked {
	Gtk2->main_quit;
    exit;
}

#sub directory_changed_cb {
#    exit;
#}

sub on_config_clicked {
    warn "Not implemented yet\n";
}

sub browse_button_clicked {
    my $dir    = $gladexml->get_widget('directory')->get_text();
    if (-d $dir) {
        $gladexml->get_widget('directory-selector')->set_current_folder($dir);
    }
    $gladexml->get_widget('directory-selector')->show;
    return; 
}

sub directory_window_closed {
    #print "1\n";
    #if ($gladexml->get_widget('directory-selector')) {
        #$gladexml->get_widget('directory-selector')->hide;
    #}
    return;
}
sub directory_selector_delete_event_cb {
    # when directory closed with escape or x
    # but it still gets destroyed
    return;
}

sub directory_ok_clicked {
    my $filename = $gladexml->get_widget('directory-selector')->get_filename;
    $gladexml->get_widget('directory')->set_text($filename);
    $gladexml->get_widget('directory-selector')->hide;
    return;
}

sub directory_cancel_clicked {
    $gladexml->get_widget('directory-selector')->hide;
    return;
}

sub ack {
    my ($dir, $str, $cb) = @_;
    #chdir $dir;
    open (my $ACK, "ack $str $dir |") or die;
    while (my $line = <$ACK>) {
        $cb->($line);
    }
}


=head1 NAME

App::Wack - the actual code of wack the wisual ack

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
    

work with Andy on ack to allow me to call the module directly 
instead of the executable

show some sign that search is still in progress (and/or that search ended) 

Allow the user to abort search in the middle

When selecting specific file make sure it is acked even if all the other flags are not set.

=head1 COPYRIGHT

Copyright 2007-2008 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

