require_relative "../creates_grade_using_rubric"

module Services
  module Actions
    class IteratesCreatesGradeUsingRubric
      extend LightService::Action

      expects :raw_params
      expects :grading_agent
      expects :group

      executed do |context|
        group = context.group

        group.students.each do |student|
          params = context[:raw_params].deep_dup
          params["student_id"] = student.id
          params["group_id"] = group.id
          context.add_to_context Services::CreatesGradeUsingRubric.create(params, context[:grading_agent])
        end
      end
    end
  end
end
