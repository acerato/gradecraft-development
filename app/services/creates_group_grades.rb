require "light-service"
require_relative "group_services/verifies_group"
require_relative "group_services/iterates_creates_grade"

module Services
  class CreatesGroupGrades
    extend LightService::Organizer

    def self.create(group_id, grade_attributes, assignment_id, graded_by_id)
      with(attributes: { "group_id" => group_id, "grade" => grade_attributes, "assignment_id" => assignment_id }, graded_by_id: graded_by_id)
        .reduce(
          Actions::VerifiesGroup,
          Actions::IteratesCreatesGrade
        )
    end
  end
end
