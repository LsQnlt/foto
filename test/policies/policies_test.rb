require "test_helper"

class PolicyScopesTest < ActiveSupport::TestCase
  test "admin sees everything" do
    admin = users(:admin)
    assert_equal Album.count, AlbumPolicy::Scope.new(admin, Album).resolve.count
    assert_equal Photo.count, PhotoPolicy::Scope.new(admin, Photo).resolve.count
    assert_equal User.count, UserPolicy::Scope.new(admin, User).resolve.count
  end

  test "a user only sees their own records" do
    alice = users(:alice)
    assert_equal alice.albums.sort, AlbumPolicy::Scope.new(alice, Album).resolve.sort
    assert_equal [photos(:alice_public_photo)], PhotoPolicy::Scope.new(alice, Photo).resolve.to_a
    assert_equal [alice], UserPolicy::Scope.new(alice, User).resolve.to_a
  end
end

class PermissionsTest < ActiveSupport::TestCase
  test "only admins may set the album owner" do
    assert_includes AlbumPolicy.new(users(:admin), Album).permitted_attributes, :user_id
    assert_not_includes AlbumPolicy.new(users(:alice), Album).permitted_attributes, :user_id
  end

  test "a user may only manage photos of their own albums" do
    alice = users(:alice)
    assert PhotoPolicy.new(alice, photos(:alice_public_photo)).destroy?
    assert_not PhotoPolicy.new(alice, photos(:bob_public_photo)).destroy?
    assert PhotoPolicy.new(users(:admin), photos(:bob_public_photo)).destroy?
  end

  test "a user may only save their own albums" do
    alice = users(:alice)
    assert AlbumPolicy.new(alice, albums(:alice_public)).update?
    assert_not AlbumPolicy.new(alice, albums(:bob_public)).update?
  end

  test "drafts are only shown to their owner and admins" do
    draft = albums(:alice_draft)
    assert AlbumPolicy.new(nil, albums(:alice_public)).show?
    assert_not AlbumPolicy.new(nil, draft).show?
    assert_not AlbumPolicy.new(users(:bob), draft).show?
    assert AlbumPolicy.new(users(:alice), draft).show?
    assert AlbumPolicy.new(users(:admin), draft).show?
  end
end
