# Unlock Conditions are used to declare a sequence of assignments or badges
# that must be completed at different levels before something else can be
# done. Unlock States store whether or not a student has met the necessary
# conditions

class UnlockConditionsController < ApplicationController
  before_action :ensure_staff?

  def create
    @unlock_condition =
      current_course.unlock_condition.new(unlock_condition_params)
    @unlock_condition.save
  end

  def update
    @unlock_condition = current_course.unlock_conditions.find(params[:id])
    @unlock_condition.update_attributes(unlock_condition_params)
    respond_with @unlock_condition
  end

  def destroy
    @unlock_condition = current_course.unlock_conditions.find(params[:id])
    @unlock_condition.destroy
  end

  private

  def unlock_condition_params
    params.require(:unlock_condition).permit :unlockable_id, :unlockable_type, :condition_id,
      :condition_type, :condition_state, :condition_value, :condition_date
  end
end
