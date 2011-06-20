#!C:/perl/bin/perl -w

use open_flash_chart;


my $g = chart->new();
  
my $e = $g->get_element('bar_stack');

$e->set_values([
  [{"val"=>rand(20),"colour"=>random_color()},{"val"=>rand(40),"colour"=>random_color()}],
  [{"val"=>rand(20),"colour"=>random_color()},{"val"=>rand(20),"colour"=>random_color()},{"val"=>rand(20),"colour"=>random_color()}],
  [{"val"=>rand(10)},{"val"=>rand(20)},{"val"=>rand(30)}],
  [{"val"=>rand(20)},{"val"=>rand(20)},{"val"=>rand(20)}],
  [{"val"=>rand(5)},{"val"=>rand(10)},{"val"=>rand(5)},{"val"=>rand(20)},{"val"=>rand(5),"colour"=>random_color()},{"val"=>rand(5)},{"val"=>rand(5)}]
 ]);  

$g->add_element($e);



print $g->render_chart_data();
