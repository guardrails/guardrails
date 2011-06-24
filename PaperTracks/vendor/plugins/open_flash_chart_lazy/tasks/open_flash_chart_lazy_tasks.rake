namespace :open_flash_chart_lazy do
  PLUGIN_ROOT = File.dirname(__FILE__) + '/../'
  
  desc 'Installs required swf in public/ and javascript files to the public/javascripts directory.'
  task :install do
    FileUtils.cp Dir[PLUGIN_ROOT + '/assets/swf/*.swf'], RAILS_ROOT + '/public'
    FileUtils.cp Dir[PLUGIN_ROOT + '/assets/javascripts/*.js'], RAILS_ROOT + '/public/javascripts'
  end
  desc 'Removes the swf and javascripts for the plugin.'
  task :remove do
    FileUtils.rm %{json2.js swfobject.js}.collect { |f| RAILS_ROOT + "/public/javascripts/" + f  }
    FileUtils.rm %{open_flash_chart.swf}.collect { |f| RAILS_ROOT + "/public/" + f  }
  end
end