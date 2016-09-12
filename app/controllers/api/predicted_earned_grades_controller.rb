class API::PredictedEarnedGradesController < ApplicationController
  include PredictorData

  before_action :ensure_student?, only: [:update]

  # GET api/predicted_earned_grades
  def index
    # restrict predictions for professor viewing student in preview mode
    if student_impersonation?
      user = User.find(impersonating_agent_id)
      student = current_student
    elsif current_user_is_student?
      user = current_user
      student = current_student
    # pass a null student for faculty viewing generic predictor
    else
      user = current_user
      student = NullStudent.new(current_course)
    end
    @assignments = PredictedAssignmentCollectionSerializer.new(
      current_course.assignments.ordered, user, student
    )
  end

  # POST api/predicted_earned_grades/:id
  def update
    prediction = PredictedEarnedGrade.where(
      student: current_student,
      id: params[:id]
    ).first

    if prediction.present?
      prediction.predicted_points = params[:predicted_points]
      prediction.save

      # This should be extracted with the rest of the event_loggers
      # TODO: this should be implemented with a PredictorEventLogger instead of a
      # PredictorEventJob since the PredictorEventLogger has logic for cleaning up
      # request params data, but for now this is better than what we had
      PredictorEventJob.new(
        data: predictor_event_attrs(prediction)
      ).enqueue

      if prediction.valid?
        render json: {
          id: prediction.id,
          predicted_points: prediction.predicted_points
        }
      else
        render json: {
          errors:  prediction.errors.full_messages
          },
          status: 400
      end
    else
      render json: {
        errors: [{ detail: "unable to find prediction" }], success: false
        },
        status: 404
    end
  end

  private

  def predictor_event_attrs(prediction)
    {
      prediction_type: "grade",
      course_id: current_course.id,
      user_id: current_user.id,
      student_id: current_student.try(:id),
      user_role: current_user.role(current_course),
      assignment_id: params[:id],
      predicted_points: params[:predicted_points],
      possible_points: prediction.assignment.try(:full_points),
      created_at: Time.now,
      prediction_saved_successfully: prediction.valid?
    }
  end
end
