class TaskCompletion < ApplicationRecord
  belongs_to :user
  belongs_to :task

  validates :completed_on, presence: true
  validate :task_is_available_to_user

  private

  def task_is_available_to_user
    return if task.blank? || user.blank? || task.user_id.nil? || task.user_id == user_id

    errors.add(:task, :invalid)
  end
end
