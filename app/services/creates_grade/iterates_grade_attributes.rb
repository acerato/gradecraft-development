require_relative "../creates_grade"

module Services
  module Actions
    class IteratesGradeAttributes
      extend LightService::Action

      expects :assignment_id
      expects :graded_by_id
      expects :grade_attributes

      executed do |context|
        context.grade_attributes.each do |key, value|
          params = { "grade" => value }
          params.merge! "assignment_id" => context.assignment_id
          params.merge! "student_id" => value[:student_id]
          context.add_to_context Services::CreatesGrade.create params, context.graded_by_id
        end
      end
    end
  end
end
