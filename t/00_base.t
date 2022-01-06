## no critic
use Test::More;
use Test::Moose::More;

my %classes = (
    'Linux::Hosts' => [
        'add',          'add_alias',    'list', 'remove',
        'remove_alias', 'set_hostname', 'entries'
    ],
    'Linux::Hosts::Entry' => [
        'add_alias', 'remove_alias', 'set_hostname', 'address',
        'aliases',   'hostname'
    ],
    'Linux::Hosts::Exception' => [
        'errno', 'message'
    ],
);

for my $class ( keys %classes ) {
    use_ok($class);
    is_class_ok($class);
    is_immutable_ok($class);
    check_sugar_ok($class);
    for my $method ( @{ $classes{$class} } ) {
        has_method_ok( $class, $method );
    }
}

done_testing();
