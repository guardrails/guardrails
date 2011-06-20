<%@ Language="PerlScript"%>
<% 

# For this test you must have an iis webserver with the perlscript dll installed as a language.
# Also you'll need the open-flash-chart.swf file and the open_flash_chart.pm files together with this one
#

use strict; 
our ($Server, $Request, $Response);
use lib $Server->mappath('.');
use open_flash_chart;

my $g = chart->new();
my $x = $g->get_axis('x_axis');
$x->set_labels({"labels"=>[]});	#clear out the default labels so scatter can plot the x axis.
my $y_axis = $g->get_axis('y_axis');

my $e = $g->get_element('scatter');
$e->set_values([
  {"x"=>-rand(5), "y"=>-rand(5)},
  {"x"=>-rand(4), "y"=>-rand(4)},
  {"x"=>-rand(2), "y"=>-rand(2), "dot-size"=>20},
  {"x"=>rand(3),  "y"=>rand(3), "dot-size"=>5},
  {"x"=>rand(6),  "y"=>rand(6), "dot-size"=>5},
  {"x"=>rand(10),  "y"=>rand(10), "dot-size"=>15}
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
    <h3>Scatter Test</h3>
<%
  $Response->write($g->render_swf({'width'=>600, 'height'=>400}));
  $Response->write('<p>Should plot six dots of various sizes.</p>');
%>
</body>
</html>