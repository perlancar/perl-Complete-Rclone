package Complete::Rclone;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Rclone::Util ();

use Exporter 'import';
our @EXPORT_OK = qw(
                       complete_rclone_remote
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to rclone',
};

$SPEC{complete_rclone_remote} = {
    v => 1.1,
    summary => 'Complete from a list of configured rclone remote names',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        %Rclone::Util::argspecs_common,
        type => {
            summary => 'Only list remotes of a certain type (e.g. "drive" for Google Drive, "google photos" for Google Photos)',
            schema => 'str*',
            tags => ['category:filtering'],
        },
    },
    result_naked => 1,
};
sub complete_rclone_remote {
    require Complete::Util;
    require Hash::Subset;

    my %args = @_;

    my $res = Rclone::Util::parse_rclone_config(Hash::Subset::hash_subset(\%args, \%Rclone::Util::argspecs_common));
    return {message=>"Can't parse rclone config files: $res->[1]"} unless $res->[0] == 200;
    my $config = $res->[2];

    Complete::Util::complete_array_elem(
        word  => $args{word},
        array => [$args{type} ? (grep {$config->{$_}{type} eq $args{type}} sort keys %$config) : (sort keys %$config)],
    );
}

1;
# ABSTRACT:

=for Pod::Coverage .+

=head1 SEE ALSO

L<Complete>

L<https://rclone.org>
