package Lacuna::RPC::Building::Shipyard;

use Moose;
use utf8;
no warnings qw(uninitialized);
extends 'Lacuna::RPC::Building';
use Lacuna::Constants qw(SHIP_TYPES);


sub app_url {
    return '/shipyard';
}


sub model_class {
    return 'Lacuna::DB::Result::Building::Shipyard';
}


sub view_build_queue {
    my ($self, $session_id, $building_id, $page_number) = @_;

    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id);
    my $body        = $building->body;
    $page_number ||= 1;
    my @constructing;
    my $fleets = $building->fleets_under_construction;

    my ($sum) = $fleets->search(undef, {
        "+select" => [
            { count => 'id' },
            { sum   => 'quantity' },
        ],
        "+as" => [qw(number_of_fleets number_of_ships)],
    });
    $fleets = $fleets->search({},
        { order_by    => 'date_available', rows => 25, page => $page_number },
    );

    while (my $fleet = $fleets->next) {
        push @constructing, {
            id              => $fleet->id,
            type            => $fleet->type,
            type_human      => $fleet->type_formatted,
            date_completed  => $fleet->date_available_formatted,
            quantity        => $fleet->quantity,
        }
    }

    return {
# TODO TODO TODO        status                      => $self->format_status($empire, $body),
        number_of_fleets_building   => $sum->get_column('number_of_fleets'),
        fleets_building             => \@constructing,
        cost_to_subsidize           => $sum->get_column('number_of_ships') || 0,
        building                    => {
            work        => {
                seconds_remaining   => $building->work_seconds_remaining,
                start               => $building->work_started_formatted,
                end                 => $building->work_ends_formatted,
            },
        },
    };
}


sub subsidize_build_queue {
    my ($self, $session_id, $building_id) = @_;

    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id);
    my $body        = $building->body;
    my $fleets      = $building->fleets_under_construction;
    my $cost        = $fleets->count;

    unless ($empire->essentia >= $cost) {
        confess [1011, "Not enough essentia."];    
    }

    $empire->spend_essentia($cost, 'fleet build subsidy after the fact');
    $empire->update;

    while (my $fleet = $fleets->next) {
        $fleet->finish_construction;
    }
    $building->finish_work->update;
 
    return $self->view($empire, $building);
}


sub build_fleet {
    my ($self, $session_id, $building_id, $type, $quantity) = @_;

    $quantity = defined $quantity ? $quantity : 1;
    if ($quantity <= 0 or int($quantity) != $quantity) {
        confess [1001, "Quantity must be a positive integer"];
    }
    my $empire      = $self->get_empire_by_session($session_id);
    my $building    = $self->get_building($empire, $building_id);
    my $body_id     = $building->body_id;

    my $fleet = Lacuna->db->resultset('Fleet')->new({
        type        => $type, 
        quantity    => $quantity,
    });
    my $costs = $building->get_fleet_costs($fleet);
    $building->can_build_fleet($fleet, $costs);
    $building->spend_resources_to_build_fleet($costs);
    $building->build_fleet($fleet, $costs->{seconds});
    $fleet->body_id($body_id);
    $fleet->insert;

    return $self->view_build_queue($empire, $building);
}


sub get_buildable {
    my ($self, $session_id, $building_id, $tag) = @_;

    my $empire = $self->get_empire_by_session($session_id);
    my $building = $self->get_building($empire, $building_id);
    my %buildable;
    foreach my $type (SHIP_TYPES) {
        my $fleet = Lacuna->db->resultset('Lacuna::DB::Result::Fleet')->new({ type => $type, quantity => 1 });
        my @tags = @{$fleet->build_tags};
        if ($tag) {
            next unless ($tag ~~ \@tags);
        }
        my $can = eval{$building->can_build_fleet($fleet)};
        my $reason = $@;
        $buildable{$type} = {
            attributes  => {
                speed           => $building->set_fleet_speed($fleet),
                stealth         => $building->set_fleet_stealth($fleet),
                hold_size       => $building->set_fleet_hold_size($fleet),
                berth_level     => $fleet->base_berth_level,
                combat          => $building->set_fleet_combat($fleet),
                max_occupants   => $fleet->max_occupants
            },
            tags        => \@tags,
            cost        => $building->get_fleet_costs($fleet),
            can         => ($can) ? 1 : 0,
            reason      => $reason,
            type_human  => $fleet->type_formatted,
        };
    }
    my $docks = 0;
    my $port = $building->body->spaceport;
    if (defined $port) {
        $docks = $port->docks_available;
    }
    return {
        buildable       => \%buildable,
        docks_available => $docks,
        status          => $self->format_status($empire, $building->body),
        };
}


__PACKAGE__->register_rpc_method_names(qw(get_buildable build_fleet view_build_queue subsidize_build_queue));


no Moose;
__PACKAGE__->meta->make_immutable;

