class CreateTaskCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :task_completions do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :task, null: false, foreign_key: { on_delete: :cascade }
      t.date :completed_on, null: false

      t.timestamps null: false
    end

    add_index :task_completions, [ :user_id, :completed_on ]
  end
end
