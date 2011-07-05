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
my $y_axis = $g->get_axis('y_axis');

my $e = $g->get_element('line');

my $data = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data, rand(20) );
}
$e->set_values($data, 0);
$e->set_dot_style({'type'=>'solid-dot', 'colour'=>'#a44a80', 'dot-size'=>4, 'tip'=>'#val#<br>#x_label#'});
$y_axis->add_element($e);

$e = $g->get_element('line');
my $data = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data, rand(30) );
}
$e->set_values($data, 0);
$e->set_dot_style({'type'=>'hollow-dot', 'colour'=>'#a44a80', 'dot-size'=>3, 'tip'=>'#val#<br>#x_label#'});
$y_axis->add_element($e);


$e = $g->get_element('line');
my $data = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data, rand(40) );
}
$e->set_values($data, 0);
$y_axis->add_element($e);

%>
<html>
  <head>
    <title>OFC Test Suite - PERL</title>
    <link type="text/css" rel="stylesheet" media="all" href="style.css"/>
  </head>
  <body>
<!--#INCLUDE FILE = "list_all_tests.inc"-->
    <h3>Line Test</h3>
<%
  $Response->write($g->render_swf({'width'=>600, 'height'=>400}));
  $Response->write('<p>Should have one plain line, one line_dot, and one line_hollow with height=rnd(40)</p>');
%>
</body>
</html>