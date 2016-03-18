class AddNameAndPublicKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :name, :string, null: false, default: ""
    add_column :users, :public_key, :string, null: false, default: ""
  end
end
