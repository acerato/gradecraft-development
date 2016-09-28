require "light-service"
require_relative "group_services/verifies_group"
require_relative "group_services/iterates_creates_grade"

module Services
  class CreatesGroupGrades
    extend LightService::Organizer

    def self.create(group_id, grade, assignment)
      with(attributes: { "group_id" => group_id, grade: grade, assignment: assignment })
        .reduce(
          Actions::VerifiesGroup,
          Actions::IteratesCreatesGrade
        )
    end
  end
end
