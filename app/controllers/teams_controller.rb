class TeamsController < ApplicationController
  respond_to :html, :json

  before_action :ensure_staff?, except: [:index]

  def index
    @teams = current_course.teams.order_by_rank.includes(:earned_badges)
    if current_user_is_student?
      @team = current_student.team_for_course(current_course)
    end
  end

  def show
    @team = current_course.teams.find(params[:id])
    @students = @team.students
    @challenges = current_course.challenges.chronological.alphabetical
  end

  def new
    @team =  current_course.teams.new
    @submit_message = "Create #{term_for :team}"
  end

  def create
    @team =  current_course.teams.new(team_params)
    @team.save
    respond_with @team, notice: "Team #{@team.name} successfully created"
  end

  def edit
    @team =  current_course.teams.find(params[:id])
    @submit_message = "Update #{term_for :team}"
  end

  def update
    @team = current_course.teams.find(params[:id])
    @team.update_attributes(team_params)
    respond_with @team, notice: "Team #{@team.name} successfully updated"
  end

  def destroy
    @team = current_course.teams.find(params[:id])
    @name = "#{@team.name}"
    @team.destroy
    respond_to do |format|
      format.html do
        redirect_to teams_url,
        notice: "#{(term_for :team).titleize} #{@name} successfully deleted"
      end
    end
  end

  private

  def team_params
    params.require(:team).permit :name, :course, :course_id, :average_score,
      :banner, :rank, :challenge_grade_score, student_ids: [], leader_ids: [],
      team_memberships_attributes: [:id, :student_id, :team_id, :_destroy],
      team_leaderships_attributes: [:id, :leader_id, :team_id, :_destroy]
  end
end
