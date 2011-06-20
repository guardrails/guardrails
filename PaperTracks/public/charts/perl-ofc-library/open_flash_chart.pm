use strict; use warnings;

# This class manages all functions of the open flash chart api.
package chart;

my $open_flash_chart_seqno = 0;
my $BOOTSTRAP_COMPLETED = 0;

sub new() {
  # Constructer for the open_flash_chart_api
  # Sets our default variables
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  
  $self->{'open_flash_chart_seqno'} = $open_flash_chart_seqno++;
  $self->{'data_load_type'} = 'inline_js'; # or 'url_callback'  not sure if we still need both
  
  $self->{'chart_props'} = {

    "title"=>{
      "text"=>"Default Chart Title",
      "style"=>"{font-size:20px; font-family:Verdana; text-align:center;}"
    },
    "x_legend"=>{
      "text" => "1983 to 2008",
      "style"=> "{font-size: 20px; color: #778877;}"
    },
  };

	#setup default axis
  my $x = $self->get_axis('x_axis');
  $x->set_labels({"labels"=>["January","February","March","April","May"]});
  my $y = $self->get_axis('y_axis');

  $self->{'elements'} = [];
  
  return $self;
}

sub bootstrap_completed {
	my ($self, $value) = @_;
	$BOOTSTRAP_COMPLETED = $value if defined($value);
	return $BOOTSTRAP_COMPLETED;
}

sub get_axis {
	my ($self, $axis_name) = @_;
	if ( !defined($self->{'axis'}->{$axis_name}) ) {
		$self->{'axis'}->{$axis_name} = axis->new($axis_name);
	}
	return $self->{'axis'}->{$axis_name}
}

sub set_axis() {
  my ($self, $axis) = @_;
  $self->{'axis'}->{$axis->{'name'}} = $axis;
}

# elements are the data series items, usually containing values to plot
sub get_element() {
  my ($self, $element_name) = @_;
  
  my $e=undef;
  eval("\$e = ${element_name}->new();");
  if ( defined($e) ) {
    return $e;
  } 
}

# Should be not used for single value elements
# Your axis min/max will not be set
sub add_element() {
  my ($self, $element) = @_;
  push(@{$self->{'elements'}}, $element);
}


sub render_chart_data() {
  my ($self) = @_;

  my $tmp = '';

  $tmp .= "{";
  $tmp .= main::to_json($self->{'chart_props'});

	#render axis data
  for ( keys %{$self->{'axis'}} ) {
    $tmp .= $self->{'axis'}->{$_}->to_json();
    
    for my $element ( @{$self->{'axis'}->{$_}->{'elements'}} ) {
    	#$main::Response->write($element);
    	$self->add_element($element);
    }
  }  

  if ( @{$self->{'elements'}} > 0 ) {
    $tmp .= "\n".'"elements" : [';
    for my $s ( @{$self->{'elements'}} ) {
    	#$main::Response->write($s);
      $tmp .= $s->to_json() . ',';  
    }  
    $tmp =~ s/,$//g;
    $tmp .= ']';
  }
  $tmp =~ s/,$//g;
  $tmp .= "\n}";

  return $tmp;
}

