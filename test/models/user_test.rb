require "test_helper"

class UserTest < ActiveSupport::TestCase
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
end
