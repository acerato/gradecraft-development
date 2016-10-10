require "light-service"

module Services
  class CreatesGrade
    extend LightService::Organizer

    aliases raw_params: :attributes

    def self.create(raw_params, graded_by_id)
      with(raw_params: raw_params, graded_by_id: graded_by_id)
        .reduce(
          Actions::VerifiesAssignmentStudent,
          Actions::BuildsGrade,
          Actions::AssociatesSubmissionWithGrade,
          Actions::MarksAsGraded,
          Actions::SavesGrade,
          Actions::RunsGradeUpdaterJob
        )
    end
  end
end
