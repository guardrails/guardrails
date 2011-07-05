helpers do
  def remote_graph(dom_id,options={},html_options={})
    html_options.merge!({:id=>dom_id})
    javascript_tag(swf_object(dom_id,options)).concat(content_tag("div","",html_options))
  end
  def javascript_tag(content_or_options_with_block = nil, html_options = {})
    content = content_or_options_with_block
    content_tag("script",javascript_cdata_section(content), html_options.merge(:type => "text/javascript"))
  end
  def cdata_section(content)
    "<![CDATA[#{content}]]>"
  end
  def javascript_cdata_section(content) #:nodoc:
    "\n//#{cdata_section("\n#{content}\n//")}\n"
  end
  def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true)
    content = content_or_options_with_block
    content_tag_string(name, content, options, escape)
  end
  def content_tag_string(name, content, options, escape = true)
    tag_options = tag_options(options, escape) if options
    "<#{name}#{tag_options}>#{content}</#{name}>"
  end
  def tag_options(options, escape = true)
    unless options.empty?
      attrs = []
      if escape
        options.each do |key, value|
          next unless value
          key = key.to_s
          value = escape_once(value)
          attrs << %(#{key}="#{value}")
        end
      else
        attrs = options.map { |key, value| %(#{key}="#{value}") }
      end
      " #{attrs.sort * ' '}" unless attrs.empty?
    end
  end
  def escape_once(html)
    html.to_s.gsub(/[\"><]|&(?!([a-zA-Z]+|(#\d+));)/) { |special| ERB::Util::HTML_ESCAPE[special] }
  end
  def swf_object(dom_id,options={})
    default_options={:width=>300,:height=>150}
    options = default_options.merge(options)
    remote = ""
    remote = ",{'data-file':'#{options[:route]}'}" if options[:route]
    "swfobject.embedSWF('/open-flash-chart.swf','#{dom_id}','#{options[:width]}','#{options[:height]}','9.0.0','expressInstall.swf'#{remote});"
  end
end
