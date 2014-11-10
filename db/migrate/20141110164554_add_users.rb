class AddUsers < ActiveRecord::Migration
  def change
  	create_table "users", force: true do |t|
    	t.string   "provider"
    	t.string   "uid"
    	t.string   "name"
    	t.string   "oauth_token"
    	t.datetime "oauth_expires_at"
    	t.datetime "created_at"
    	t.datetime "updated_at"
    	t.string   "avatar"
    	t.string   "email"
    	t.string   "role", default: "unapproved"
  	end
  end
end
