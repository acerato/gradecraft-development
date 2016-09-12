class CurrentCoursesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :ensure_not_impersonating?, only: [:change]

  # Switch between enrolled courses
  def change
    if course = current_user.courses.where(id: params[:course_id]).first
      unless session[:course_id] == course.id
        session[:course_id] = CourseRouter.change!(current_user, course).id
        record_course_login_event course: course
      end
    end
    redirect_to root_url
  end
end
