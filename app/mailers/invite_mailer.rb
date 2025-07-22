class InviteMailer < ApplicationMailer
  def invite_email
    @invitation = params[:invitation]
    @url = new_user_registration_url(token: @invitation.token)

    mail(to: @invitation.email, subject: t('.subject'))
  end
end
