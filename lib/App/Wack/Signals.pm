package App::Wack::Signals;
use strict;
use warnings;

use Carp          qw(croak);
use Cwd           qw(cwd);
use Data::Dumper  qw(Dumper);

use Gtk2::GladeXML;

our $VERSION = '0.01';

sub say { print @_, "\n";}

my $gladexml;

{
    no warnings 'redefine';
    sub App::Ack::print_first_filename { _add_results("$_[0]\n"); }
    sub App::Ack::print_separator      { _add_results("--\n"); }
    sub App::Ack::print                { _add_results($_[0]); }
    sub App::Ack::print_filename       { _add_results("$_[0]$_[1]"); }
    sub App::Ack::print_line_no        { _add_results("$_[0]$_[1]"); }
}

my %options = (
    'check-case-sensitive' => 'i',
    'check-invert-match'   => 'v',
    'check-word-regexp'    => 'w',
    'check-literal'        => 'Q',
    'check-subdirs'        => 'n',
    'check-all-types'      => 'all',
    'before_context'       => 'before_context',
    'after_context'        => 'after_context',
);

AUTOLOAD {
    our $AUTOLOAD;
    if ($ENV{WACK_TESTING}) {
        croak "Missing function '$AUTOLOAD' called";
    } else {
        print $AUTOLOAD . " <-\n";
    }
}
sub DESTROY {
}


sub setup {
    $gladexml = Gtk2::GladeXML->new_from_buffer(App::Wack::Glade::get_xml());
    $gladexml->signal_autoconnect_from_package("App::Wack::Signals");

    return;
}

sub run {
    my ($config) = @_;
    my $recent_searches = $config->{recent_searches};
    _set_options($config->{opts} );
    _update_regex_history_box( $recent_searches );
    $gladexml->get_widget('directory')->set_text(cwd);
    Gtk2->main;
}


sub on_main_destroy {
    _close_app();
}
sub on_quit_clicked {
    _close_app();
}

sub _close_app {
	Gtk2->main_quit;
    App::Wack::save_config();
    exit;
}

sub _set_options {
    my ($opt) = @_;

    foreach my $widget (keys %options) {
        if ($widget eq 'before_context' or $widget eq 'after_context') {
            my $combobox = $gladexml->get_widget($widget);
            foreach (0..4) {
                $combobox->append_text ($_);
            }
            $combobox->set_active($opt->{ $options{$widget} } || 0);
        } else {
            if ($opt->{ $options{$widget} } ) {
                $gladexml->get_widget($widget)->set_active(1);
            }
        }
    }
}


sub on_check_toggled {
    my ($button) = @_;
    my $key = $options{ $button->get_name };
    App::Wack::set_option($key, $button->get_active);

    $gladexml->get_widget('search-text')->grab_focus;

    run_search();

    return;
}
sub on_combo_changed {
    return on_check_toggled(@_);
}


sub _clean_results {
    my $result = $gladexml->get_widget('results')->get_buffer;
    $result->delete($result->get_start_iter, $result->get_end_iter);
    return;
}
sub _set_result {
    my ($text) = @_;

    _clean_results();
    my $result = $gladexml->get_widget('results')->get_buffer;
    $result->set_text($text);  
    return;
}

sub on_check_inmemory_toggled {
    return if not $gladexml->get_widget('check-inmemory')->get_active;
    my $file = $gladexml->get_widget('directory')->get_text();
    # TODO disable the irrelevant buttons and checkboxes?
    # or shall I create a separate window with the available options for the
    # in-memory tool?
    if (not -f $file) {
        show_error("First select a file please");
        $gladexml->get_widget('check-inmemory')->set_active(0);
        return;
    }
    _clean_results();

    if (my $content = App::Wack::read_file($file)) {
        _set_result($content);
    } else {
        show_error("Could not open file $!");
    };

    # TODO turn off the click box if a non-file is selected? What if we are editing the path to get to a new file?
 
    return;
}

sub on_changed_search {
    run_search();
    return;
}

sub run_search {
    return if not $gladexml->get_widget('check-inmemory')->get_active;
    my $search = $gladexml->get_widget('search-text')->child->get_text;

    eval {
        my $result = App::Wack::search($search);
        App::Wack::Signals::_set_result($result);
    };
    if ($@) {
        show_error("regex problem: $@");
    }

    # TODO: highlight
    return;
}

sub _update_regex_history_box {
    my ($searches) = @_;
    my $search_widget = $gladexml->get_widget('search-text');
    $search_widget->get_model->clear;
    foreach my $txt (@$searches) {
        $search_widget->prepend_text($txt);
    }
    return;
}


sub on_search_clicked {
    #my $result   = $gladexml->get_widget('results')->get_buffer;
    my $regex    = $gladexml->get_widget('search-text')->child->get_text;
    my $dir      = $gladexml->get_widget('directory')->get_text();
    #say $regex;
    eval {
        App::Wack::_validate_regex($regex);
    };
    if ($@) {
        show_error("Invalid regex: $@");
        return;
    }

    my $searches = App::Wack::_update_regex_history($regex);
    _update_regex_history_box($searches);
    _clean_results();

    App::Wack::ack($regex, $dir);

    #$opt{m} = $MAX_ROWS;

    return;
}
 
sub on_config_clicked {
    warn "Not implemented yet\n";
}


sub show_error {
    my ($msg) = @_;
#    print "ERROR $msg\n";
    my $dialog = Gtk2::MessageDialog->new ($gladexml->get_widget('main'),
                                             'destroy-with-parent',
                                             'error',
                                             'ok',
                                             $msg);
    my $response = $dialog->run;
    $dialog->destroy;
    return;
}

sub on_browse_button_clicked {
    my $dir    = $gladexml->get_widget('directory')->get_text();
    if (-d $dir) {
        $gladexml->get_widget('directory-selector')->set_current_folder($dir);
    }
    $gladexml->get_widget('directory-selector')->show;
    return; 
}


sub on_directory_window_closed {
    #print "1\n";
    #if ($gladexml->get_widget('directory-selector')) {
        #$gladexml->get_widget('directory-selector')->hide;
    #}
    return;
}
sub on_directory_selector_deleted {
    # when directory closed with escape or x
    # but it still gets destroyed
    return;
}


sub on_directory_ok_clicked {
    my $filename = $gladexml->get_widget('directory-selector')->get_filename;
    $gladexml->get_widget('directory')->set_text($filename);
    $gladexml->get_widget('directory-selector')->hide;
    return;
}

sub on_directory_cancel_clicked {
    $gladexml->get_widget('directory-selector')->hide;
    return;
}

sub _add_results {
    my ($text) = @_;
#say $text;
    my $result = $gladexml->get_widget('results')->get_buffer;
    my $end = $result->get_end_iter;
    $result->insert($end, $text);
    #print $text;
    return;
}

sub on_help_clicked {

    my $help = App::Wack::get_help();
    _set_result($help);
    return;
}
sub on_activate {
    on_search_clicked();
}

sub on_search_activate {
    on_search_clicked();
}

sub on_stop_button_clicked {
    print "STOP\n";
    #$stop_now++;
    return;
}

sub get_gladexml {
    return $gladexml;
}

1;


