class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :groupname
      t.string :description
      t.string :profile
      t.boolean :admin
      t.boolean :approved
      t.timestamps
    end
  end

  def self.down
    drop_table :groups
  end
end
