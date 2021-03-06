class Assignments::StudentsController < ApplicationController
  before_filter :ensure_staff?

  # POST /assignments/:assignment_id/students/:student_id/grade
  def grade
    grade = Grade.find_or_create params[:assignment_id], params[:student_id]
    redirect_to edit_grade_path grade, team_id: params[:team_id]
  end
end
