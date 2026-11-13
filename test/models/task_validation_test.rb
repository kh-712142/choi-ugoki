require "test_helper"

class TaskValidationTest < ActiveSupport::TestCase
  test "strips surrounding whitespace from a task name" do
    task = Task.new(name: "  肩を10秒伸ばす  ")

    assert task.valid?
    assert_equal "肩を10秒伸ばす", task.name
  end

  test "rejects a blank task name" do
    task = Task.new(name: "   ")

    assert_not task.valid?
    assert_includes task.errors[:name], "を入力してください"
  end

  test "accepts a task name with 100 characters and rejects longer names" do
    accepted_task = Task.new(name: "a" * 100)
    rejected_task = Task.new(name: "a" * 101)

    assert accepted_task.valid?
    assert_not rejected_task.valid?
  end
end
