require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "renders the registration form" do
    get new_user_path

    assert_response :success
    assert_select "h1", "アカウント新規登録"
    assert_select "input[type=email][name='user[email]']"
    assert_select "input[type=password][name='user[password]']"
    assert_select "input[type=password][name='user[password_confirmation]']"
    assert_select "a[href='#{login_path}']", "ログインに戻る"
  end

  test "creates a user, signs them in, and redirects to the home page" do
    assert_difference("User.count", 1) do
      post users_path, params: {
        user: {
          email: "NEWUSER@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.find_by!(email: "newuser@example.com")
    assert_equal user.id, session[:user_id]
    assert_redirected_to root_path
  end

  test "renders errors when registration is invalid" do
    assert_no_difference("User.count") do
      post users_path, params: {
        user: {
          email: "invalid@example.com",
          password: "short",
          password_confirmation: "short"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select ".registration-errors", text: /8文字以上/
  end
end
