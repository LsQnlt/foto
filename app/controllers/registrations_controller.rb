class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
  before_action :set_invitation
  before_action :redirect_if_no_invitation

  def new
    @user = User.new(email_address: @invitation.email)
  end

  def create
    @user = User.new(user_params)
    @user.email_address = @invitation.email

    if @user.save
      @invitation.mark_as_used!
      flash[:success] = I18n.t('registrations.create.success')
      redirect_to user_albums_path(pseudonym: @user.pseudonym)
    else
      flash[:alert] = @user.errors.full_messages.join(", ")
      render :new,  status: :unprocessable_entity
    end
  end

  private

  def set_invitation
    @invitation = Invitation.usable.find_by(token: params[:token])
  end

  def redirect_if_no_invitation
    unless @invitation
      redirect_to root_path, alert: t('registrations.token.invalid')
      return
    end
  end

  def user_params
    params.expect(user: [:password, :password_confirmation, :pseudonym])
  end
end
