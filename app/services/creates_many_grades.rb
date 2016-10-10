require "light-service"
require "creates_grade/iterates_grade_attributes"

module Services
  class CreatesManyGrades
    extend LightService::Organizer

    def self.create(assignment_id, graded_by_id, grade_attributes)
      with(grade_attributes: grade_attributes, assignment_id: assignment_id, graded_by_id: graded_by_id)
        .reduce(
          Actions::IteratesGradeAttributes
        )
    end
  end
end
