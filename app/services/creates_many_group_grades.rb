require "light-service"
require_relative "group_services/iterates_assignment_groups_to_create_grades"

module Services
  class CreatesManyGroupGrades
    include LightService::Organizer

    def self.create(assignment_id, grades_by_group_params)
      with(assignment_id: assignment_id, grades_by_group_params: grades_by_group_params)
        .reduce(
          Actions::IteratesAssignmentGroupsToCreateGrades
        )
    end
  end
end
