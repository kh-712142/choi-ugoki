require "test_helper"

class TaskCompletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Task.default_tasks.delete_all
    @user = User.create!(email: "completion@example.com", password: "password123")
    @recommended_task = Task.create!(user_id: nil, name: "今日のおすすめ")
    @other_users_task = User.create!(email: "completion-other@example.com", password: "password123").tasks.create!(name: "他のユーザーのタスク")
    post login_path, params: { email: @user.email, password: "password123" }
  end

  test "records each completion for the current recommendation using today's server date" do
    next_task = Task.create!(user_id: nil, name: "次のおすすめ")
    first_task = @user.recommended_task_for
    following_task = @user.alternative_recommendation_tasks.first

    assert_equal [ @recommended_task.id, next_task.id ].sort, [ first_task.id, following_task.id ].sort

    post task_completions_path, params: { task_id: @other_users_task.id, completed_on: Date.yesterday }

    assert_redirected_to root_path
    follow_redirect!
    assert_select "dialog[data-completion-dialog]"
    assert_select ".completion-dialog__message", "えらい！この調子で明日もなにか1つ運動してみよう！"
    assert_equal following_task.id, @user.reload.daily_recommendation_task_id

    post task_completions_path, params: { task_id: @other_users_task.id, completed_on: Date.yesterday }
    assert_redirected_to root_path
    follow_redirect!
    assert_select ".completion-dialog__message", "すばらしい！2回以上運動できた自分を褒めよう！"

    completions = @user.task_completions.order(:id)
    assert_equal [ first_task.id, following_task.id ], completions.pluck(:task_id)
    assert_equal [ Date.current, Date.current ], completions.pluck(:completed_on)
    assert_equal 1, completions.where(task: first_task, completed_on: Date.current).count
    assert_equal 2, @user.task_completions.where(completed_on: Date.current).count
    assert_equal first_task.id, @user.reload.daily_recommendation_task_id
  end

  test "allows completing the same task again after selecting it again" do
    next_task = Task.create!(user_id: nil, name: "次のおすすめ")
    post daily_recommendation_path, params: { task_id: @recommended_task.id }

    post task_completions_path
    assert_equal next_task.id, @user.reload.daily_recommendation_task_id
    post daily_recommendation_path, params: { task_id: @recommended_task.id }
    post task_completions_path

    assert_equal 2, @user.task_completions.where(task: @recommended_task, completed_on: Date.current).count
    assert_equal [ @recommended_task.id, @recommended_task.id ], @user.task_completions.order(:id).pluck(:task_id)
    assert_equal next_task.id, @user.reload.daily_recommendation_task_id
  end

  test "counts today's completions across different tasks" do
    another_default_task = Task.create!(user_id: nil, name: "別の標準タスク")
    @user.task_completions.create!(task: another_default_task, completed_on: Date.current)

    post task_completions_path

    assert_redirected_to root_path
    follow_redirect!
    assert_select ".completion-dialog__message", "すばらしい！2回以上運動できた自分を褒めよう！"
    assert_equal 2, @user.task_completions.where(completed_on: Date.current).count
  end

  test "does not create a completion for an unavailable task when there is no recommendation" do
    Task.default_tasks.delete_all
    @recommended_task.destroy!

    assert_no_difference("TaskCompletion.count") do
      post task_completions_path, params: { task_id: @other_users_task.id }
    end

    assert_redirected_to root_path
  end

  test "requires login to record a completion" do
    task = @user.tasks.create!(name: "本人のタスク")
    delete logout_path

    assert_no_difference("TaskCompletion.count") do
      post task_completions_path, params: { task_id: task.id }
    end

    assert_redirected_to login_path
  end
end
