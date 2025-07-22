# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email_address   :string           not null
#  password_digest :string           not null
#  pseudonym       :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#  index_users_on_pseudonym      (pseudonym) UNIQUE
#
class User < ApplicationRecord
  rolify
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :albums, dependent: :destroy

  has_and_belongs_to_many :roles, join_table: :users_roles, before_add: :ensure_only_one_role

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  validates :pseudonym, presence: true, uniqueness: true
  validates :email_address, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }

  after_initialize :assign_default_role, if: :new_record?

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "email_address", "id", "id_value", "password_digest", "updated_at"]
  end

  def assign_default_role
    add_role(:user) if roles.blank?
  end

  private

  def ensure_only_one_role(role)
    if roles.count >= 1
      raise ActiveRecord::Rollback, "Seulement un rôle peut être attribué"
    end
  end
end
