require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "shows the form with a valid invitation" do
    get new_user_registration_url(token: invitations(:pending).token)
    assert_response :success
  end

  test "redirects with a missing, used or expired invitation" do
    [nil, invitations(:used).token, invitations(:expired).token].each do |token|
      get new_user_registration_url(token: token)
      assert_redirected_to root_path
    end
  end

  test "creates the user with the invitation email and consumes the invitation" do
    invitation = invitations(:pending)

    assert_difference("User.count", 1) do
      post user_registration_url, params: {
        token: invitation.token,
        user: { pseudonym: "nouveau", password: "password123", password_confirmation: "password123" },
      }
    end

    user = User.find_by!(pseudonym: "nouveau")
    assert_equal invitation.email, user.email_address
    assert invitation.reload.used?
    assert_redirected_to user_albums_path(pseudonym: "nouveau")
  end

  test "re-renders the form when the user is invalid" do
    assert_no_difference("User.count") do
      post user_registration_url, params: {
        token: invitations(:pending).token,
        user: { pseudonym: "nouveau", password: "short", password_confirmation: "short" },
      }
    end
    assert_response :unprocessable_entity
    assert_not invitations(:pending).reload.used?
  end
end
