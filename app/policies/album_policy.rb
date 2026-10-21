# frozen_string_literal: true

class AlbumPolicy < ApplicationPolicy
  def show?
    record.published? || create?
  end

  def create?
    admin? || record.user_id == user&.id
  end

  def update?
    create?
  end

  def permitted_attributes
    attributes = [:title, :description, :published, :password_protected, :password, { uploaded_photos: [] }]
    attributes << :user_id if admin?
    attributes
  end

  class Scope < Scope
    def resolve
      if user.has_role?(:admin)
        scope.all
      elsif user.has_role?(:user)
        scope.where(user_id: user.id)
      else
        scope.none
      end
    end
  end
end
