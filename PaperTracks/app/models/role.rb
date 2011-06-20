class Role < ActiveRecord::Base
  belongs_to :role_type, :autosave => true
  belongs_to :group
  has_and_belongs_to_many :permissions
  has_and_belongs_to_many :users
end
