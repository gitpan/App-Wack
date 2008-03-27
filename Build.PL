use strict;
use warnings;

use 5.006;

use Module::Build;

# in the development environment only
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
            'App::Ack'               => '1.78',
            'File::HomeDir'          => '0',
            'YAML'                   => '0',

            'Carp'                   => '0',
            'Cwd'                    => '0',
            'File::Spec'             => '0',
            'List::Util'             => '0',
    },
    build_requires     => {
            'Test::More'             => '0',
            'Test::Pod'              => '0',
            'Test::Pod::Coverage'    => '0',
    },
);

$build->create_build_script;

