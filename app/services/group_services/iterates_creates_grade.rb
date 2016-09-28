require_relative "../creates_grade"

module Services
  module Actions
    class IteratesCreatesGrade
      extend LightService::Action

      expects :attributes, :group

      executed do |context|
        group = context.group

        group.students.each do |student|
          params = context[:attributes].deep_dup
          params["student_id"] = student.id
          params["group_id"] = group.id
          context.add_to_context Services::CreatesGrade.create(params)
        end
      end
    end
  end
end
