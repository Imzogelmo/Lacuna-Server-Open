package Lacuna::DB::Message;

use Moose;
extends 'SimpleDB::Class::Item';
use DateTime;
use DateTime::Format::Strptime;

__PACKAGE__->set_domain_name('message');
__PACKAGE__->add_attributes(
    in_reply_to     => { isa => 'Str' },
    subject         => { isa => 'Str' },
    body            => { isa => 'MediumStr' },
    date_sent       => { isa => 'DateTime' },
    from_id         => { isa => 'Str' },
    from_name       => { isa => 'Str' },
    to_id           => { isa => 'Str' },
    to_name         => { isa => 'Str' },
    has_read        => { isa => 'Str', default=>0 },
    has_replied     => { isa => 'Str', default=>0 },
    has_archived    => { isa => 'Str', default=>0 },
);

__PACKAGE__->belongs_to('original_message', 'Lacuna::DB::Message', 'in_reply_to');
__PACKAGE__->belongs_to('sender', 'Lacuna::DB::Empire', 'from_id');
__PACKAGE__->belongs_to('receiver', 'Lacuna::DB::Empire', 'to_id');

sub date_sent_formatted {
    my ($self) = @_;
    return DateTime::Format::Strptime::strftime('%d %m %Y %H:%M:%S %z',$self->date_sent);
}


sub send {
    my ($class, %params) = @_;
    my $recipients = $params{recipients};
    unless (@{$recipients}) {
        $recipients->[0] = $params{to}->name;
    }
    my $self = $class->new(
        simpledb    => $params{simpledb},
        date_sent   => DateTime->now,
        subject     => $params{subject},
        body        => $params{body},
        from_id     => $params{from}->id,
        from_name   => $params{from}->name,
        to_id       => $params{to}->id,
        to_name     => $params{to}->name,
        recipients  => $recipients,
        in_reply_to => $params{in_reply_to},
    );
    $self->put;
    if ($params{in_reply_to} ne '') {
        my $original = $params{simpledb}->dommain($class)->find($params{in_reply_to});
        if (defined $original && !$original->has_replied) {
            $original->has_replied(1);
            $original->put;
        }
    }
    return $self;
}

no Moose;
__PACKAGE__->meta->make_immutable;
