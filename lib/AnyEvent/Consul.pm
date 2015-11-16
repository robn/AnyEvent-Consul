package AnyEvent::Consul;

# ABSTRACT: Make async calls to Consul via AnyEvent

use warnings;
use strict;

use Consul;
use AnyEvent::HTTP qw(http_request);
use Hash::MultiValue;

sub new {
    shift;
    Consul->new(@_, req_cb => sub {
        my ($self, $method, $url, $headers, $content, $cb) = @_;
        http_request($method, $url, body => $content, headers => $headers->as_hashref, sub {
            my ($rdata, $rheaders) = @_;
            my $rstatus = $rheaders->{Status};
            my $rreason = $rheaders->{Reason};
            delete $rheaders->{$_} for grep { m/^[A-Z]/ } keys %$rheaders;
            $cb->($rstatus, $rreason, Hash::MultiValue->from_mixed($rheaders), $rdata);
        });
        return;
    });
}

sub acl     { shift->new(@_)->acl     }
sub agent   { shift->new(@_)->agent   }
sub catalog { shift->new(@_)->catalog }
sub event   { shift->new(@_)->event   }
sub health  { shift->new(@_)->health  }
sub kv      { shift->new(@_)->kv      }
sub session { shift->new(@_)->session }
sub status  { shift->new(@_)->status  }

1;

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Consul - Make async calls to Consul via AnyEvent

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Consul;
    
    my $cv = AE::cv;
    
    my $kv = AnyEvent::Consul->kv;

    # do some blocking op to discover the current index
    $kv->get("mykey", cb => sub { 
        my ($v, $meta) = @_;
    
        # now set up a long-poll to watch a key we're interested in
        $kv->get("mykey", index => $meta->index, cb => sub {
            my ($v, $meta) = @_;
            say "mykey changed to ".$v->value;
            $cv->send;
        });
    });
    
    # make the change
    $kv->put("mykey" => "newval");
    
    $cv->recv;

=head1 DESCRIPTION

AnyEvent::Consul is a thin wrapper around L<Consul> to connect it to
L<AnyEvent::HTTP> for asynchronous operation.

It takes the same arguments and methods as L<Consul> itself, so see the
documentation for that module for details. The important difference is that you
must pass the C<cb> option to the endpoint methods to enable their asynchronous
mode.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/AnyEvent-Consul/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/AnyEvent-Consul>

  git clone https://github.com/robn/AnyEvent-Consul.git

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
