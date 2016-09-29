class Assignments::GroupsController < ApplicationController
  before_action :ensure_staff?

  # GET /assignments/:assignment_id/groups/:id/grade
  # Grading an assignment for a whole group
  def grade
    @assignment = current_course.assignments.find(params[:assignment_id])
    @group = @assignment.groups.find(params[:id])
    @submission_id = @assignment.submissions.where(group_id: @group.id).first.try(:id)
    @title = "Grading #{ @group.name }'s #{@assignment.name}"
    @assignment_score_levels = @assignment.assignment_score_levels
    @rubric = @assignment.rubric if @assignment.grade_with_rubric?
  end

  # PUT /assignments/:assignment_id/groups/:id/graded
  # Updates the grades for a whole group for an assignment
  def graded
    @assignment = current_course.assignments.find(params[:assignment_id])
    @group = @assignment.groups.find(params[:id])

    @grades = Grade.find_or_create_grades(@assignment.id, @group.students.pluck(:id))

    grade_ids = []
    @grades = @grades.each do |grade|
      grade.update_attributes(grade_params.merge(graded_at: DateTime.now, group_id: @group.id))
      grade_ids << grade.id
    end

    # @mz TODO: add specs
    enqueue_multiple_grade_update_jobs(grade_ids)

    respond_with @assignment, notice: "#{@group.name}'s #{@assignment.name} was successfully updated"
  end

  private

  def grade_params
    params.require(:grade).permit :graded_at, :group_id, :graded_by_id, :instructor_modified,
      :submission_id, :raw_points, :feedback, :status
  end

  # Schedule the `GradeUpdater` for all grades provided
  def enqueue_multiple_grade_update_jobs(grade_ids)
    grade_ids.each { |id| GradeUpdaterJob.new(grade_id: id).enqueue }
  end
end
