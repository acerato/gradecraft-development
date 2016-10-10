class API::AssignmentsController < ApplicationController
  before_filter :ensure_student?, only: [:update]


  # GET api/assignments
  def index
    @assignments = current_course.assignments

    if current_user_is_student?
      @student = current_student
      @update_predictions = !student_impersonation?

      if !student_impersonation?
        @assignments.includes(:predicted_earned_grades)
        @predicted_earned_grades =
          PredictedEarnedGrade.where(
            course: current_course,
            student: current_student
          )
      end
    end
  end
end
