require "test_helper"

class TaskValidationTest < ActiveSupport::TestCase
  test "タスク名の前後の空白を取り除く" do
    task = Task.new(name: "  肩を10秒伸ばす  ")

    assert task.valid?
    assert_equal "肩を10秒伸ばす", task.name
  end

  test "空欄のタスク名を拒否する" do
    task = Task.new(name: "   ")

    assert_not task.valid?
    assert_includes task.errors[:name], "を入力してください"
  end

  test "100文字のタスク名は受け入れ、それを超える名前は拒否する" do
    accepted_task = Task.new(name: "a" * 100)
    rejected_task = Task.new(name: "a" * 101)

    assert accepted_task.valid?
    assert_not rejected_task.valid?
  end
end
