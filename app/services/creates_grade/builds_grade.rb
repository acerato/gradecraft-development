module Services
  module Actions
    class BuildsGrade
      extend LightService::Action

      expects :attributes
      expects :student
      expects :assignment
      expects :grading_agent

      promises :grade

      executed do |context|
        grade = Grade.find_or_create(context[:assignment].id,context[:student].id)
        grade.full_points = context[:assignment].full_points
        grade.graded_by_id = context[:grading_agent].id
        grade.assign_attributes context[:attributes]["grade"]
        grade.group_id = context[:attributes]["group_id"] if context[:attributes]["group_id"]
        context[:grade] = grade
      end
    end
  end
end
