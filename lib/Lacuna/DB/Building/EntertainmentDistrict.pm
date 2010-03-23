package Lacuna::DB::Building::EntertainmentDistrict;

use Moose;
extends 'Lacuna::DB::Building';

use constant controller_class => 'Lacuna::Building::Entertainment';

use constant university_prereq => 2;

use constant image => 'entertainment';

use constant name => 'Entertainment District';

use constant food_to_build => 500;

use constant energy_to_build => 500;

use constant ore_to_build => 800;

use constant water_to_build => 500;

use constant waste_to_build => 500;

use constant time_to_build => 300;

use constant food_consumption => 100;

use constant energy_consumption => 100;

use constant ore_consumption => 10;

use constant water_consumption => 100;

use constant waste_production => 300;

use constant happiness_production => 200;



no Moose;
__PACKAGE__->meta->make_immutable;
