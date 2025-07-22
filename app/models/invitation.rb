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
# Indexes
#
#  index_invitations_on_email  (email) UNIQUE
#  index_invitations_on_token  (token) UNIQUE
#
class Invitation < ApplicationRecord
  before_create :generate_token

  validates :email, presence: true, uniqueness: true
  validates :token, uniqueness: true

  scope :usable, -> { where(used: false).where('expires_at IS NULL OR expires_at > ?', Time.current) }

  def mark_as_used!
    update(used: true)
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
