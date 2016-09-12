class AnalyticsController < ApplicationController
  before_action :ensure_staff?
  before_action :set_granularity_and_range

  def students
    @title = "#{term_for :student} Analytics"
    @nonpredictors = current_course.nonpredictors
  end

  def staff
    @title = "#{term_for :team_leader} Analytics"
  end

  def all_events
    data = CourseEvent.data(@granularity, @range,
      { course_id: current_course.id }, { event_type: "_all" })
    render json: MultiJson.dump(data)
  end

  def role_events
    data = CourseRoleEvent.data(@granularity, @range, {
      course_id: current_course.id, role_group: params[:role_group]
    }, { event_type: "_all" })
    render json: MultiJson.dump(data)
  end

  def login_events
    data = CourseLogin.data(@granularity, @range, {
      course_id: current_course.id
      })

    # Only graph counts
    data[:lookup_keys] = ["{{t}}.count"]

    render json: MultiJson.dump(data)
  end

  def login_role_events
    data = CourseRoleLogin.data(@granularity, @range,
      {course_id: current_course.id, role_group: params[:role_group]})

    # Only graph counts
    data[:lookup_keys] = ["{{t}}.count"]

    render json: MultiJson.dump(data)
  end

  def all_pageview_events
    data = CoursePageview.data(@granularity, @range,
      {course_id: current_course.id}, {page: "_all"})

    render json: MultiJson.dump(data)
  end

  def all_role_pageview_events
    data = CourseRolePageview.data(@granularity, @range,
      {course_id: current_course.id, role_group: params[:role_group]},
      {page: "_all"})

    render json: MultiJson.dump(data)
  end

  def all_user_pageview_events
    user = current_course.students.find(params[:user_id])
    data = CourseUserPageview.data(@granularity, @range,
      {course_id: current_course.id, user_id: user.id},
      {page: "_all"})

    render json: MultiJson.dump(data)
  end

  def pageview_events
    data = CoursePagePageview.data(@granularity, @range,
      {course_id: current_course.id})
    data.decorate! { |result| result[:name] = result.page }

    render json: MultiJson.dump(data)
  end

  def role_pageview_events
    data = CourseRolePagePageview.data(@granularity, @range,
      {course_id: current_course.id, role_group: params[:role_group]})
    data.decorate! { |result| result[:name] = result.page }

    render json: MultiJson.dump(data)
  end

  def user_pageview_events
    user = current_course.students.find(params[:user_id])
    data = CourseUserPagePageview.data(@granularity, @range,
      {course_id: current_course.id, user_id: user.id})
    data.decorate! { |result| result[:name] = result.page }

    render json: MultiJson.dump(data)
  end

  private

  def set_granularity_and_range
    @granularity = :daily

    if current_course.start_date && current_course.end_date
      @range = (current_course.start_date..current_course.end_date)
    else
      @range = :past_year
    end
  end
end