#
#
#
sub render_swf {
	my ($self, $props) = @_;
  #my ($self, $width, $height, $data) = @_;
 
	$props->{'height'} = '300px' if !defined($props->{'height'});
	$props->{'width'} = '400px' if !defined($props->{'width'});
	$props->{'data'} = '' if !defined($props->{'data'});
	$props->{'class'} = 'ofc-chart' if !defined($props->{'class'});
	
  my $open_flash_chart_seqno = $self->{'open_flash_chart_seqno'};

  my $html = '';
  if ( $self->{'data_load_type'} eq 'inline_js' ) {
  	my $data = $self->render_chart_data();
    if ($BOOTSTRAP_COMPLETED == 0 ) {
      $html .= '<script type="text/javascript" src="jquery-1.2.6.min.js" ></script>';
    	$html .= '<script type="text/javascript" src="json/json2.js"></script>';
      $html .= '<script type="text/javascript" src="swfobject.js"></script>';
      $html .= qq^
        <script type="text/javascript">
          OFC = {};
          OFC.jquery = {
              name: "jQuery",
              version: function(src) { return \$('#'+ src)[0].get_version() },
              rasterize: function (src, dst) { \$('#'+ dst).replaceWith(OFC.jquery.image(src)) },
              image: function(src) { return "<img src='data:image/png;base64," + \$('#'+src)[0].get_img_binary() + "' />"},
              popup: function(src) {
                  var img_win = window.open('', 'Charts: Export as Image')
                  with(img_win.document) {
                      write('<html><head><title>Charts: Export as Image<\/title><\/head><body>' + OFC.jquery.image(src) + '<\/body><\/html>') }
                      close();
               }
          }
          // Using an object as namespaces is JS Best Practice. I like the Control.XXX style.
          //if (!Control) {var Control = {}}
          //if (typeof(Control == "undefined")) {var Control = {}}
          if (typeof(Control == "undefined")) {var Control = {OFC: OFC.jquery}}
           
           
          // By default, right-clicking on OFC and choosing "save image locally" calls this function.
          // You are free to change the code in OFC and call my wrapper (Control.OFC.your_favorite_save_method)
          // function save_image() { alert(1); Control.OFC.popup('my_chart') }
          function save_image() { OFC.jquery.popup('ofc_div_1') }
          function moo() { alert(99); };
        </script>          
      ^;
      $BOOTSTRAP_COMPLETED = 1;
    }
    $html .= qq^
      <script type="text/javascript">
        swfobject.embedSWF("open-flash-chart.swf", "ofc_div_$open_flash_chart_seqno", "$props->{'width'}", "$props->{'height'}", "9.0.0", "expressInstall.swf", {"get-data":"get_data_$open_flash_chart_seqno","loading":"loading..."} );
        function get_data_$open_flash_chart_seqno() {
          return JSON.stringify(data_$open_flash_chart_seqno);
        }
        var data_$open_flash_chart_seqno = $data;
      </script>
      <div id="ofc_div_$open_flash_chart_seqno" class="$props->{'class'}"></div>
      ^;
  } else {
    $html .= qq^
    <object
      classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"
      codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0"
      width="$props->{'width'}"
      height="$props->{'height'}"
      id="ofc_div_$open_flash_chart_seqno"
      align="middle">
    <param name="allowScriptAccess" value="sameDomain" />
    <param name="movie" value="open-flash-chart.swf?width=$props->{'width'}&height=$props->{'height'}&data=$props->{'data'}"/>
    <param name="quality" value="high" />
    <param name="bgcolor" value="#FFFFFF" />
    <embed
      src="open-flash-chart.swf?width=$props->{'width'}&height=$props->{'height'}&data=$props->{'data'}"
      quality="high"
      bgcolor="#FFFFFF"
      width="$props->{'width'}"
      height="$props->{'height'}"
      name="open-flash-chart"
      align="middle"
      allowScriptAccess="sameDomain"
      type="application/x-shockwave-flash"
      pluginspage="http://www.macromedia.com/go/getflashplayer"
    />
    </object>
    ^;
  }  	
  	
  return $html;
}












#Not Yet Supported
#"hbar",



#############################
sub _____ELEMENT_OBJECTS_____(){}
#############################
package element;
use Carp qw(cluck);

our $AUTOLOAD;
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};

	$self->{'min_value'} = undef;
	$self->{'max_value'} = undef;
	
  $self->{'element_props'} =  {
    'type'      => '',
    'values'    => [1.5,1.69,1.88,2.06,2.21],
  };
  return bless $self, $class;
}

sub set_values {
  my ($self, $values_arg, $min, $max) = @_;
  
  $self->{'element_props'}->{'values'} = $values_arg if defined($values_arg);
  $self->set_min_max($min, $max);
}

