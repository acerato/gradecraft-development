require "showtime"

module Presenters
  module CourseAnalyticsExports
    class Base < Showtime::Presenter
      def create_and_enqueue_export
        create_export && export_job.enqueue
      end

      def create_export
        @export = CourseAnalyticsExport.create \
          course_id: current_course.id,
          professor_id: current_user.id
      end

      def export_job
        @export_job ||= CourseAnalyticsExportJob.new \
          course_analytics_export_id: @export.id
      end

      def export
        @export ||= CourseAnaltyicsExport.find params[:id]
      end

      def destroy_export
        return export.destroy if export.delete_object_from_s3
        false
      end

      def course
        @course ||= current_course
      end

      def stream_export
        export.stream_s3_object_body
      end

      def export_filename
        export.export_filename
      end
    end
  end
end
