
use strict;
use warnings;
use Test::More;

eval {
    require Test::Pod::Coverage;
    import Test::Pod::Coverage;
};
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"; # if $@;
all_pod_coverage_ok();
__END__
if ($@) {
    plan skip_all => 
        "Test::Pod::Coverage 1.08 required for testing POD coverage";
} else {
    plan tests => 1;
}
#all_pod_coverage_ok();
pod_coverage_ok( "CGI::FileManager", "CGI::FileManager::Auth" );

