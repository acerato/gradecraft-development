class Students::AssignmentTypeWeightsController < ApplicationController

  before_action :ensure_staff?

  # GET /students/:id/assignment_type_weights
  # faculty view of student's weights index view
  def index
    @title =
      "Editing #{current_student.name}'s #{term_for :weight} Choices"
    render template: "assignment_type_weights/index"
  end
end
