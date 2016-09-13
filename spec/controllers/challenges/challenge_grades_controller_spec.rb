require "rails_spec_helper"

describe Challenges::ChallengeGradesController do

  let(:world) { World.create.with(:course, :student) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }
  let(:team) { world.create_team.team }
  let(:challenge) { world.create_challenge.challenge }

  context "as professor" do

    before(:each) do
      @challenge_grade = create(:challenge_grade, team: team, challenge: challenge)
      login_user(professor)
    end

    describe "GET new" do
      it "shows the new challenge grade form" do
        get :new, params: { challenge_id: challenge, team_id: team }
        expect(assigns(:challenge)).to eq(challenge)
        expect(assigns(:team)).to eq(team)
        expect(response).to render_template(:new)
      end
    end

    describe "POST create" do
      it "creates the challenge grade with valid attributes and redirects to the challenge show page" do
        team2 = create(:team, course: world.course )
        params = attributes_for(:challenge_grade)
        params[:score] = "101"
        params[:challenge_id] = challenge.id
        params[:team_id] = team2.id
        params[:status] = "Released"
        post :create, params: { challenge_id: challenge.id, challenge_grade: params }
        expect(challenge.challenge_grades.where(:team_id => team2.id).first.score).to eq(101)
        expect(response).to redirect_to(challenge)
      end

      it "redirects to new form with invalid attributes" do
        expect{ post :create,
                params: { challenge_id: challenge.id,
                          challenge_grade: attributes_for(:challenge_grade, team_id: nil) }}
          .to_not change(ChallengeGrade,:count)
      end
    end


    describe "GET mass_edit" do
      it "assigns params" do
        get :mass_edit, params: { challenge_id: challenge.id }
        expect(response).to render_template(:mass_edit)
      end
    end

    describe "POST mass_update" do
      it "updates the challenge grades for the specific challenge" do
        challenge_grades_attributes = { "#{challenge.challenge_grades.to_a.index(@challenge_grade)}" =>
          { team_id: team.id, score: 1000, status: "Released",
            id: @challenge_grade.id
          }
        }
        put :mass_update, params: { challenge_id: challenge.id,
          challenge: { challenge_grades_attributes: challenge_grades_attributes }}
        expect(@challenge_grade.reload.score).to eq 1000
      end

      it "redirects to the mass_edit form if attributes are invalid" do
        challenge_grades_attributes = { "#{challenge.challenge_grades.to_a.index(@challenge_grade)}" =>
          { team_id: nil, score: 1000, status: "Released",
            id: @challenge_grade.id
          }
        }
        put :mass_update, params: { challenge_id: challenge.id,
          challenge: { challenge_grades_attributes: challenge_grades_attributes }}
        expect(response).to render_template(:mass_edit)
      end
    end

    describe "GET edit_status" do
      it "displays the edit_status page" do
        get :edit_status, params: { challenge_id: challenge.id, challenge_grade_ids: [ @challenge_grade.id ] }
        expect(response).to render_template(:edit_status)
      end
    end

    describe "POST update_status" do
      it "updates the status of multiple challenge grades" do
        post :update_status, params: { challenge_id: challenge.id, challenge_grade_ids: [ @challenge_grade.id ], challenge_grade: {"status"=> "Released"}}
        expect(response).to redirect_to challenge_path(challenge)
      end
    end
  end

  context "as student" do
    describe "protected routes" do
      [
        :new,
        :create
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route, params: { challenge_id: 2 }).to redirect_to(:root)
          end
        end
    end

    describe "protected routes requiring id in params" do
    [
      :mass_edit,
      :mass_update,
      :edit_status,
      :update_status
    ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, params: { challenge_id: 2, id: "1" }).to redirect_to(:root)
        end
      end
    end
  end
end
