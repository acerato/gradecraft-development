class Assignments::StudentsController < ApplicationController
  before_action :ensure_staff?

  # POST /assignments/:assignment_id/students/:student_id/grade
  def grade
    grade = Grade.find_or_create params[:assignment_id], params[:student_id]
    redirect_to edit_grade_path grade
  end
end
