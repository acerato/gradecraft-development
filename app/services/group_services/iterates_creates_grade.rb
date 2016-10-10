require_relative "../creates_grade"

module Services
  module Actions
    class IteratesCreatesGrade
      extend LightService::Action

      expects :attributes
      expects :group
      expects :graded_by_id

      executed do |context|
        group = context.group
        graded_by_id = context.graded_by_id

        group.students.each do |student|
          params = context[:attributes].deep_dup
          params["student_id"] = student.id
          params["group_id"] = group.id
          context.add_to_context Services::CreatesGrade.create(params, graded_by_id)
        end
      end
    end
  end
end
