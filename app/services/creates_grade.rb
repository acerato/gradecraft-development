require "light-service"

module Services
  class CreatesGrade
    extend LightService::Organizer

    aliases raw_params: :attributes

    def self.create(raw_params)
      with(raw_params: raw_params)
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
