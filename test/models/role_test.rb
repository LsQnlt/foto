require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "fixtures assign one role per user" do
    assert users(:admin).has_role?(:admin)
    assert users(:alice).has_role?(:user)
    assert_not users(:alice).has_role?(:admin)
  end
end
