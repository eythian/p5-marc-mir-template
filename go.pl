package MIR::Template;
use Modern::Perl;

sub _control {
    my $k = shift;
    sub {
        my ( $out, $content ) = @_;
        ref $content and die "trying to load a ref in $k";
        $$out{ $k } = $content;
    }
}

sub _data {
    my ( $field, $tag ) = @_;
    sub {
        my ( $out, $content ) = @_;
        push @{ $$out{$field} }, [ $tag, $content ];
    }
}


sub new {
    my ( $pkg, $spec ) = @_;
    my %template;
    while ( my @pair = each %$spec ) {
        my ( $k, $v ) = @pair;
        given ( ref $v ) {
            when ('') { $template{ $v } = _control $k }
            when ('HASH') {
                while ( my ( $subk, $subv ) = each %$v ) {
                    $template{ $subv } = _data $k, $subk;
                }
            }
            when ('ARRAY') {
                # my ( $field, $fieldspec ) = @$v;
                # $template{ $field } = _mv_data $fieldspec;
            }
        }
    }
    bless \%template, __PACKAGE__;
}

sub mir {
    my ( $template, $source ) = @_;
    my $out = {};
    while ( my ( $k, $v ) = each %$source ) {
        my $t = $$template{ $k } or next;
        $t->( $out, $v );
    }
    $out
}

package main;
use Modern::Perl;
use YAML ();

my $spec = YAML::Load << '';
    001: id
    200: [ authors, { a: name, b: [firstname] } ]
    300: { a: title, b: subtitle }

my $data = YAML::Load  << '';
    authors:
        - { name: Doe, firstname: [john, elias, frederik] }
        - { name: Doe, firstname: jane }
    title: "i can haz title"
    subtitle: "also subs"
    id: PPNxxxx

my $expected = YAML::Load << '';
    - [001, PPNxxxx ]
    - [200, [ [a, Doe], [b, john], [b, elias], [b, frederik] ]]
    - [200, [ [a, Doe], [b, jane]                            ]]
    - [300, [ [a, "i can haz title"], [b, "also subs"]       ]]

my $template = MIR::Template->new( $spec );
my $out  = $template->mir( $data );
say YAML::Dump $out;

