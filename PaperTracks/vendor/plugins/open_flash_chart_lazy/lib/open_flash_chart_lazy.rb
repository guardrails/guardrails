require 'mhash'
require 'json'
require 'date'
require File.join(File.dirname(__FILE__),'open_flash_chart_lazy/open_flash_chart_lazy')

# dumb hack to support sinatra
begin 
  ActionView::Base
  require File.join(File.dirname(__FILE__),'open_flash_chart_lazy/open_flash_chart_lazy_helper')
  ActionView::Base.class_eval do
    include ActionView::Helpers::OpenFlashChartLazyHelper
  end
rescue
  require File.join(File.dirname(__FILE__),'open_flash_chart_lazy/open_flash_chart_lazy_sinatra')
  #not rails
end

