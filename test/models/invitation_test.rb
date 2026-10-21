require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  test "generates a token on creation" do
    invitation = Invitation.create!(email: "someone@example.com")
    assert invitation.token.present?
  end

  test "requires a unique email" do
    assert_not Invitation.new(email: invitations(:pending).email).valid?
  end

  test "usable scope excludes used and expired invitations" do
    usable = Invitation.usable
    assert_includes usable, invitations(:pending)
    assert_not_includes usable, invitations(:used)
    assert_not_includes usable, invitations(:expired)
  end

  test "an invitation without expiry date stays usable" do
    invitation = Invitation.create!(email: "forever@example.com", expires_at: nil)
    assert_includes Invitation.usable, invitation
  end

  test "mark_as_used! makes it unusable" do
    invitations(:pending).mark_as_used!
    assert_not_includes Invitation.usable, invitations(:pending)
  end
end
