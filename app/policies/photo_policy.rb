# frozen_string_literal: true

class PhotoPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.has_role?(:admin)
        scope.all
      elsif user.has_role?(:user)
        scope.includes(:album).where(album: { user_id: user.id })
      else
        scope.none
      end
    end
  end
end
