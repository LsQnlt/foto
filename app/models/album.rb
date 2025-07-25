# == Schema Information
#
# Table name: albums
#
#  id                 :integer          not null, primary key
#  description        :text
#  password_digest    :string
#  password_protected :boolean
#  published          :boolean          default(FALSE)
#  title              :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :integer          not null
#
# Indexes
#
#  index_albums_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Album < ApplicationRecord
  has_secure_password validations: false

  belongs_to :user
  has_many :photos, dependent: :destroy
  has_one :cover_photo, -> { order(created_at: :asc) }, class_name: 'Photo'

  accepts_nested_attributes_for :photos, allow_destroy: true
  validates :password, presence: true, if: -> { password_protected? && (new_record? || password.present?) }

  attr_accessor :uploaded_photos

  scope :published, -> { where(published: true) }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "id", "id_value", "title", "updated_at", "user_id"]
  end
end
