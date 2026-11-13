class Task < ApplicationRecord
  belongs_to :user, optional: true

  scope :default_tasks, -> { where(user_id: nil) }

  def self.daily_recommendation(date = Date.current)
    tasks = default_tasks.order(:id)
    task_count = tasks.count
    return if task_count.zero?

    tasks.offset(date.jd % task_count).first
  end
end
