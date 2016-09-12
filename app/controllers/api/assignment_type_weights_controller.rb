class API::AssignmentTypeWeightsController < ApplicationController

  before_action :ensure_student?

  # POST /api/assignment_types/:assignment_type_id/assignment_type_weights
  def create
    assignment_type = current_course.assignment_types.find(params[:assignment_type_id])
    weight = params[:weight]

    if assignment_type && weight && assignment_type.student_weightable?
      assignment_type_weight = assignment_type.weights.where(student: current_user).first_or_initialize
      assignment_type_weight.weight = weight
      assignment_type_weight.save

      if assignment_type_weight.valid?
        render json: {
          id: assignment_type_weight.id,
          weight: assignment_type_weight.weight
        }
      else
        render json: {
          errors:  assignment_type_weight.errors.full_messages
          },
          status: 400
      end
    else
      render json: {
        errors: [{ detail: "unable to weight assignment type" }], success: false
        },
        status: 404
    end
  end
end
