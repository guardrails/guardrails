# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100531202218) do

  create_table "groups", :force => true do |t|
    t.string   "groupname"
    t.string   "description"
    t.string   "profile"
    t.boolean  "admin"
    t.boolean  "approved"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups_users", :id => false, :force => true do |t|
    t.integer "group_id"
    t.integer "user_id"
  end

  create_table "log_items", :force => true do |t|
    t.integer  "value"
    t.integer  "value2"
    t.integer  "schedule_index"
    t.integer  "paper_id"
    t.integer  "scheduler_id"
    t.integer  "group_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "papers", :force => true do |t|
    t.string   "title"
    t.string   "url"
    t.string   "author"
    t.string   "location"
    t.integer  "user_id"
    t.integer  "last_citations"
    t.boolean  "favorite"
    t.string   "true_title"
    t.datetime "last_update"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", :force => true do |t|
    t.string   "permissionname"
    t.integer  "role_id"
    t.boolean  "admin"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions_roles", :id => false, :force => true do |t|
    t.integer "permission_id"
    t.integer "role_id"
  end

  create_table "role_types", :force => true do |t|
    t.string   "typename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.integer  "role_type_id"
    t.integer  "group_id"
    t.string   "rolename"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  create_table "schedulers", :force => true do |t|
    t.integer  "current_index"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "login",                     :limit => 40
    t.string   "name",                      :limit => 100, :default => ""
    t.string   "email",                     :limit => 100
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token",            :limit => 40
    t.datetime "remember_token_expires_at"
    t.string   "profile",                   :limit => 200, :default => ""
  end

  add_index "users", ["login"], :name => "index_users_on_login", :unique => true

end
