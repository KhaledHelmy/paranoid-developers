class CreateCodes < ActiveRecord::Migration
  def change
    create_table :codes do |t|
      t.text :code
      t.references :user, index: true, foreign_key: true
      t.string :file_name

      t.timestamps null: false
    end
  end
end
