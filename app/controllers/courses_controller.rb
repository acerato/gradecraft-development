# rubocop:disable AndOr
class CoursesController < ApplicationController
  include CoursesHelper

  skip_before_action :require_login, only: [:badges]
  before_action :ensure_staff?, except: [:index, :badges, :change]
  before_action :ensure_not_impersonating?, only: [:index]
  before_action :find_course, only: [:show,
                                     :edit,
                                     :copy,
                                     :update,
                                     :destroy,
                                     :badges]
  before_action :use_current_course, only: [:course_details,
                                            :custom_terms,
                                            :multiplier_settings,
                                            :player_settings,
                                            :student_onboarding_setup]
  skip_before_action :verify_authenticity_token, only: [:change]
  before_action :ensure_not_impersonating?, only: [:change]

  def index
    @courses = current_user.courses
    # Used to return the course list to search
    respond_to do |format|
      format.html
      format.json do
        render json: @courses.to_json(only: [:id, :name, :course_number, :year, :semester])
      end
    end
  end

  def show
    authorize! :read, @course
  end

  def new
    @course = Course.new
  end

  def edit
    authorize! :update, @course
  end

  def create
    @course = Course.new(course_params)
    respond_to do |format|
      if @course.save
        if !current_user_is_admin?
          @course.course_memberships.create(user_id: current_user.id,
                                            role: current_user.role(current_course))
        end
        session[:course_id] = @course.id
        bust_course_list_cache current_user
        format.html do
          redirect_to course_path(@course),
          notice: "Course #{@course.name} successfully created"
        end
      else
        format.html { render action: "new" }
      end
    end
  end

  def copy
    authorize! :read, @course
    duplicated = @course.copy(params[:copy_type], {})
    if duplicated.save
      if !current_user_is_admin? && current_user.role(duplicated).nil?
        duplicated.course_memberships.create(user: current_user, role: current_role)
      end
      duplicated.recalculate_student_scores unless duplicated.student_count.zero?
      session[:course_id] = duplicated.id
      redirect_to edit_course_path(duplicated.id),
        notice: "#{@course.name} successfully copied" and return
    else
      redirect_to courses_path,
        alert: "#{@course.name} was not successfully copied" and return
    end
  end

  def update
    authorize! :update, @course
    respond_to do |format|
      if @course.update_attributes(course_params)
        bust_course_list_cache current_user
        format.html do
          redirect_to @course,
          notice: "Course #{@course.name} successfully updated"
        end
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy
    authorize! :destroy, @course
    @name = @course.name
    @course.destroy
    redirect_to courses_url, notice: "Course #{@name} successfully deleted"
  end

  # Switch between enrolled courses
  def change
    if course = current_user.courses.where(id: params[:id]).first
      authorize! :read, course
      unless session[:course_id] == course.id
        session[:course_id] = CourseRouter.change!(current_user, course).id
        record_course_login_event course: course
      end
    end
    redirect_to root_url
  end

  def course_creation_wizard
  end

  def badges
    if @course.has_public_badges?
      @title = @course.name
      @badges = @course.badges
    else
      redirect_to root_path, alert: "Whoops, nothing to see here! That data is not available."
    end
  end

  def course_details
  end

  def custom_terms
  end

  def multiplier_settings
  end

  def player_settings
  end

  def student_onboarding_setup
  end

  private

  def course_params
    params.require(:course).permit :course_number, :name,
      :semester, :year, :has_badges, :has_teams, :instructors_of_record_ids,
      :team_term, :student_term, :section_leader_term, :group_term, :lti_uid,
      :user_id, :course_id, :course_rules, :syllabus,
      :has_character_names, :has_team_roles, :has_character_profiles, :hide_analytics,
      :total_weights, :weights_close_at, :has_public_badges,
      :assignment_weight_type, :has_submissions, :teams_visible,
      :weight_term, :fail_term, :pass_term, :time_zone,
      :max_weights_per_assignment_type, :assignments,
      :accepts_submissions, :tagline, :office, :phone,
      :class_email, :twitter_handle, :twitter_hashtag, :location, :office_hours,
      :meeting_times, :assignment_term, :challenge_term, :badge_term, :gameful_philosophy,
      :team_score_average, :has_team_challenges, :team_leader_term,
      :max_assignment_types_weighted, :full_points, :has_in_team_leaderboards,
      :grade_scheme_elements_attributes, :add_team_score_to_student, :status,
      :assignments_attributes, :start_date, :end_date,
      unlock_conditions_attributes: [:id, :unlockable_id, :unlockable_type, :condition_id,
        :condition_type, :condition_state, :condition_value, :condition_date, :_destroy],
      instructors_of_record_ids: [], course_memberships_attributes: [:id, :course_id, :user_id, :instructor_of_record]
  end

  def find_course
    @course = Course.find(params[:id])
  end

  def use_current_course
    @course = current_course
    authorize! :update, @course
  end
end
