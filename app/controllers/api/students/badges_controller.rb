class API::Students::BadgesController < ApplicationController

  before_filter :ensure_staff?

  # GET api/students/:student_id/badges
  def index
    @student = User.find(params[:student_id])
    @update_predictions = false
    @badges = current_course.badges.select(
      :can_earn_multiple_times,
      :course_id,
      :description,
      :full_points,
      :icon,
      :id,
      :name,
      :position,
      :visible,
      :visible_when_locked).includes(:earned_badges)
    @earned_badges =
      current_course.earned_badges.where(student_id: @student.id).select(
        :id,
        :badge_id,
        :grade_id,
        :feedback,
        :level_id,
        :student_id,
        :student_visible,
        :points
      )
    @predicted_earned_badges =
      PredictedEarnedBadge.find_or_create_for_student(
        current_course.id, @student.id
      )
    render template: "api/badges/index"
  end
end
