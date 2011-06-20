class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string :permissionname
      t.integer :role_id
      t.boolean :admin
      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end
