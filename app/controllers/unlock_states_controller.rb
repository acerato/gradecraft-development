# Unlock States are used to store whether or not a student has achieved the
# necessary Unlock Conditions to be able to do whatever is locked
class UnlockStatesController < ApplicationController

  before_action :ensure_staff?
  before_action :save_referer, only: [:manually_unlock]

  def create
    @unlock_state = current_course.unlock_state.new(unlock_condition_params)
    @unlock_condition.save
  end

  def update
    @unlock_state = current_course.unlock_states.find(params[:id])
    @unlock_state.update_attributes(unlock_condition_params)
    respond_with @unlock_state
  end

  def manually_unlock
    if params[:assignment_id].present?
      @unlockable = current_course.assignments.find(params[:assignment_id])
    elsif params[:badge_id].present?
      @unlockable = current_course.badges.find(params[:badge_id])
    end
    @student = current_course.students.find(params[:student_id])
    @unlock_state = @unlockable.find_or_create_unlock_state(@student.id)
    @unlock_state.instructor_unlocked = true
    @unlock_state.save
    redirect_to session[:return_to]
  end

  def destroy
    @unlock_state = current_course.unlock_state.find(params[:id])
    @unlock_state.destroy
  end

  private

  def unlock_condition_params
    params.require(:unlock_condition).permit :unlockable_id, :unlockable_type, :student_id,
      :instructor_unlocked, :unlocked, :unlockable
  end
end
