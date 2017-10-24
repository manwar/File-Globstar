# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>, 
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use strict;

use Test::More;

ok require File::Globstar::ListMatch;

sub unref;

my ($matcher, $input, @patterns);

$input = [qw (Tom Dick Harry)];
$matcher = File::Globstar::ListMatch->new($input);
is_deeply [unref $matcher->patterns], [
    qr{^Tom$},
    qr{^Dick$},
    qr{^Harry$},
], 'array input';

$input = <<EOF;
FooBar
BarBaz
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    qr{^FooBar$},
    qr{^BarBaz$}
], 'string input';

$input = <<EOF;
# Comment
FooBar
# Comment
BarBaz
# Comment
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    qr{^FooBar$},
    qr{^BarBaz$}
], 'discard comments';

my $space = ' ';
my $whitespace = "\x09\x0a\x0b\x0c\x0d$space";

$input = <<EOF;

FooBar
$whitespace
BarBaz
$whitespace$whitespace
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    qr{^FooBar$},
    qr{^BarBaz$}
], 'discard empty lines';

$input = <<EOF;
foo\\bar
foo\\\\bar
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    qr{^foobar$},
    qr{^foo\\bar$}
], 'backslash escape regular characters';

$input = <<EOF;
trailing space$whitespace
escaped space\\$space
not escaped space\\\\$space
escaped space again\\\\\\\\\\$space$whitespace
\\$space
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    qr{^trailing\ space$},
    qr{^escaped\ space\ $},
    qr{^not\ escaped\ space\\$},
    qr{^escaped\ space\ again\\\\\ $},
    qr{^\ $},
], 'trailing whitespace';

open HANDLE, '<', 't/patterns' 
    or die "Cannot open 't/patterns' for reading: $!";
$matcher = File::Globstar::ListMatch->new(*HANDLE, filename => 't/patterns');
is_deeply [unref $matcher->patterns], [
    qr{^foo$},
    qr{^bar$},
    qr{^baz$},
], 'read from GLOB';

open my $fh, '<', 't/patterns' 
    or die "Cannot open 't/patterns' for reading: $!";
$matcher = File::Globstar::ListMatch->new($fh, filename => 't/patterns');
is_deeply [unref $matcher->patterns], [
    qr{^foo$},
    qr{^bar$},
    qr{^baz$},
], 'read from GLOB';

$matcher = File::Globstar::ListMatch->new('t/patterns');
is_deeply [unref $matcher->patterns], [
    qr{^foo$},
    qr{^bar$},
    qr{^baz$},
], 'read from GLOB';

$input = <<EOF;
!negated
/full-match
!/negated-full-match
directory/
!negated-directory/
!negated/full-match-directory/
EOF
$matcher = File::Globstar::ListMatch->new(\$input);
is_deeply [unref $matcher->patterns], [
    qr{^negated$},
    qr{^full\-match$},
    qr{^negated\-full\-match$},
    qr{^directory$},
    qr{^negated\-directory$},
    qr{^negated\/full\-match\-directory$},
], 'strip-off';

done_testing;

sub unref {
    my (@patterns) = @_;

    return map { $$_ } @patterns;
}