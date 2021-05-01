package Complete::Rclone;

# AUTHORITY
# DATE
# DIST
# VERSION

use 5.010001;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       complete_rclone_remote
               );

our %SPEC;

our %argspecs_common = (
    config_filenames => {
        schema => ['array*', of=>'filename*'],
        tags => ['category:configuration'],
    },
    config_dirs => {
        schema => ['array*', of=>'filename*'],
        tags => ['category:configuration'],
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to rclone',
};

sub _parse_rclone_config {
    my %args = @_;

    my @dirs      = @{ $args{config_dirs} // ["$ENV{HOME}/.config/rclone", "/etc/rclone", "/etc"] };
    my @filenames = @{ $args{config_filenames} // ["rclone.conf"] };

    my @paths;
    for my $dir (@dirs) {
        for my $filename (@filenames) {
            my $path = "$dir/$filename";
            next unless -f $path;
            push @paths, $path;
        }
    }
    unless (@paths) {
        return [412, "No config paths found/specified"];
    }

    require Config::IOD::Reader;
    my $reader = Config::IOD::Reader->new;
    my $merged_config_hash;
    for my $path (@paths) {
        my $config_hash;
        eval { $config_hash = $reader->read_file($path) };
        return [500, "Error in parsing config file $path: $@"] if $@;
        for my $section (keys %$config_hash) {
            my $hash = $config_hash->{$section};
            for my $param (keys %$hash) {
                $merged_config_hash->{$section}{$param} = $hash->{$param};
            }
        }
    }
    [200, "OK", $merged_config_hash];
}


$SPEC{complete_rclone_remote} = {
    v => 1.1,
    summary => 'Complete from a list of configured rclone remote names',
    args => {
        word => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        %argspecs_common,
        type => {
            schema => 'str*',
            tags => ['category:filtering'],
        },
    },
    result_naked => 1,
};
sub complete_rclone_remote {
    require Complete::Util;

    my %args = @_;

    my $res = _parse_rclone_config(%args);
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
