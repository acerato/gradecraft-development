require "light-service"
require_relative "imports_lms_grades/imports_lms_grades"
require_relative "imports_lms_grades/imports_lms_users"
require_relative "imports_lms_grades/retrieves_lms_grades"
require_relative "imports_lms_grades/retrieves_lms_users"

module Services
  class ImportsLMSGrades
    extend LightService::Organizer

    def self.import(provider, access_token, course_id, assignment_ids, grade_ids,
                    assignment, user)
      with(provider: provider, access_token: access_token, course_id: course_id,
           assignment_ids: assignment_ids, grade_ids: grade_ids,
           assignment: assignment, course: assignment.course, user: user).reduce(
             Actions::RetrievesLMSGrades,
             Actions::RetrievesLMSUsers,
             Actions::ImportsLMSUsers,
             Actions::ImportsLMSGrades)
    end
  end
end
