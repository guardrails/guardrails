require 'spec'
require 'spec/interop/test'
require 'sinatra'
require 'sinatra/test/methods'
require File.expand_path(File.dirname(__FILE__) + "/../lib/open_flash_chart_lazy")

include Sinatra::Test::Methods
 
Sinatra::Application.default_options.merge!(
  :env => :test,
  :run => false,
  :raise_errors => true,
  :logging => false
)
 
Sinatra.application.options = nil

describe OpenFlashChartLazy::Graph do
  before(:each) do
    @stats = OpenFlashChartLazy::Graph.new("Titulo del grafico")
  end
  it "should create a series hash" do
    @stats.series.should be_a_kind_of(Array)
    @stats.series.should be_empty
  end
  it "should respond to title and include the text" do
    @stats.title.should be_a_kind_of(Mhash)
    @stats.title[:text].should == "Titulo del grafico"
  end
  it "should know the x axis" do
    @stats.x_axis.should be_a_kind_of(Mhash)
  end
end
describe OpenFlashChartLazy::Pie do
  describe "creating a new Pie" do
    before(:each) do
      @stats = OpenFlashChartLazy::Pie.new("Titulo del grafico")
    end
    it "should create a series hash" do
      @stats.series.should be_a_kind_of(Array)
      @stats.series.should be_empty
    end
    it "should respond to title and include the text" do
      @stats.title.should be_a_kind_of(Mhash)
      @stats.title[:text].should == "Titulo del grafico"
    end
  end
  describe "adding a serie" do
    before(:each) do
      @stats = OpenFlashChartLazy::Pie.new("2008")
      @data = [["TV",1000],["Internet",2343],["Post",233],[nil,43]]
      @serie = OpenFlashChartLazy::Serie.new(@data,{:title=>"Ventas"})
      @stats.add_serie(@serie)
    end
    it "should add a new hash to series hash with the label as key" do
      @stats.series.length.should == 1
    end
    it "should add an element to elements array for each serie" do
      @stats.elements.length.should == 1
    end
    it "should be a hash added as element" do
      @stats.elements[0].should be_a_kind_of(Hash)
    end
    it "should add the options to the elements hash" do
      @stats.elements[0][:type].should == "pie"
      @stats.elements[0][:colours].should be_a_kind_of(Array)
      @stats.elements[0][:colours].length == 4
      @stats.elements[0][:start_angle].should == 35
      @stats.elements[0][:animate].should == true
      @stats.elements[0][:border].should == 2
      @stats.elements[0][:alpha].should == 0.6
      
    end
    it "should have the x_axis == null" do
      @stats.x_axis.should == "null"
    end
    it "should add the title to the element hash" do
      @stats.elements[0][:text].should == "Ventas"
    end
    it "should fill the values and the annotations if present of the with series data" do
      @stats.elements[0][:values].length.should == 4
      @stats.elements[0][:values][0].value.should == 1000
      @stats.elements[0][:values][0].text.should == "TV"
      @stats.elements[0][:values][1].value.should == 2343
      @stats.elements[0][:values][1].text.should == "Internet"
      @stats.elements[0][:values][2].value.should == 233
      @stats.elements[0][:values][3].text.should == ""
      
    end
  end
end

#{ "title": { "text": "Sat Jul 12 2008" }, "elements": [ { "type": "bar", "values": [ 9, 8, 7, 6, 5, 4, 3, 2, 1 ] } ] }
describe OpenFlashChartLazy::Bar do
  describe "creating a bar chart" do
    before(:each) do
      @stats = OpenFlashChartLazy::Bar.new("2008")
      @data = [["TV",1000],["Internet",2343],["Post",233],[nil,43]]
      @serie = OpenFlashChartLazy::Serie.new(@data,{:title=>"Ventas"})
      @stats.add_serie(@serie)
    end
    it "should add a new hash to series hash with the label as key" do
      @stats.series.length.should == 1
    end
    it "should add an element to elements array for each serie" do
      @stats.elements.length.should == 1
    end
    it "should be a hash added as element" do
      @stats.elements[0].should be_a_kind_of(Hash)
    end
    it "should add the options to the elements hash" do
      @stats.elements[0][:type].should == "bar"
    end
    it "should add the title to the element hash" do
      @stats.elements[0][:text].should == "Ventas"
    end
    it "should fill the values if present" do
      @stats.elements[0][:values].length.should == 4
      @stats.elements[0][:values][0].should == 1000
      @stats.elements[0][:values][1].should == 2343
      @stats.elements[0][:values][2].should == 233
      @stats.elements[0][:values][3].should == 43
    end

  end
