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

$g->{'chart_props'}->{'tooltip'} = {'text'=>'Hollow Tip #val#<br>I See...'};


my $e = $g->get_element('area');
my $data = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data, rand(20) );
}
$e->set_values($data, 0);
$y_axis->add_element($e);

my $f = $g->get_element('area');
$data = [];
for( my $i=0; $i<5; $i++ ) {
	push ( @$data, rand(40) );
}
$f->set_values($data, 0);
$f->set_dot_style({'type'=>'hollow-dot', 'colour'=>'#a44a80', 'dot-size'=>3, 'tip'=>'#val#<br>#x_label#'});

$y_axis->add_element($f);

%>
<html>
  <head>
    <title>OFC Test Suite - PERL</title>
    <link type="text/css" rel="stylesheet" media="all" href="style.css"/>
  </head>
  <body>
  	<!--#INCLUDE FILE = "list_all_tests.inc"-->
    <h3>Area Hollow Test</h3>
<%
  $Response->write($g->render_swf({'width'=>600, 'height'=>400}));
  $Response->write('<p>Should plot 1 plain line with area shaded and one line-dot with area shaded.</p>');
%>
</body>
</html>