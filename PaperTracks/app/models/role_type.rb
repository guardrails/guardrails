class RoleType < ActiveRecord::Base
  has_many :roles, :autosave => true
end
