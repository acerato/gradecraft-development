class CriterionGradesController < ApplicationController
  before_action :ensure_staff?

  before_action :find_criterion_grade, except: [:new, :create]
  after_action :respond_with_criterion_grade

  def new
    @criterion_grade = CriterionGrade.new criterion_grade_params
  end

  def create
    @criterion_grade = CriterionGrade.create criterion_grade_params
  end

  def destroy
    @criterion_grade.destroy
  end

  def update
    @criterion_grade.update_attributes criterion_grade_params
  end

  private

  def criterion_grade_params
    params.require(:criteron_grade).permit :points, :criterion_id, :level_id,
      :student_id, :assignment_id, :comments
  end

  def find_criterion_grade
    @criterion_grade = CriterionGrade.find params[:id]
  end

  def respond_with_criterion_grade
    respond_with @criterion_grade
  end
end
