#!/usr/bin/perl

use strict; use warnings;

use FindBin qw($Bin);
use lib "$Bin";

use open_flash_chart;

#NEW CHART DEFINITION
my $chart = chart->new();

#BACKGROUND COLOR. ATTENTION: IT MUST BE SET BEFORE TITLE
#COLORE DI SFONDO. ATTENZIONE: VA SETTATO PRIMA DEL TITOLO
$chart->{'chart_props'} = {'bg_colour' => '#efefef'};

#TITLE CHART
#INSERIMENTO TITOLO
$chart->{'chart_props'}->{'title'} = {'text'=>'Titolo del grafico', 'style'=>'font-size:20px; font-family:Verdana; text-align:center;'};


$chart->{'chart_props'}->{'tooltip'} = {'shadow'=> '1', 'stroke'=> '2', 'colour'=> '#000000', 'background'=>'#ffffff', 'title'=>'font-size: 14px; color: #CC2A43;', 'body'=>'font-size: 12px; font-weight: bold; color: #000000;'};
#"tooltip": { "shadow": false, "stroke": 5, "colour": "#6E604F", "background": "#BDB396", "title": "{font-size: 14px; color: #CC2A43;}", "body": "{font-size: 10px; font-weight: bold; color: #000000;}" } }


#Y_LEGEND CHART
#INSERIMENTO TITOLO ASSE DELLE y
$chart->{'chart_props'}->{'y_legend'} = {'text'=>'y_legend', 'style'=>'font-size:15px; font-family:Verdana; text-align:center;'};

#X_LEGEND_CHART
#INSERIMENTO TITOLO ASSE DELLE X
$chart->{'chart_props'}->{'x_legend'} = {'text'=>'x_legend', 'style'=>'font-size:15px; font-family:Verdana; text-align:center;'};

#X AXIS DEFINITION
#DEFINIZIONE ASSE DELLE X
my $chart_x = $chart->get_axis('x_axis');

#X AXIS LABEL DEFINITION
#DEFINIZIONE ETICHETTE ASSE DELLE X
$chart_x->set_labels( {labels => ["a","b","c","d","e"]} );
#oppure
#$lab = { labels => ["a","b","c","d","e"]};
#$chart_x->set_labels($lab);

#X AXIS PARAMETER DEFINITION. VIA FUNCTION (THIS METHOD IS OVERWRITTEN IF DIRECT METHOD IS USED)
#DEFINIZIONE PARAMETRI ASSE DELLE X. Tramite funzioni (viene sovrascritto se si usa anche il metoro diretto)
#$chart_x->set_stroke(10);
#$chart_x->set_colour( '#000000' );
#$chart_x->set_tick_height(5); # doesn't work
#$chart_x->set_grid_colour( '#A2ACBA' ); # doesn't work
#$chart_x->set_steps( 2 );
#$chart_x->set_grid_colour( '#000000' ); # doesn't work

#X AXIS PARAMETER DEFINITION. VIA DIRECT METHOD
#DEFINIZIONE PARAMETRI ASSE DELLE X. Tramite inserimento diretto
$chart_x->{'props'} =  {
		'labels' => { labels => ["a","b","c","d","e"]},
		'stroke' => undef,
		'tick-length' => undef,
		'colour' => '#000000',
		'offset' => undef,
		'grid-colour' => '#f0f0f0',
		'3d' => undef, #for bar_3d
		'steps' => '1',
		'visible' => undef,
		
#X AXIS RANGE SETTINGS. INSERT 'a'  IF YOU WOULD LIKE TO USE DEDICATED FUNCTION SET_MIN() AND SET_MAX()
#SET DELLA SCALA DELL'ASSE Y. Inserire 'a' per poter usare le funzioni dedicate set_min() e set_max()
		'min' => 'a',
		'max' => 'a'
};

#X AXIS RANGE SETTINGS. NUMBER OF ELEMETS TO RAPRESENT. USE UNDEF FOR AUTOMATIC VALUE
#SET DELLA SCALA DELL'ASSE X. Indica il numero di elementi da rappresentare. usare undef per il calcolo automatico
$chart_x->set_min(undef);
$chart_x->set_max(3);

#Y AXIS DEFINITION
#DEFINIZIONE ASSE DELLE Y
my $chart_y = $chart->get_axis('y_axis');


