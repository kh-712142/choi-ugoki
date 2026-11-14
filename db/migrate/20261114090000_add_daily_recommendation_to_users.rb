class AddDailyRecommendationToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users,
                  :daily_recommendation_task,
                  foreign_key: { to_table: :tasks, on_delete: :nullify }
    add_column :users, :daily_recommendation_date, :date
  end
end
