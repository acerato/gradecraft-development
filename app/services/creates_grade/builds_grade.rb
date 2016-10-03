module Services
  module Actions
    class BuildsGrade
      extend LightService::Action

      expects :attributes
      expects :student
      expects :assignment

      promises :grade

      executed do |context|
        grade = Grade.find_or_create(context[:assignment].id,context[:student].id)
        grade.full_points = context[:assignment].full_points
        grade.group_id = context[:attributes]["group_id"] if context[:attributes]["group_id"]
        update_grade_attributes grade, context[:attributes]["grade"]
        context[:grade] = grade
      end

      private

      # Updates the given attributes on the grade
      # Ideally this will be replaced by grade.assign_attributes context[:attributes]["grade"]
      # once we have identified and permitted all inputs as strong params
      def self.update_grade_attributes(grade, attributes)
        attributes.each_pair do |key, value|
          method = "#{key}="
          grade.send method, value if grade.respond_to? method
        end
      end
    end
  end
end