#TYPE OF CHART FOR THE ELEMENT
#SELEZIONE DEL TIPO DI GRAFICO PER L'ELEMENTO
#my $chart_element = $chart->get_element('pie');
my $chart_element = $chart->get_element('bar_stack');
#my $chart_element = $chart->get_element('bar_glass');


#VALUE SET FOR THE ELEMENT VIA FUNCTION. WITH THIS METHOD THE Y RANGE IS CALCULATED AUTO
#SET DEI VALORI DELL'ELEMENTO TRAMITE LA FUNZIONE. IN QUESTO MODO LA SCALA DELL'ASSE Y E' CALCOLATA AUTOMATICAMENTE
#$chart_element->set_values($values);
#$chart_element->set_values([100,50,20,30,40]);

#$chart_element->set_values([100,{'top'=> 30, 'colour'=> '#000000', 'tip'=> 'Spoon {#val#}<br>
#Title Bar 2<br>
#Override bar 2 tooltip<br>
#Special data point'},20,30,40]); # doesn't work



#SET ELEMENT VALUES FOR BAR_STACK VIA FUNCTION
my $color;
my $color2;
$chart_element->set_values([
	[{'val'=>1,'colour'=>$color=random_color(),'tip'=>'Title <br> value = #val#'},{'val'=>3,'colour'=>$color2=random_color(),'tip'=>'Title2 <br> value = #val#'}],
	[{'val'=>4,'colour'=>$color,'tip'=>'Title <br> value = #val#'},{'val'=>8,'colour'=>$color2,'tip'=>'Title2 <br> value = #val#'}],
	[{'val'=>6,'colour'=>$color,'tip'=>'Title <br> value = #val#'},{'val'=>2,'colour'=>$color2,'tip'=>'Title2 <br> value = #val#'}],
	]);


#MANUAL VALUE SET. RANGE OF THE Y IS NOT AUTO AND HAS TO BE SETTED WITH SET_MAX()
#SET DEI VALORI DELL'ELEMENTO MANUALE. IN QUESTO MODO LA SCALA DELL'ASSE Y NON VIENE CALCOLATA
#$chart_element->{'element_props'}->{'values'} = [4,5,6,56,45];

#SET ELEMENT VALUES FOR BAR_STACK MANUALLY
#$chart_element->{'element_props'}->{'values'} = [
#	[{"val"=>1,"colour"=>random_color(),"text"=>'ciao'},{"val"=>3,"colour"=>random_color()}],
#	[{"val"=>0,"colour"=>random_color()},{"val"=>6,"colour"=>random_color()}],
#	];

#ELEMENT PARAMETERS
#SET PARAMETRI DELL'ELEMENTO
$chart_element->{'element_props'}->{'tip'} = 'Total title <br> total value = #val#'; 
#$chart_element->{'element_props'}->{'tip'} = 'Tooltip title #val# <br> value = #val#'; 
$chart_element->{'element_props'}->{'alpha'} = 0.5; #for bar
$chart_element->{'element_props'}->{'outline-colour'} = random_color(); #for bar_filled
#$chart_element->{'element_props'}->{'text'} = 'element_label';
$chart_element->{'element_props'}->{'text'} = '';
$chart_element->{'element_props'}->{'colour'} = random_color();
$chart_element->{'element_props'}->{'font-size'} = 10;
$chart_element->{'element_props'}->{'width'} = 2; #for line
#$chart_element->{'element_props'}->{'width'} = 2; #for area_hallow
#$chart_element->{'element_props'}->{'fill'} = ''; #for area_hallow
#$chart_element->{'element_props'}->{'halo-size'} = 2; #for area_hallow
#$chart_element->{'element_props'}->{'fill-alpha'} = 0.6; #for area_hallow

#INSERT ELEMENT IN THE CHART
#INSERIMENTO DELL'ELEMENTO NEL GRAFICO
$chart_x->add_element($chart_element);

#PRINT OF THE DATA IN THE JSON FORMAT
#STAMPA DEI DATI NEL FORMATO JSON 
#$chart->render_chart_data();


#HTML CODE
print "Content-type: text/html\n\n";
print '
<html><head>
<title>Open flash chart Test</title>
</head>
<body>
';

#INSERT OF THE CHART IN THE HTML
#INSERIMENTO DEL GRAFICO NELL'HTML
print $chart->render_swf({'width'=>600, 'height'=>400});

print'
<p>
</body>
</html>
';

#print "\n";
