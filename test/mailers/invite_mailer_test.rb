require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  test "invite_email contains the registration link" do
    invitation = invitations(:pending)
    mail = InviteMailer.with(invitation: invitation).invite_email

    assert_equal [invitation.email], mail.to
    assert_equal ["contact@foto.rip"], mail.from
    assert_includes mail.body.encoded, "token=#{invitation.token}"
  end
end
