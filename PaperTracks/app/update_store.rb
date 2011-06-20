class UpdateStore < ActiveRecord::Base
  @s = Scheduler.find(1)
  @papers = Paper.all
  @papers.each do |paper|
    @new_log = LogItem.create(:schedule_index => @s.current_index, :value => paper.citations)
    paper.log_items << @new_log
  end
  Group.all.each do |group|
    @gpapers = group.allpapers
    @c_count = 0
    @gpapers.each do |ppr|
      @c_count += ppr.citations
    end
    @new_log = LogItem.create(:schedule_index => @s.current_index, :value => @gpapers.size, :value2 => @c_count)
    group.log_items << @new_log
  end
  @new_log = LogItem.create(:schedule_index => @s.current_index, :value => Time.new.year, :value2 => Time.new.month)
  @s.log_items << @new_log
  @s.current_index = @s.current_index + 1
  @s.save
  puts @s.current_index
end
