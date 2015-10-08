class GradebookExportPerformer < ResqueJob::Performer
  def setup
    @user = fetch_user
    @course = fetch_course
  end

  # perform() attributes assigned to @attrs in the ResqueJob::Base class
  def do_the_work
    if @course.present? and @user.present?
      require_success(export_messages) do
        fetch_csv_data
        notify_gradebook_export # the result of this block determines the outcome
      end
    end
  end

  private
  
  def fetch_user
    User.find @attrs[:user_id]
  end

  def fetch_course
    Course.find @attrs[:course_id]
  end

  def fetch_csv_data
    @csv_data = @course.gradebook_for_course(@course)
  end

  def notify_gradebook_export
    NotificationMailer.gradebook_export(@course, @user, @csv_data).deliver_now
  end

  def export_messages
    { success: "Gradebook export notification mailer was successfully delivered.",
      failure: "Gradebook export notification mailer was not delivered." }
  end
end

class GradebookExporterJob < ResqueJob::Base
  @queue = :gradebook_exporter 
  @performer_class = GradebookExportPerformer
end
