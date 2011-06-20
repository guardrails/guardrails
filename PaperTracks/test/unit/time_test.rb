require 'test_helper'
require 'performance_test_help'
require 'ruby-prof'
class TimeTest < ActiveSupport::TestCase
  test "truth 3" do 
    get '/'
  end
end
