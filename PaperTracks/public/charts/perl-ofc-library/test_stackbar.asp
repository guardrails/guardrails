<%@ Language="PerlScript"%>
<% 

# For this test you must have an iis webserver with the perlscript dll installed as a language.
# Also you'll need the open-flash-chart.swf file and the open_flash_chart.pm files together with this one
#

use strict; 
our ($Server, $Request, $Response);
use lib $Server->mappath('.');
use open_flash_chart qw(random_color);

my $g = chart->new();
my $y_axis = $g->get_axis('y_axis');

my $e = $g->get_element('bar_stack');

my $colors = get_random_colors(5);
$e->set_values([
  [{"val"=>rand(20),'colour'=>$colors->[0], 'tip'=>'#val#<br>#total# (bar total)'},{'val'=>rand(40),'colour'=>$colors->[1]}],
  [{"val"=>rand(20),"colour"=>$colors->[0]},{"val"=>rand(20),"colour"=>$colors->[1]},{"val"=>rand(20),"colour"=>$colors->[2]}],
  [{"val"=>rand(10),"colour"=>$colors->[0]},{"val"=>rand(20),"colour"=>$colors->[1]},{"val"=>rand(30),"colour"=>$colors->[2]}],
  [{"val"=>rand(20),"colour"=>$colors->[0]},{"val"=>rand(20),"colour"=>$colors->[1]},{"val"=>rand(20),"colour"=>$colors->[2]}],
  [{"val"=> rand(5),"colour"=>$colors->[0]},{"val"=>rand(10),"colour"=>$colors->[1]},{"val"=> rand(5),"colour"=>$colors->[2]},{"val"=>rand(20),"colour"=>$colors->[3]},{"val"=>rand(5),"colour"=>$colors->[4]}]
 ]);  

$e->set_tip('#total#<br>(bar total)');
$y_axis->add_element($e);


$colors = get_random_colors(5);
$e = $g->get_element('bar_stack');
$e->set_values([
  [{"val"=>rand(20),"colour"=>$colors->[0]},{"val"=>rand(40),"colour"=>$colors->[1]}],
  [{"val"=>rand(20),"colour"=>$colors->[0]},{"val"=>rand(20),"colour"=>$colors->[1]},{"val"=>rand(20),"colour"=>$colors->[2]}],
  [{"val"=>rand(10),"colour"=>$colors->[0]},{"val"=>rand(20),"colour"=>$colors->[1]},{"val"=>rand(30),"colour"=>$colors->[2]}],
  [{"val"=>rand(20),"colour"=>$colors->[0]},{"val"=>rand(20),"colour"=>$colors->[1]},{"val"=>rand(20),"colour"=>$colors->[2]}],
  [{"val"=> rand(5),"colour"=>$colors->[0]},{"val"=>rand(10),"colour"=>$colors->[1]},{"val"=> rand(5),"colour"=>$colors->[2]},{"val"=>rand(20),"colour"=>$colors->[3]},{"val"=>rand(5),"colour"=>$colors->[4]}]
 ]);  

$y_axis->add_element($e);


%>
<html>
  <head>
    <title>OFC Test Suite - PERL</title>
    <link type="text/css" rel="stylesheet" media="all" href="style.css"/>
  </head>
  <body>
  	<!--#INCLUDE FILE = "list_all_tests.inc"-->
    <h3>StackBar Test</h3>
<%
  $Response->write($g->render_swf({'width'=>600, 'height'=>400}));
  $Response->write('<p>Should have two stackbar series.</p>');
%>
</body>
</html>