class CreateLogItems < ActiveRecord::Migration
  def self.up
    create_table :log_items do |t|
      t.integer :value
      t.integer :value2
      t.integer :schedule_index
      t.integer :paper_id
      t.integer :scheduler_id
      t.integer :group_id
      t.timestamps
    end
  end

  def self.down
    drop_table :log_items
  end
end