end


describe OpenFlashChartLazy::Line do
  describe "adding a serie" do
    before(:each) do
      @start =Time.mktime(2007,7,2)
      @stats = OpenFlashChartLazy::Line.new(@start)
      @data = [["2007-05",23],["2008-2"],["2009-10"],["2007-12",1000],["2007-11",500]]
      @serie = OpenFlashChartLazy::Serie.new(@data,{:title=>"Este tiene time",:start_date=>@start,:items=>12})
      @stats.add_serie(@serie,{:type=>"line_dot",:width=>4,:dot_size=>5})
    end
    it "should add a new hash to series hash with the label as key" do
      @stats.series.length.should == 1
    end
    it "should add an element to elements array for each serie" do
      @stats.elements.length.should == 1
    end
    it "should be a hash added as element" do
      @stats.elements[0].should be_a_kind_of(Mhash)
    end
    it "should add the options to the elements hash" do
      @stats.elements[0][:type].should == "line_dot"
      @stats.elements[0][:width].should == 4
      @stats.elements[0][:dot_size].should == 5
    end
    it "should add the title to the element hash" do
      @stats.elements[0][:text].should == "Este tiene time"
    end
    it "should fill the values of the with series data" do
      @stats.elements[0][:values].length.should == 12
      @stats.elements[0][:values][0].should == 0
      @stats.elements[0][:values][4].should == 500
      @stats.elements[0][:values][5].should == 1000
    end
    it "should add the colour from the LINE_COLORS to element" do
      @stats.elements[0][:colour].should == OpenFlashChartLazy::Line::LINE_COLORS[0]
      
    end
  end
  describe "rendering a bargraph" do
    before(:each) do
      usuarios = [["2007-7",20],["2007-2",30]]
      @serie = OpenFlashChartLazy::Serie.new(usuarios,{:title=>"usuarios",:start_date=>@start,:items=>2})
      @start =Time.mktime(2007,7,2)
      @stats = OpenFlashChartLazy::Line.new("graf")
      @stats.add_serie(@serie)
    end
    it "should not include periods start_date months and series in the json result" do
      #@stats.to_graph_json.should == %< >
    end
  end
end

describe OpenFlashChartLazy::Serie do
  describe "creating with time" do
    before(:each) do
      @start =Time.mktime(2006,1,4)
      @data = [["2006-1",100],["2006-2",300],["2006-3",300]]
      @serie = OpenFlashChartLazy::Serie.new(@data,{:title=>"Este tiene time",:start_date=>@start,:items=>4})
    end
    it "should know the items" do
      @serie.items.should == 4
    end
    it "should have a values array with a lenght of items filled with YYYY-MM" do
      @serie.keys.should include("2006-01")
      @serie.keys.should include("2006-04")
      @serie.keys.should_not include("2006-05")
      @serie.keys.should_not include("2006-00")
      @serie.keys.should_not include("2005-12")
    end
    it "should generate the label according to the formatter" do
      @serie.labels[0].should == "Jan 2006"
      @serie.labels[3].should == "Apr 2006"
    end
    it "should match the data pairs with generated keys and assing the values" do
      @serie.values[0].should == 100
      @serie.values[1].should == 300
      @serie.values[2].should == 300
      @serie.values[3].should == 0
    end
    it "should know the title" do
      @serie.title.should == "Este tiene time"
    end
    it "should have items length" do
      @serie.values.length.should == 4
    end
    it "should calculate the min and max of the serie" do
      @serie.max.should == 300
      @serie.min.should == 0
    end
    it "should calculate the step to include at least 5 y values" do
      @serie.steps.should == (@serie.max - @serie.min) / 5
    end
  end
  describe "creating with array" do
    before(:each) do
      @data = [40,20,100,123]
      @serie = OpenFlashChartLazy::Serie.new(@data,{:title=>"Este tiene es array",:items=>10})
    end
    it "should know the items" do
      @serie.items.should == 10
    end
    it "should have items length" do
      @serie.values.length.should == 10
    end
  end
  describe "creating with a hash" do
    before(:each) do
      @data = {:juan=>40,:fernando=>20,:pedro=>100,:marcelo=>123}
      @serie = OpenFlashChartLazy::Serie.new(@data,{:title=>"Este tiene es hash",:items=>12})
    end
    it "should know the items and will be the length of the hash" do
      @serie.items.should == 4
    end
    it "should add the same keys of the hash to keys" do
      @serie.keys.should == @data.keys
    end
  end
end