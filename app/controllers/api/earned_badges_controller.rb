require_relative "../../services/creates_earned_badge"

class API::EarnedBadgesController < ApplicationController
  before_filter :ensure_staff?

  # POST /api/earned_badges
  def create
    result = Services::CreatesEarnedBadge.award earned_badge_params
    if result.success?
      @earned_badge = result.earned_badge
      render status: 201
    else
      render json: { message: result.message, success: false }, status: 400
    end
  end

  # DELETE /api/earned_badges/:id
  def destroy
    earned_badge = EarnedBadge.where(id: params[:id]).first
    if earned_badge.present? && earned_badge.destroy
      render json: { message: "Earned badge successfully deleted", success: true },
        status: 200
    else
      render json: { message: "Earned badge failed to delete", success: false },
        status: 400
    end
  end

  private

  def earned_badge_params
    params.require(:earned_badge).permit(:feedback, :student_id, :badge_id,
      :submission_id, :course_id, :assignment_id, :level_id, :criterion_id, :grade_id).merge(awarded_by: current_user, course: current_course)
  end
end
