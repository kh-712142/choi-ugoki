require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    Task.default_tasks.delete_all
  end

  test "検証前にメールアドレスを正規化する" do
    user = User.new(email: "  TEST@Example.COM ", password: "password123")

    assert user.valid?
    assert_equal "test@example.com", user.email
  end

  test "大文字小文字を区別せず重複メールアドレスを拒否する" do
    User.create!(email: "existing@example.com", password: "password123")
    duplicate = User.new(email: "EXISTING@example.com", password: "password123")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "はすでに存在します"
  end

  test "8文字未満のパスワードを拒否する" do
    user = User.new(email: "short@example.com", password: "1234567")

    assert_not user.valid?
    assert_includes user.errors[:password], "は8文字以上で入力してください"
  end

  test "8文字のパスワードを受け入れる" do
    user = User.new(email: "valid@example.com", password: "12345678")

    assert user.valid?
  end

  test "72バイトを超えるパスワードは拒否する" do
    user = User.new(email: "long-password@example.com", password: "あ" * 25)

    assert_not user.valid?
    assert user.errors[:password].any?
  end

  test "指定日には選択済みのおすすめを使い、翌日は既定のおすすめに戻る" do
    user = User.create!(email: "recommendation@example.com", password: "password123")
    selected_task = Task.create!(user_id: nil, name: "ユーザーが選んだ標準タスク")
    Task.create!(user_id: nil, name: "別の標準タスク")
    selected_date = Date.new(2026, 11, 14)

    user.select_daily_recommendation!(selected_task, selected_date)

    assert_equal selected_task, user.recommended_task_for(selected_date)
    assert_equal Task.daily_recommendation(selected_date + 1), user.recommended_task_for(selected_date + 1)
  end

  test "候補には標準タスクと自分のタスクだけを含め、現在のおすすめを除外する" do
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

  test "他のユーザーのタスクをおすすめに選べない" do
    user = User.create!(email: "candidate-owner@example.com", password: "password123")
    another_user = User.create!(email: "candidate-other@example.com", password: "password123")
    another_users_task = another_user.tasks.create!(name: "他人のタスク")

    assert_raises(ActiveRecord::RecordNotFound) do
      user.select_daily_recommendation!(another_users_task)
    end
  end

  test "月曜から日曜までの今週の達成記録を数える" do
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

  test "指定日の最新達成記録を5件だけ返す" do
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
