class Scheduler < ActiveRecord::Base
  has_many :log_items
  def produce_forced_time(index, timeobj = true)
    @olog = self.log_items[0]
    @oyear = @olog.value
    @omonth = @olog.value2
    @month = @omonth + index
    @year = @oyear + (@month-1)/12
    @month = @month - ((@month-1)/12) * 12
    if timeobj
      return Time.mktime(@year.inspect,@month,1)
    else
      return @year.inspect + "-" + @month.inspect
    end
  end
end
