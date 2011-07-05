module ActionView
  module Helpers
    module OpenFlashChartLazyHelper
      def remote_graph(dom_id,options={},html_options={})
        html_options.merge!({:id=>dom_id})
        javascript_tag(swf_object(dom_id,options)).concat(content_tag("div","",html_options))
      end
      def swf_object(dom_id,options={})
        default_options={:width=>300,:height=>150}
        options = default_options.merge(options)
        remote = ""
        remote = ",{'data-file':'#{options[:route]}'}" if options[:route]
        "swfobject.embedSWF('/open-flash-chart.swf','#{dom_id}','#{options[:width]}','#{options[:height]}','9.0.0','expressInstall.swf'#{remote});"
      end
      def inline_graph(graph,options={},html_options={})
        dom_id = "lazy_graph#{Time.now.usec}"
        script = <<-EOS
        function open_flash_chart_data()
        {
            return JSON.stringify(#{dom_id});
        }
        function findSWF(movieName) {
          if (navigator.appName.indexOf("Microsoft")!= -1) {
            return window[movieName];
          } else {
            return document[movieName];
          }
        }
        var #{dom_id} = #{graph.to_graph_json};
        EOS
        content_tag("div","",:id=>"#{dom_id}").concat(javascript_tag(swf_object(dom_id,options)).concat(javascript_tag(script)))
      end
    end
  end
end