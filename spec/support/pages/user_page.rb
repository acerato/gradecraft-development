class UserPage
  include Capybara::DSL

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  protected

  def fill_out_form(fields={})
    fill_in "First name", with: fields[:first_name] || user.first_name
    fill_in "Last name", with: fields[:last_name] || user.last_name
    fill_in "Email", with: fields[:email] || user.email
    fill_in "Display name", with: fields[:display_name] || user.display_name

    courses = fields[:courses]
    courses.each_with_index do |course, index|
      destroyed = find(:xpath, ".//input[@id='user_course_memberships_attributes_#{index}__destroy']", visible: false)
      if destroyed.value == "true"
        destroyed.set false
      else
        destroyed.set true
      end
    end if courses
  end
end
