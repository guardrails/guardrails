# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  def core_index
    render :template => 'home/index', :layout => 'core'
  end

  def controller_check(group, permission)
    if current_user
      if current_user.authen_check(group,permission)
        true
      else
        flash[:notice] = 'You do not have access to that page'
        redirect_to root_path
      end
   else
      access_denied
    end
  end

  def flash_redirect(path = root_path, notice = "You do not have permission to perform that action")
    flash[:notice] = notice
    redirect_to path
  end

  def specific_group?
    if @group_id
      return @group_id != "0"
    end
    @group_id = "0"
    return false
  end
  def value_graph(logs,current_value,func,points,label_interval, title, color_param)
    points = points - 1
    @s = Scheduler.find(1)
    bar_graph = OpenFlashChartLazy::Line.new(title)
    if color_param == "even"
      bar_graph.bg_colour="#ffffcc"
    else
      bar_graph.bg_colour="#ffffff"
    end
    @vals = Array.new
    if logs.size > points
        @sublogs = logs.last(points)
    else
        @sublogs = logs
    end
    if logs.size <= 0
      @start_time = @s.produce_forced_time(@s.current_index)
    else
      @start_time = @s.produce_forced_time(@sublogs[0].schedule_index)
    end
    logs.each do |log|
      @vals = @vals + [[@s.produce_forced_time(log.schedule_index,false), func.call(log)]]
    end
    @vals = @vals + [[@s.produce_forced_time(@s.current_index,false), current_value]]
    first_serie = OpenFlashChartLazy::Serie.new(
                                                @vals,
                                                {:title=>"",:start_date=>@start_time,:items=>@sublogs.size + 1})
    bar_graph.add_serie(first_serie)
    bar_graph.y_axis[:steps] = (bar_graph.y_axis[:max] / 6) + 1
    bar_graph.y_axis[:max] += 1
    @index = 0
    while @index < bar_graph.x_axis[:labels][:labels].size
      if (@index/label_interval == (@index-1)/label_interval)
        bar_graph.x_axis[:labels][:labels][@index] = ""
      end
      @index += 1
   end
    bar_graph.elements[0].colour = "#000000"
    render :text=>bar_graph.to_graph_json
  end

end
