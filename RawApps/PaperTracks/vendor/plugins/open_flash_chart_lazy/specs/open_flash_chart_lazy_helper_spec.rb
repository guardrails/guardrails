# 
# this was used for Rails helpers specs
#

#require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
#include ActionView::Helpers::OpenFlashChartLazyHelper
#describe ActionView::Helpers::OpenFlashChartLazyHelper do
#  it "should respond to swf_object and return the javascript code with the route" do
#    swf_object("my_graph",{:route=>"/my_route"}).should == "swfobject.embedSWF('/open-flash-chart.swf','my_graph','300','150','9.0.0','expressInstall.swf',{'data-file':'/my_route'});"
#  end
#  it "should respond to swf_object and return the javascript code without the route" do
#    swf_object("my_graph").should == "swfobject.embedSWF('/open-flash-chart.swf','my_graph','300','150','9.0.0','expressInstall.swf');"
#  end
#end