sub set_min_max {
  my ($self, $min, $max) = @_;

  $self->{'max_value'} = $max if defined($max);
  $self->{'min_value'} = $min if defined($min);

  for ( @{$self->{'element_props'}->{'values'}} ) {
    if ( ref($_) eq 'HASH' || ref($_) eq 'ARRAY' ) {
    	#multi value/axis chart
      return undef;
    }
    
    #standard single value chart, could be y, y-right, etc.
    if ( !defined($max) ) {
	    $self->{'max_value'} = $_ if ( !defined($self->{'max_value'}) || $_ > $self->{'max_value'} );
	  }
		if ( !defined($min) ) {
			$self->{'min_value'} = $_ if ( !defined($self->{'min_value'}) || $_ < $self->{'min_value'} );	  }
  	}

	return 1;
}

sub to_json() {
  my ($self) = @_;
  my $json = main::to_json($self->{'element_props'});
  $json =~ s/,$//g;
  return '{' . $json . '}';
}
sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or warn "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion
	
	if ( $name eq 'values' ) {
	  $self->{'element_props'}->{'values'} = [];
	  cluck "You need to call set_values() instead of plain values().";
	  return undef;
	}
	
	$name =~ s/^set_//; # strip set_
	$name =~ s/^get_//; # strip get_
	$name =~ s/_/-/gi;

	unless (exists $self->{'element_props'}->{$name} ) {
	  cluck "'$name' is not a valid property in class $type";
	  return undef;
	}

	if (@_) {
	  return $self->{'element_props'}->{"$name"} = shift;
	} else {
    return $self->{'element_props'}->{"$name"};
	}
}
sub DESTROY {  }


package bar_and_line_base;
our @ISA = qw(element);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'colour'} = main::random_color();
  $self->{'element_props'}->{'text'} = 'text';
  $self->{'element_props'}->{'font-size'} = 10;
  $self->{'element_props'}->{'axis'} = undef;

  return $self;
}





#
#
# LINE TYPES
#
#
package line;
our @ISA = qw(bar_and_line_base);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  $self->{'element_props'}->{'width'} = 2;
  $self->{'element_props'}->{'dot-style'} = {}; #{'type'=>'solid-dot', 'colour'=>'#a44a80', 'dot-size'=>6, 'tip'=>'#val#<br>#x_label#'};
  return $self;
}

package area;
our @ISA = qw(bar_and_line_base);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  $self->{'element_props'}->{'width'} = 2;
  $self->{'element_props'}->{'fill'} = '';
  $self->{'element_props'}->{'text'} = '';
  $self->{'element_props'}->{'dot-style'} = {};
  $self->{'element_props'}->{'halo-size'} = 2;
  $self->{'element_props'}->{'fill-alpha'} = 0.6;
  return $self;
}


#
#
# BAR TYPES
#
#
package bar;
our @ISA = qw(bar_and_line_base);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  $self->{'element_props'}->{'alpha'} = 0.5;
  return $self;
}

package bar_3d;
our @ISA = qw(bar);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  return $self;
}

package bar_fade;
our @ISA = qw(bar);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  return $self;
}

package bar_glass;
our @ISA = qw(bar);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  return $self;
}

package bar_sketch;
our @ISA = qw(bar);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  return $self;
}

package bar_filled;
our @ISA = qw(bar);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  $self->{'element_props'}->{'outline-colour'} = main::random_color();
  return $self;
}

package bar_stack;
our @ISA = qw(bar);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  $self->{'element_props'}->{'text'} = __PACKAGE__ . ' ' . $self->{'element_props'}->{'text'};
  $self->{'element_props'}->{'values'} = [
                    [{"val"=>1},{"val"=>3}],
                    [{"val"=>1},{"val"=>1},{"val"=>2.5}],
                    [{"val"=>5},{"val"=>5},{"val"=>2},{"val"=>2},{"val"=>2,"colour"=>main::random_color()},{"val"=>2},{"val"=>2}]
                   ];
  
  return $self;
}

