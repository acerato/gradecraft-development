class WelcomeEmailPreview
  def welcome_email
    user = User.last
    UserMailer.welcome_email user
  end
end
