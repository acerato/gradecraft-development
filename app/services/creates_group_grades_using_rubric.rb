require "light-service"
require_relative "group_services/verifies_group"
require_relative "group_services/iterates_creates_grade_using_rubric"

module Services
  class CreatesGroupGradesUsingRubric
    extend LightService::Organizer

    aliases raw_params: :attributes

    def self.create(raw_params, graded_by_id)
      with(raw_params: raw_params, graded_by_id: graded_by_id)
        .reduce(
          Actions::VerifiesGroup,
          Actions::IteratesCreatesGradeUsingRubric
        )
    end
  end
end
