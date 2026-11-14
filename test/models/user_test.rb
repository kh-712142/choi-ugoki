require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    Task.default_tasks.delete_all
  end

  test "normalizes email before validation" do
    user = User.new(email: "  TEST@Example.COM ", password: "password123")

    assert user.valid?
    assert_equal "test@example.com", user.email
  end

  test "rejects duplicate email regardless of case" do
    User.create!(email: "existing@example.com", password: "password123")
    duplicate = User.new(email: "EXISTING@example.com", password: "password123")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "はすでに存在します"
  end

  test "requires a password of at least eight characters" do
    user = User.new(email: "short@example.com", password: "1234567")

    assert_not user.valid?
    assert_includes user.errors[:password], "は8文字以上で入力してください"
  end

  test "accepts a password with eight characters" do
    user = User.new(email: "valid@example.com", password: "12345678")

    assert user.valid?
  end

  test "rejects a password longer than bcrypt's 72-byte limit" do
    user = User.new(email: "long-password@example.com", password: "あ" * 25)

    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "uses a selected recommendation for its date and falls back the next day" do
    user = User.create!(email: "recommendation@example.com", password: "password123")
    selected_task = Task.create!(user_id: nil, name: "ユーザーが選んだ標準タスク")
    Task.create!(user_id: nil, name: "別の標準タスク")
    selected_date = Date.new(2026, 11, 14)

    user.select_daily_recommendation!(selected_task, selected_date)

    assert_equal selected_task, user.recommended_task_for(selected_date)
    assert_equal Task.daily_recommendation(selected_date + 1), user.recommended_task_for(selected_date + 1)
  end

  test "includes only default and own tasks in alternatives and excludes current recommendation" do
    user = User.create!(email: "candidate@example.com", password: "password123")
    selected_task = Task.create!(user_id: nil, name: "現在のおすすめ")
    default_task = Task.create!(user_id: nil, name: "別の標準タスク")
    own_task = user.tasks.create!(name: "自分のタスク")
    another_user = User.create!(email: "another-candidate@example.com", password: "password123")
    another_user.tasks.create!(name: "他のユーザーのタスク")
    date = Date.current

    user.select_daily_recommendation!(selected_task, date)

    assert_equal [ default_task, own_task ], user.alternative_recommendation_tasks(date)
  end

  test "cannot select another user's task as a recommendation" do
    user = User.create!(email: "candidate-owner@example.com", password: "password123")
    another_user = User.create!(email: "candidate-other@example.com", password: "password123")
    another_users_task = another_user.tasks.create!(name: "他人のタスク")

    assert_raises(ActiveRecord::RecordNotFound) do
      user.select_daily_recommendation!(another_users_task)
    end
  end

  test "counts this week's completions including both Monday and Sunday" do
    travel_to Time.zone.local(2026, 11, 11, 12)
    user = User.create!(email: "weekly-count@example.com", password: "password123")
    another_user = User.create!(email: "weekly-count-other@example.com", password: "password123")
    task = Task.create!(user_id: nil, name: "標準タスク")

    user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 9))
    user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 15))
    user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 15))
    user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 8))
    user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 16))
    another_user.task_completions.create!(task:, completed_on: Date.current)

    assert_equal 3, user.weekly_completion_count
  ensure
    travel_back
  end

  test "returns only the five newest completions for the given date" do
    travel_to Time.zone.local(2026, 11, 14, 12)
    user = User.create!(email: "recent-completions@example.com", password: "password123")
    tasks = 7.times.map { |index| Task.create!(user_id: nil, name: "タスク#{index}") }
    completions = tasks.each_with_index.map do |task, index|
      user.task_completions.create!(task:, completed_on: Date.current, created_at: (6 - index).minutes.ago)
    end
    yesterday_task = Task.create!(user_id: nil, name: "昨日のタスク")
    user.task_completions.create!(task: yesterday_task, completed_on: Date.yesterday)

    assert_equal completions.last(5).reverse, user.recent_completions_on.to_a
  ensure
    travel_back
  end
end