#stackbar must override set_min_max() because of nested value list
sub set_min_max {
  my ($self, $min, $max) = @_;

	my $max_bar_val;
  for my $v ( @{$self->{'element_props'}->{'values'}} ) {
  	#each bar
  	my $this_bar_val;
    if ( ref($v) eq 'ARRAY' ) {
    	#multi value/axis chart
      for ( @$v ) {
      	#each bar piece
        next if !defined($_->{'val'});
				
				if ( !defined($this_bar_val) ) {
					$this_bar_val = $_->{'val'};
				} else {
					$this_bar_val += $_->{'val'};
				}
      }
    }
  	$max_bar_val = $this_bar_val if ( !defined($max_bar_val) || $max_bar_val < $this_bar_val );
  }

  $self->{'max_value'} = $max if defined($max);
  $self->{'min_value'} = $min if defined($min);
  if ( !defined($max) ) {
    $self->{'max_value'} = $max_bar_val;
  }
	if ( !defined($min) ) {
    $self->{'min_value'} = 0;
  }
  
	return 1;
}


package pie;
our @ISA = qw(element);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  $self->{'element_props'}->{'alpha'} = 0.5;
  $self->{'element_props'}->{'colours'} = [main::random_color(), main::random_color(), main::random_color(), main::random_color(), main::random_color()];
  $self->{'element_props'}->{'border'} = 2;
  $self->{'element_props'}->{'animate'} = 1;
  $self->{'element_props'}->{'start-angle'} = 0;
  $self->{'element_props'}->{'radius'} = 200;
  $self->{'element_props'}->{'tip'} = '#val#';
  $self->{'element_props'}->{'label-colour'} = '#000';
  $self->{'element_props'}->{'values'} = [ {'value'=>rand(255), 'label'=>'linux'}, {'value'=>rand(255), 'label'=>'windows'}, {'value'=>rand(255), 'label'=>'vax'}, {'value'=>rand(255), 'label'=>'NexT'}, {'value'=>rand(255), 'label'=>'solaris'}];

  return $self;
}
sub set_pie_values() {
  my ($self, $values, $labels, $links ) = @_;
  
  $self->{'element_props'}->{'values'} = [];

  my @l_values = @$values if defined($values) || ();
  my @l_labels = @$labels if defined($labels) || ();
  my @l_links = @$links if defined($links) || ();
  
  while ( @l_labels < @l_values ) {
 		push(@l_labels, '');
  }
  while ( @l_links < @l_values ) {
 		push(@l_links, '');
  }

  my $total=0;
  for my $v ( @l_values ) {
    $total=$total + $v;
  }
  if ( $total == 0 ) {
  	return undef;
  }
  
  my $pie_total = 0;
  my $biggest_pie_slice = 0;
  my $too_small_value = 0;
  my $too_small_label = '';
  for ( my $i=0; $i < @l_values; $i++) {
    $l_values[$i] = sprintf("%.1f", ($l_values[$i] / $total) * 100.0);
    # you can't have a zero pie slice
    if ( $l_values[$i] == 0.0 ) {
    	splice(@l_values, $i, 1);
    	splice(@l_labels, $i, 1);
    	splice(@l_links, $i, 1);
    	$i--;
    	next;
    } elsif ($l_values[$i] < 3.0) {
    	$pie_total += $l_values[$i];
    	$too_small_value = $too_small_value + $l_values[$i];
   		$too_small_label = $l_labels[$i] . '/' . $too_small_label;
    	splice(@l_values, $i, 1);
    	splice(@l_labels, $i, 1);
    	splice(@l_links, $i, 1);
    	$i--;
    	next;
    }
    
    $pie_total += $l_values[$i];
    if ( $l_values[$i] > $l_values[$biggest_pie_slice] ) {
      $biggest_pie_slice = $i;
    }
  }
  
  #adjust for rounding errors, and fill to 100% on biggest pie slice
  $l_values[$biggest_pie_slice] += (100.0 - $pie_total);

	#get rid of the tailing / from the too small label
	$too_small_label =~ s/\/$//;
	if (length($too_small_label) > 20 ) {
		$too_small_label = substr($too_small_label,0,25) . "...";
	}

	if ( $too_small_value > 0 ) {
		push(@l_values, $too_small_value);
		$too_small_label =~ s/ $//;
		push(@l_labels, $too_small_label);
		push(@l_links,'');
	}

  #$self->{pie_values} = join(',',@l_values);
  #$self->{pie_labels} = join(',',@l_labels);
  #$self->{pie_links}  = join(',',@l_links);

	for ( my $i=0; $i < @l_values; $i++ ) {
	#  push( @$plist, {'value'=>$s->{'values'}->[$i], 'label'=>$self->{'x_ticks'}->[$i], 'font-size'=>12, } );
	  push(@{$self->{'element_props'}->{'values'}}, {'value'=>$l_values[$i], 'label'=>$l_labels[$i]});

	}
}



