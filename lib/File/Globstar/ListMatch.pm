# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

# This next lines is here to make Dist::Zilla happy.
# ABSTRACT: Perl Globstar (double asterisk globbing) and utils

package File::Globstar::ListMatch;

use strict;

use File::Globstar qw(translatestar);
use Scalar::Util qw(reftype);

sub new {
    my ($class, $input, %options) = @_;

    my $self = {};
    bless $self, $class;
    $self->{__ignore_case} = delete $options{ignoreCase};
    $self->{__is_ignore} = delete $options{isExclude};

    if (ref $input) {
        my $type = reftype $input;
        if ('SCALAR' eq $type) {
           $self->_readString($$input);
        } elsif ('ARRAY' eq $type) {
           $self->_readArray($input);
        } else {
           die "reference to file handle\n";
        }
    } elsif ("GLOB" eq ref \$input) {
        die "GLOB\n";
    } else {
        die "filename\n";
    }

    return $self;
}

sub patterns {
    return @{shift->{__patterns}};
}

sub _readArray {
    my ($self, $lines) = @_;

    my @patterns;
    $self->{__patterns} = \@patterns;

    my $ignore_case = $self->{__ignoreCase};
    foreach my $line (@$lines) {
        my $transpiled = eval { translatestar $line, $ignore_case };
        if ($@) {
            $transpiled = quotemeta $line;
            if ($ignore_case) {
                push @patterns, qr/^$transpiled$/i;
            } else {
                push @patterns, qr/^$transpiled$/;
            }
        } else {
            push @patterns, $transpiled;
        }
    }

    return $self;
}

sub _readString {
    my ($self, $string) = @_;

    my @lines;
    foreach my $line (split /\n/, $string) {
        next if $line =~ /^#/;
        push @lines, $line;
    }

    $self->_readArray(\@lines);

    return $self;
}

1;
