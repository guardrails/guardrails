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
#$g->{'chart_props'}->{'tooltip'} = {'text'=>'#val#'};

my $e = $g->get_element('pie');
$e->set_radius(150);
$e->set_values([ {'value'=>rand(255), 'label'=>'linux-ubuntu'}, {'value'=>rand(255), 'label'=>'windows'}, {'value'=>rand(255), 'label'=>'vax'}, {'value'=>rand(255), 'label'=>'NexT'}, {'value'=>rand(255), 'label'=>'solaris'}]);
$e->set_tip('#val#  #percent#');
$g->add_element($e);
  
%>
<html>
  <head>
    <title>OFC Test Suite - PERL</title>
    <link type="text/css" rel="stylesheet" media="all" href="style.css"/>
  </head>
  <body>
  	<!--#INCLUDE FILE = "list_all_tests.inc"-->
    <h3>Pie Test</h3>
<%
  $Response->write($g->render_swf({'width'=>600, 'height'=>400}));
  $Response->write('<p>Should be a pie with five slices.</p>');
%>
</body>
</html>