package scatter;
our @ISA = qw(element);
sub new() {
  my ($proto) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  bless $self, $class;
  $self = $self->SUPER::new();
  $self->{'element_props'}->{'type'} = __PACKAGE__;
  $self->{'element_props'}->{'values'} = [
    {"x"=>-5,  "y"=>-5 },
    {"x"=>0,   "y"=>0  },
    {"x"=>5,   "y"=>5,  "dot-size"=>20},
    {"x"=>5,   "y"=>-5, "dot-size"=>5},
    {"x"=>-5,  "y"=>5,  "dot-size"=>5},
    {"x"=>0.5, "y"=>1,  "dot-size"=>15}
  ];
  $self->{"element_props"}->{"dot-style"} = {"type"=>"solid-dot"};

  return $self;
}
sub set_min_max {
  my ($self, $min, $max) = @_;

	my $max_calc;
	my $min_calc;
  for ( @{$self->{'element_props'}->{'values'}} ) {
    $max_calc = $_->{'y'} if !defined($max_calc);
    if ( $_->{'y'} > $max_calc ) {
      $max_calc = $_->{'y'};
    }
    $min_calc = $_->{'y'} if !defined($min_calc);
    if ( $_->{'y'} < $min_calc ) {
      $min_calc = $_->{'y'};
    }
  }

  $self->{'max_value'} = $max if defined($max);
  $self->{'min_value'} = $min if defined($min);
  if ( !defined($max) ) {
    $self->{'max_value'} = $max_calc;
  }
	if ( !defined($min) ) {
    $self->{'min_value'} = $min_calc;
  }
  
	return 1;


}

#############################
sub _____AXIS_OBJECT_____(){}
#############################
package axis;
use Carp qw(cluck);

our $AUTOLOAD;
our $defaults = {
  	'labels' =>       undef,
		'stroke' =>				undef,
		'tick-length' =>	undef,
		'colour' =>				undef,
		'offset' =>				undef,
		'grid-colour' =>	undef,
		'3d' =>						undef,
		'steps' =>				undef,
		'visible' =>			undef,
		'min' =>					undef,
		'max' =>					undef,
};

sub new() {
  my ($proto, $name) = @_;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{'name'} = $name; # x_axis | y_axis | y_axis_right
  $self->{'elements'} = [];

	#props are rendered into json
  %{$self->{'props'}} =  %$defaults;
  
  return bless $self, $class;
}

sub add_element() {
  my ($self, $element) = @_;
	
  push(@{$self->{'elements'}}, $element);
 	$self->set_min_max();
}

sub set_min_max {
  my ($self) = @_;

  for my $e ( @{$self->{'elements'}} ) {
    $self->{'props'}->{'max'} = $e->{'max_value'} if ( !defined($self->{'props'}->{'max'}) || $self->{'props'}->{'max'} < $e->{'max_value'}  );
    $self->{'props'}->{'min'} = $e->{'min_value'} if ( !defined($self->{'props'}->{'min'}) || $self->{'props'}->{'min'} > $e->{'min_value'}  );
  }
  
  $self->{'props'}->{'max'} = main::smooth_max($self->{'props'}->{'max'});
  $self->{'props'}->{'steps'} = $self->{'props'}->{'max'} / 10;
  
	return 1;
}

