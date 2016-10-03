require_relative "../creates_grade_using_rubric"

module Services
  module Actions
    class IteratesAssignmentGroupsToCreateGrades
      extend LightService::Action

      expects :assignment_id, :grades_by_group_params

      executed do |context|
        grades_by_group_params = context[:grades_by_group_params]
        assignment_id = context[:assignment_id]

        grades_by_group_params[:grades_by_group].each do |index, gbg|
          context.add_to_context Services::CreatesGroupGrades.create gbg[:group_id], gbg, assignment_id
        end
      end
    end
  end
end
