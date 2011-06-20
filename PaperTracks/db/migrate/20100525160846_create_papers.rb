class CreatePapers < ActiveRecord::Migration
  def self.up
    create_table :papers do |t|
      t.string :title
      t.string :url
      t.string :author
      t.string :location
      t.integer :user_id
      t.integer :last_citations
      t.boolean :favorite
      t.string :true_title
      t.datetime :last_update
      t.timestamps
    end
  end

  def self.down
    drop_table :papers
  end
end
