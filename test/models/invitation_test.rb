# == Schema Information
#
# Table name: invitations
#
#  id         :integer          not null, primary key
#  email      :string
#  expires_at :datetime
#  token      :string
#  used       :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require "test_helper"

class InvitationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
