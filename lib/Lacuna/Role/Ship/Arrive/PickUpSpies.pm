package Lacuna::Role::Ship::Arrive::PickUpSpies;

use strict;
use Moose::Role;

after handle_arrival_procedures => sub {
    my ($self) = @_;
    my $empire_id = $self->body->empire_id;
    my $spies = Lacuna->db->resultset('Lacuna::DB::Result::Spies');
    my $cargo_log = Lacuna->db->resultset('Lacuna::DB::Result::Log::Cargo');

    # we're coming home
    return if ($self->direction eq 'in');

    $cargo_log->new({
        message     => 'before pick up spies',
        body_id     => $self->foreign_body_id,
        data        => $self->payload,
        object_type => ref($self),
        object_id   => $self->id,
    })->insert;
    my @riding;
    foreach my $id (@{$self->payload->{fetch_spies}}) {
        my $spy = $spies->find($id);
        next unless defined $spy;
        $cargo_log->new({
            message     => 'found spy',
            body_id     => $self->foreign_body_id,
            data        => {spy => $id},
            object_type => ref($self),
            object_id   => $self->id,
        })->insert;
        next unless $spy->is_available;
        $cargo_log->new({
            message     => 'spy is available',
            body_id     => $self->foreign_body_id,
            data        => {spy => $id},
            object_type => ref($self),
            object_id   => $self->id,
        })->insert;
        next unless $spy->empire_id eq $empire_id;
        $cargo_log->new({
            message     => 'empire matches up',
            body_id     => $self->foreign_body_id,
            data        => {spy => $id},
            object_type => ref($self),
            object_id   => $self->id,
        })->insert;
        push @riding, $spy->id;
        $spy->available_on($self->date_available);
        $spy->on_body_id($self->body_id);
        $spy->task('Travelling');
        $spy->started_assignment(DateTime->now),
        $spy->update;
    }
    my $payload = $self->payload;
    delete $payload->{fetch_spies};
    $payload->{spies} = \@riding;
    $self->payload($payload);
    $cargo_log->new({
        message     => 'after pick up spies',
        body_id     => $self->foreign_body_id,
        data        => $self->payload,
        object_type => ref($self),
        object_id   => $self->id,
    })->insert;
};

1;