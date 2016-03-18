class CreateEncryptions < ActiveRecord::Migration
  def change
    create_table :encryptions do |t|
      t.references :code, index: true, foreign_key: true, null: false
      t.references :user, index: true, foreign_key: true, null: false
      t.string :encryption_key, null: false
      t.string :encryption_iv, null: false

      t.timestamps null: false
    end
  end
end
