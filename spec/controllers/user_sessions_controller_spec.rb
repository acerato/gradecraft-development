require 'rails_spec_helper'

describe UserSessionsController do
  let(:world) { World.create.with(:course, :student) }
  let(:student) { world.student}
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  describe "POST create" do
    context "user is successfully logged in" do
      it "records the course login event" do
        allow(subject).to receive(:login) { student }
        expect(subject).to receive(:record_course_login_event)
        post :create, params: { user: student.attributes }
      end
    end

    context "user is not logged in" do
      it "does not record the course login event" do
        allow(subject).to receive(:login) { nil }
        expect(subject).to_not receive(:record_course_login_event)
        post :create, params: { user: student.attributes }
      end
    end
  end

  describe "impersonate_student" do
    before do
      allow(subject).to receive(:current_course) { world.course }
    end

    it "stores the professor id in sessions" do
      login_user(professor)
      get :impersonate_student, params: { student_id: student.id }
      expect(session[:impersonating_agent_id]).to eq(professor.id)
    end

    it "logs in as student" do
      login_user(professor)
      get :impersonate_student, params: { student_id: student.id }
      expect(session[:user_id]).to eq(student.id.to_s)
    end
  end

  describe "exit_student_impersonation" do

    it "returns session to faculty" do
      allow(subject).to receive(:login) { student }
      session[:impersonating_agent_id] = professor.id
      get :exit_student_impersonation
      expect(session[:impersonating_agent_id]).to be_nil
      expect(session[:user_id]).to eq(professor.id.to_s)
    end
  end
end
