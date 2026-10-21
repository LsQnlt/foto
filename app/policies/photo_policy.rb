# frozen_string_literal: true

class PhotoPolicy < ApplicationPolicy
  def create?
    admin? || (user.present? && record.album&.user_id == user.id)
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  def permitted_attributes
    [:image, :album_id]
  end

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
