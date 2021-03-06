# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def tr
    "<tr class='" + cycle('odd','even') + "'>"
  end
  def table_w_sortheader(headers, target, options)
    @headers_row = ""
    headers.each do |hdr|
      @symbols = hdr.split("_")
      if @symbols.size > 1
        if (@symbols[0] == "c")
          @headers_row = @headers_row  + "<th style='padding: 4px;'><center>" + @symbols[1] + "</center></th>"
        else
          @headers_row = @headers_row  + "<th style='text-align:right; padding: 4px;'>" + @symbols[1] + "</th>"
        end
      else
        @headers_row = @headers_row + "<th style='padding: 4px;'>&nbsp;&nbsp;" + hdr + "</th>"
      end
    end
    @option_str = ""
    options.each do |option|
      if params[:sort] == option[0]
        @option_str += ("<option value='" + option[0] + "' SELECTED >" + option[1] + "</option>")
      else
        @option_str += ("<option value='" + option[0] + "'>" + option[1] + "</option>")
      end
    end
    @headers_row = @headers_row + "<th style='text-align:right; padding-right: 5px;' colspan=10>Sort: &nbsp;<form name='form' style='display:inline'><select name='sort' onchange='location=\"" + target + "?sort=\" + form.sort.options[form.sort.selectedIndex].value'>" + @option_str  + "</select></th>"
    return "<table><tr class='tableheader'>" + @headers_row + "</tr>"
  end
  def table_w_header(headers)
    @headers_row = ""
    headers.each do |hdr|
      @symbols = hdr.split("_")
      if @symbols.size > 1
        if (@symbols[0] == "c")
          @headers_row = @headers_row  + "<th style='padding: 4px;'><center>" + @symbols[1] + "</center></th>"
        else
          @headers_row = @headers_row  + "<th style='text-align:right; padding: 4px;'>" + @symbols[1] + "</th>"
        end
      else
        @headers_row = @headers_row + "<th style='padding: 4px;'>&nbsp;&nbsp;" + hdr + "</th>"
      end
    end
    @headers_row = @headers_row + "<th colspan=10></th>"
    return "<table><tr class='tableheader'>" + @headers_row + "</tr>"
  end
  def icon_link(icon, text)
    return "#{image_tag(icon, :size => "16x16", :class => "icon")}#{text}"
  end
  def up_down_pic(paper)
    if paper.log_items.size > 0
     @last_log = paper.log_items[paper.log_items.size-1]
     if (paper.citations == @last_log.value)
       return ""
     else
       if (paper.citations < @last_log.value)
         return image_tag("down.png",:class => "arrow")
       else
         return image_tag("up.png", :class=>"arrow")
       end
     end
    else
      return ""
    end
  end


end
