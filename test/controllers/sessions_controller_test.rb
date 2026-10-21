require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "shows the login page" do
    get new_session_url
    assert_response :success
  end

  test "logs in with valid credentials" do
    assert_difference("Session.count", 1) do
      sign_in_as users(:alice)
    end
    assert_redirected_to root_url
    assert cookies[:session_id].present?
  end

  test "refuses invalid credentials" do
    assert_no_difference("Session.count") do
      sign_in_as users(:alice), password: "wrong"
    end
    assert_redirected_to new_session_url
  end

  test "logs out" do
    sign_in_as users(:alice)
    assert_difference("Session.count", -1) do
      delete session_url
    end
    assert_redirected_to new_session_url
  end
end