sub to_json() {
  my ($self) = @_;
  my $json = main::to_json($self->{'props'}, $self->{'name'}, __PACKAGE__);
  #$json =~ s/,$//g;
  return $json;
}
sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) or warn "$self is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion
	$name =~ s/^set_//; # strip set_
	$name =~ s/^get_//; # strip get_

	unless (exists $self->{'props'}->{$name} ) {
	  cluck "'$name' is not a valid property in class $type";
	  return undef;
	}

	if (@_) {
	  return $self->{'props'}->{"$name"} = shift;
	} else {
    return $self->{'props'}->{"$name"};
	}
}
sub DESTROY {  }










#
#
# GENERAL HELPERS
#
#
package main;
sub to_json {
  my ($data_structure, $name) = @_;

  my $tmp='';
  
  if ( defined($name) && $name ne '' ) {
  	$name =~ s/\"/\'/gi;
    $tmp.= "\n\"$name\" : ";
  }
  
  if ( ref $data_structure eq 'ARRAY' ) {
    $tmp.= "[";
    for (@$data_structure) {
      $tmp.= to_json($_,'');
    }
    $tmp =~ s/,$//g;
    $tmp.= "]";
  } elsif ( ref $data_structure eq 'HASH' ) {
    $tmp.= "{" if defined($name);
    for (keys %{$data_structure}) {
      if ( defined($data_structure->{$_}) ) {
        $tmp.= to_json($data_structure->{$_}, $_ || '');
      }
    }
    $tmp =~ s/,$//g;
    $tmp.= "}" if defined($name);
  
  } else {
  	
  	if ( !defined($data_structure) ) {
  		return;
  	}
  	
    if ( $data_structure =~ /^-{0,1}[\d.]+$/ || $data_structure eq 'null') {
      #number
      $tmp.= $data_structure;
    } else {
      #not number
      $data_structure =~ s/\"/\'/gi;
      $tmp.= "\"$data_structure\"";
    }
  } 
  
  return $tmp.',';
}

sub get_random_colors {
	my $how_many = shift;
	my $ret = [];
	for ( my $i = 0; $i < $how_many; $i++ ) {
		push(@$ret,random_color());
	}
	return $ret;
}

sub random_color {
  my @hex;
  for (my $i = 0; $i < 64; $i++) {
    my ($rand,$x);
    for ($x = 0; $x < 3; $x++) {
      $rand = rand(255);
      $hex[$x] = sprintf ("%x", $rand);
      if ($rand < 9) {
        $hex[$x] = "0" . $hex[$x];
      }
      if ($rand > 9 && $rand < 16) {
        $hex[$x] = "0" . $hex[$x];
      }
    }
  }
  return "\#" . $hex[0] . $hex[1] . $hex[2];
}

# URL-encode string
sub url_escape {
    my($toencode) = @_;
    $toencode=~s/([^a-zA-Z0-9_\-. ])/uc sprintf("%%%02x",ord($1))/eg;
    $toencode =~ tr/ /+/;    # spaces become pluses
    return $toencode;
}


# round the number up a bit to a nice round number
# also changes number to an int
sub smoother {
	my $number = shift;
	my $min_max = shift;
	my $n = $number;
	
	#$n = $n + $n % 10;
	#return $n;
	
	if ( $min_max eq 'max' ) {
		$n = int($n + 0.99 * ($n <=> 0));
	} else {
		$n = int($n - 0.99 * ($n <=> 0));
	}
	
	if ( $n <= 1 ) { $n = 1 }
  elsif ( $n < 10 ) { $n = $n }
  elsif ( $n < 30 ) { $n = $n + (-$n % 5) }
 	elsif ( $n < 100 ) { $n = $n + (-$n % 10) }
 	elsif ( $n < 500 ) { $n = $n + (-$n % 50) }
 	elsif ( $n < 1000 ) { $n = $n + (-$n % 100) }
 	elsif ( $n < 10000 ) { $n = $n + (-$n % 200) }
 	else { $n = $n + (-$n % 500) }
  return int($n);
}
sub smooth_max {
	my $number = shift;
	return smoother($number, 'max');
}
sub smooth_min {
	my $number = shift;
	return smoother($number, 'min');
}

1;
