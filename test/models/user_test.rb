require "test_helper"

class UserTest < ActiveSupport::TestCase
  def build_user(**attrs)
    User.new({ email_address: "new@example.com", pseudonym: "new_user", password: "password123" }.merge(attrs))
  end

  test "valid with email, pseudonym and password" do
    assert build_user.valid?
  end

  test "normalizes email address" do
    user = build_user(email_address: "  New@Example.COM ")
    assert_equal "new@example.com", user.email_address
  end

  test "rejects a pseudonym with forbidden characters" do
    assert_not build_user(pseudonym: "pas bon!").valid?
  end

  test "requires a unique pseudonym" do
    assert_not build_user(pseudonym: users(:alice).pseudonym).valid?
  end

  test "requires a password of at least 8 characters" do
    assert_not build_user(password: "short").valid?
  end

  test "gets the user role by default" do
    user = build_user
    user.save!
    assert user.has_role?(:user)
    assert_not user.has_role?(:admin)
  end

  test "authenticates with the right password" do
    assert_equal users(:alice), User.authenticate_by(email_address: "alice@example.com", password: "password")
    assert_nil User.authenticate_by(email_address: "alice@example.com", password: "wrong")
  end

  test "a user can only have one role" do
    alice = users(:alice)
    alice.add_role(:admin)
    assert_equal ["user"], alice.reload.roles.pluck(:name)
  end
end
