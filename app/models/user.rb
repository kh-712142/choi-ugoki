class User < ApplicationRecord
  has_many :tasks, dependent: :destroy
  belongs_to :daily_recommendation_task, class_name: "Task", optional: true

  has_secure_password

  before_validation :normalize_email

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true

  def recommended_task_for(date = Date.current)
    if daily_recommendation_date == date && daily_recommendation_task &&
        Task.available_to(self).exists?(id: daily_recommendation_task_id)
      daily_recommendation_task
    else
      Task.daily_recommendation(date)
    end
  end

  def alternative_recommendation_tasks(date = Date.current)
    selected_task_id = recommended_task_for(date)&.id
    candidates = Task.default_tasks.order(:id).to_a + tasks.order(:id).to_a
    candidates.reject { |task| task.id == selected_task_id }
  end

  def select_daily_recommendation!(task, date = Date.current)
    selected_task = Task.available_to(self).find(task.id)
    update!(daily_recommendation_task: selected_task, daily_recommendation_date: date)
  end

  private

  def normalize_email
    self.email = email.strip.downcase if email.present?
  end
end
