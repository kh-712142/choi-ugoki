class Task < ApplicationRecord
  belongs_to :user, optional: true

  before_validation :normalize_name

  validates :name, presence: true, length: { maximum: 100 }

  scope :default_tasks, -> { where(user_id: nil) }
  scope :available_to, ->(user) { default_tasks.or(where(user: user)) }

  def self.daily_recommendation(date = Date.current)
    tasks = default_tasks.order(:id)
    task_count = tasks.count
    return if task_count.zero?

    tasks.offset(date.jd % task_count).first
  end

  private

  def normalize_name
    self.name = name.strip if name.present?
  end
end
