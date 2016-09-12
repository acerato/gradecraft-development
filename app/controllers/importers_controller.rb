require_relative "../services/imports_lms_assignments"

class ImportersController < ApplicationController
  before_action :ensure_staff?
  before_action :require_authorization, except: :index

  # GET /importers
  def index
  end

  # GET /importers/:importer_id/courses
  def courses
    @provider = params[:importer_id]
    @courses = syllabus.courses
  end

  # GET /importers/:importer_id/courses/:id/assignments
  def assignments
    @provider = params[:importer_id]
    @course = syllabus.course(params[:id])
    @assignments = syllabus.assignments(params[:id])
    @assignment_types = current_course.assignment_types.ordered
  end

  # POST /importers/:importer_id/courses/:id/assignments
  def assignments_import
    @provider = params[:importer_id]

    @result = Services::ImportsLMSAssignments.import @provider,
      authorization(@provider).access_token, params[:id], params[:assignment_ids],
      current_course, params[:assignment_type_id]

    if @result.success?
      render :assignments_import_results
    else
      @course = syllabus.course(params[:id])
      @assignments = syllabus.assignments(params[:id])
      @assignment_types = current_course.assignment_types.ordered

      render :assignments, alert: @result.message
    end
  end

  private

  def require_authorization
    provider = params[:importer_id]
    require_authorization_with provider
  end

  def require_authorization_with(provider)
    auth = authorization(provider)

    if auth.nil?
      session[:return_to] = importer_courses_path(provider)
      redirect_to "/auth/#{provider}"
    elsif auth.expired?
      config = ActiveLMS.configuration.providers[provider.to_sym]
      auth.refresh_with_config! config
    end
  end

  def authorization(provider)
    UserAuthorization.for(current_user, provider)
  end

  def syllabus
    @syllabus ||= ActiveLMS::Syllabus.new(@provider, authorization(@provider).access_token)
  end
end
