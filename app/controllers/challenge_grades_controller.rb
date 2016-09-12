class ChallengeGradesController < ApplicationController

  before_action :ensure_staff?, except: [:show]
  before_action :find_challenge_grade
  before_action :find_challenge

  # GET /challenge_grades/:id
  def show
    @team = @challenge_grade.team
  end

  # GET /challenge_grades/:id/edit
  def edit
    @team = @challenge_grade.team
  end

  # POST /challenges_grades/:id
  def update
    @team = @challenge_grade.team
    if @challenge_grade.update_attributes(challenge_grade_params)

      if ChallengeGradeProctor.new(@challenge_grade).viewable?
        ChallengeGradeUpdaterJob.new(challenge_grade_id: @challenge_grade.id).enqueue
      end

      redirect_to challenge_path(@challenge),
        notice: "#{@team.name}'s Grade for #{@challenge.name} #{(term_for :challenge).titleize} successfully updated"
    else
      render action: "edit"
    end
  end

  # DELETE /challenge_grades/:id
  # May be worth it to pull this into a service
  def destroy
    @team = @challenge_grade.team

    @challenge_grade.destroy
    @team.challenge_grade_score
    @team.students.collect do |student|
      ScoreRecalculatorJob.new(user_id: student.id, course_id: current_course.id)
    end.each(&:enqueue)
    @team.average_score

    redirect_to challenge_path(@challenge),
      notice: "#{@team.name}'s grade for #{@challenge.name} has been successfully deleted."
  end

  private

  def challenge_grade_params
    params.require(:challenge_grade).permit :name, :score, :status, :challenge_id, :feedback,
      :team_id, :final_points
  end

  def find_challenge
    find_challenge_grade
    @challenge ||= @challenge_grade.challenge
  end

  def find_challenge_grade
    @challenge_grade ||= current_course.challenge_grades.find(params[:id])
  end
end
