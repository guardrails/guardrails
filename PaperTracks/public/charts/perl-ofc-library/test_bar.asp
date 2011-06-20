<%@ Language="PerlScript"%>
<% 

# For this test you must have an iis webserver with the perlscript dll installed as a language.
# Also you'll need the open-flash-chart.swf file and the open_flash_chart.pm files together with this one
# and swfobject.js, json/json2.js if you use in-line js (default).

use strict; use warnings;
our ($Server, $Request, $Response);
use lib $Server->mappath('.');

use open_flash_chart;

my $g = chart->new();
my $y_axis = $g->get_axis('y_axis');

my $e = $g->get_element('bar');
my $data = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data, rand(20) );
}
$e->set_values($data, 0);
$y_axis->add_element($e);

$e = $g->get_element('bar_filled');
my $data = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data, rand(40) );
}
$e->set_values($data, 0);
$y_axis->add_element($e);  


my $g2 = chart->new();
$y_axis = $g2->get_axis('y_axis');
my $e2 = $g->get_element('bar_3d');
my $data2 = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data2, rand(20) );
}
$e2->set_values($data2, 0);
$y_axis->add_element($e2);

$e2 = $g2->get_element('bar_glass');
my $data2 = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data2, rand(40) );
}
$e2->set_values($data2, 0);
$y_axis->add_element($e2);  

%>
<html>
  <head>
    <title>OFC Test Suite - PERL</title>
    <link type="text/css" rel="stylesheet" media="all" href="style.css"/>
  </head>
  <body>
  	<!--#INCLUDE FILE = "list_all_tests.inc"-->
    <h3>Bar Test</h3>
<%
    $Response->write($g->render_swf({'width'=>600, 'height'=>400}));
    $Response->write('<p>Should have one 2D plain, and one 2D outline bars with height=rnd(40)</p>');
    $Response->write('<br/><hr/>');
    $Response->write($g2->render_swf({'width'=>600, 'height'=>400}));
    $Response->write('<p>Should have one 3D plain and one 3D bar glass with height=rnd(40)</p>');
%>


</body>
</html>