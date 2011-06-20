class LogItem < ActiveRecord::Base
  belongs_to :paper
  belongs_to :scheduler
  belongs_to :group
end
