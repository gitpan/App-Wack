use strict;
use warnings;
use Module::Build;

if (-e 'create_glade') {
    system "$^X -I lib create_glade";
}

my $build = Module::Build->new(
    module_name        => 'App::Wack',
    dist_version_from  => 'lib/App/Wack.pm',
    license            => 'perl',
    create_makefile_pl => 'traditional',
    script_files       => 'bin/wack',
    requires           => {
            'Gtk2'                   => '1.080', 
            'Gtk2::GladeXML'         => '0',
            'App::Ack'               => '1.64',
    },
);

$build->create_build_script;

