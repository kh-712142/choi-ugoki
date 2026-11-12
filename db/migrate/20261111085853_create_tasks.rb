class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: true, foreign_key: { on_delete: :cascade }
      t.string :name, null: false

      t.timestamps null: false
    end
  end
end
