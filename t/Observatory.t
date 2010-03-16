use lib '../lib';
use Test::More tests => 4;
use Test::Deep;
use Data::Dumper;
use 5.010;
use DateTime;

use TestHelper;
my $tester = TestHelper->new->generate_test_empire;
my $session_id = $tester->session->id;
my $empire = $tester->empire;
my $home = $empire->home_planet;
my $command = $home->command;


my $result;


my $uni = Lacuna::DB::Building::University->new(
    simpledb        => $tester->db,
    x               => 0,
    y               => -1,
    class           => 'Lacuna::DB::Building::University',
    date_created    => DateTime->now,
    body_id         => $home->id,
    body            => $home,
    empire_id       => $empire->id,
    empire          => $empire,
    level           => 2,
);
$home->build_building($uni);
$uni->finish_upgrade;

$home->ore_capacity(500000);
$home->energy_capacity(500000);
$home->food_capacity(500000);
$home->water_capacity(500000);
$home->bauxite_stored(500000);
$home->algae_stored(500000);
$home->energy_stored(500000);
$home->water_stored(500000);
$home->put;


$result = $tester->post('spaceport', 'build', [$session_id, $home->id, 0, 1]);
my $spaceport = $empire->get_building('Lacuna::DB::Building::SpacePort',$result->{result}{building}{id});
$spaceport->finish_upgrade;

$home->energy_hour(500000);
$home->algae_production_hour(500000);
$home->water_hour(500000);
$home->ore_hour(500000);
$home->put;

$result = $tester->post('shipyard', 'build', [$session_id, $home->id, 0, 2]);
my $shipyard = $empire->get_building('Lacuna::DB::Building::Shipyard',$result->{result}{building}{id});
$shipyard->finish_upgrade;

$home->energy_hour(500000);
$home->algae_production_hour(500000);
$home->water_hour(500000);
$home->ore_hour(500000);
$home->put;

$result = $tester->post('observatory', 'build', [$session_id, $home->id, 0, 3]);
ok($result->{result}{building}{id}, "built an observatory");
my $observatory = $empire->get_building('Lacuna::DB::Building::Observatory',$result->{result}{building}{id});
$observatory->finish_upgrade;

$result = $tester->post('shipyard', 'get_buildable', [$session_id, $shipyard->id]);
is($result->{result}{buildable}{probe}{can}, 1, "probes are buildable");

$home->ore_capacity(500000);
$home->energy_capacity(500000);
$home->food_capacity(500000);
$home->water_capacity(500000);
$home->bauxite_stored(500000);
$home->algae_stored(500000);
$home->energy_stored(500000);
$home->water_stored(500000);
$home->put;

$result = $tester->post('shipyard', 'build_ship', [$session_id, $shipyard->id, 'probe']);
ok(exists $result->{result}{ship_build_queue}{next_completed}, "got a date of completion");
is($result->{result}{ship_build_queue}{queue}[0]{type}, 'probe', "probe building");


END {
    $tester->cleanup;
}
