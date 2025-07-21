class InviteMailer < ApplicationMailer
  def invite_email
    @invitation = params[:invitation]
    @url = new_user_registration_url(token: @invitation.token)

    mail(to: @invitation.email, subject: "Vous êtes invité à rejoindre l'app !")
  end
end
