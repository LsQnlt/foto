# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.has_role?(:admin)
        scope.all
      elsif user.has_role?(:user)
        scope.where(id: user.id)
      else
        scope.none
      end
    end
  end
end
