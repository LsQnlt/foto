# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email_address   :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
ActiveAdmin.register User do
  # Specify parameters which should be permitted for assignment
  permit_params :email_address, :pseudonym

  # or consider:
  #
  # permit_params do
  #   permitted = [:email_address, :password_digest]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :email_address
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :email_address
    column :created_at
    column :updated_at
    column :pseudonym
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :email_address
      row :pseudonym
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors
    f.inputs do
      f.input :email_address
      f.input :pseudonym
    end
    f.actions
  end

  controller do
    before_action :authorize_create!, only: [:new, :create]
    def scoped_collection
      policy_scope(User)
    end

    private

    def authorize_create!
      unless Current.user.has_role?(:admin)
        flash[:error] = t('active_admin.users.authorize_create.error')
        redirect_to admin_users_path
      end
    end
  end
end
