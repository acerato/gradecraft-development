require "light-service"
require_relative "updates_user/creates_course_membership"
require_relative "updates_user/updates_user"

module Services
  class UpdatesUser
    extend LightService::Organizer

    def self.update(attributes, course)
      with(attributes: attributes, course: course)
        .reduce(
          Actions::UpdatesUser,
          Actions::CreatesCourseMembership
        )
    end
  end
end
