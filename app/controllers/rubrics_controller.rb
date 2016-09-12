class RubricsController < ApplicationController
  before_action :ensure_staff?

  before_action :find_rubric, only: [:destroy, :update]

  respond_to :html, :json

  def design
    @assignment = current_course.assignments.find params[:assignment_id]
    @rubric = @assignment.fetch_or_create_rubric
    @course_badge_count = @assignment.course.badges.visible.count
    respond_with @rubric
  end

  def create
    @rubric = Rubric.create params[:rubric]
    respond_with @rubric
  end

  def index_for_copy
    @assignment = Assignment.find(params[:assignment_id])
    @rubrics = Rubric.where(assignment_id: current_course.assignments.pluck(:id))
  end

  def copy
    assignment = Assignment.find(params[:assignment_id])

    # this is necessary until we
    # remove all calls to: fetch_or_create_rubric
    assignment.rubric.destroy if assignment.rubric.present?

    Rubric.find(params[:rubric_id]).copy(assignment_id: assignment.id)
    redirect_to assignment_path(assignment),
      notice: "Added rubric to #{(term_for :assignment).titleize} #{assignment.name}"
  end

  def destroy
    @rubric.destroy
    respond_with @rubric
  end

  def update
    @rubric.update_attributes params[:rubric]
    respond_with @rubric, status: :not_found
  end

  def export
    assignment = current_course.assignments.find params[:assignment_id]
    rubric = assignment.rubric
    respond_to do |format|
      format.csv { send_data RubricExporter.new.export(rubric), filename: "#{assignment.name} Rubric.csv" }
    end
  end

  private

  def find_rubric
    @rubric = @assignment.rubric
  end
end
