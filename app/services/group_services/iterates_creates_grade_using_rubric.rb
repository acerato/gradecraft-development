require_relative "../creates_grade_using_rubric"

module Services
  module Actions
    class IteratesCreatesGradeUsingRubric
      extend LightService::Action

      expects :raw_params
      expects :graded_by_id
      expects :group

      executed do |context|
        graded_by_id = context.graded_by_id
        group = context.group

        group.students.each do |student|
          params = context[:raw_params].deep_dup
          params["student_id"] = student.id
          params["group_id"] = group.id
          context.add_to_context Services::CreatesGradeUsingRubric.create(params, graded_by_id)
        end
      end
    end
  end
end
