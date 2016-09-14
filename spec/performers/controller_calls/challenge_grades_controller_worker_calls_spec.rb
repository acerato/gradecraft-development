require "rails_spec_helper"
require "set"

include ResqueJobSharedExamplesToolkit

RSpec.describe ChallengeGradesController, type: :controller, background_job: true do
  include InQueueHelper

  let(:world) { World.create.with(:course, :student) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }
  let(:team) { world.create_team.team }
  let(:challenge) { world.create_challenge.challenge }


  let(:challenge_grade) { create(:challenge_grade, team: team, challenge: challenge) }
  let(:job_attributes) {{ challenge_grade_id: challenge_grade.id }} # for ChallengeGradeUpdaterJob calls
  let(:challenge_grade_attributes) {{ team_id: team.id, challenge_id: challenge.id }}

  before(:each) { ResqueSpec.reset! }

  describe "triggering jobs as a professor" do
    before(:each) do
      login_user(professor)
    end

    describe "#update" do
      let(:params) { attributes_for(:challenge_grade).merge(challenge_id: challenge.id) }
      subject { post :update, params: { id: challenge_grade.id, challenge_grade: params }}

      before do
        allow(ChallengeGrade).to receive(:find_or_create).and_return challenge_grade
      end

      context "challenge grade attributes are successfully updated" do
        before { allow_any_instance_of(ChallengeGrade).to receive(:update_attributes) { true } }

        context "challenge grade is released" do
          let(:challenge_grade) { create(:released_challenge_grade, challenge_grade_attributes) }

          before do
            allow(challenge_grade).to receive(:is_released?) { true }
          end

          it_behaves_like "a successful resque job", ChallengeGradeUpdaterJob
        end

        context "challenge grade has not been released" do
          let(:challenge_grade) { create(:grades_not_released_challenge_grade, challenge_grade_attributes) }
          let(:job_class) { ChallengeGradeUpdaterJob }

          it "shouldn't build a new job" do
            subject
            expect(assigns(job_class.to_s.underscore.to_sym)).to eq(nil)
          end
        end
      end

      context "challenge grade attributes fail to update" do
        before { allow(challenge_grade).to receive(:update_attributes) { false } }

        it_behaves_like "a failed resque job", ChallengeGradeUpdaterJob
      end
    end

    describe "actions that trigger multiple ChallengeGradeUpdaterJob instances" do
      let(:student2) { create(:user) }
      let(:students) { [student, student2] }
      let(:challenge_grade2) { create(:challenge_grade, challenge_grade_attributes.merge(student_id: student2.id)) }
      let(:challenge_grades) { [challenge_grade, challenge_grade2] }
      let(:challenge_grade_ids) { [challenge_grade.id, challenge_grade2.id] }

      describe "PUT #update_status" do
        subject { put :update_status, params: request_attrs }
        before { enroll_and_login_professor }

        context "params[:file] is present" do
          let(:request_attrs) {{ id: challenge.id, challenge_grade_ids: challenge_grade_ids }}
          before { allow(controller).to receive_messages(update_status_grade_ids: grade_ids) }
        end
      end
    end
  end
end
