require "rails_spec_helper"

include ResqueJobSharedExamplesToolkit

RSpec.describe InfoController, type: :controller, background_job: true do
  include InQueueHelper

  let(:course) { create(:course) }
  let(:course_membership_attributes) {{ user_id: professor.id, course_id: course.id }}
  let(:professor) { create(:user) }
  let(:enroll_professor) { CourseMembership.create(course_membership_attributes.merge(role: "professor")) }
  let(:job_attributes) { course_membership_attributes.merge(filename: "#{ course.name } Research Gradebook - #{ Date.today }.csv") }

  before do
    enroll_professor
    login_user(professor)
    session[:course_id] = course.id
  end

  before(:each) { ResqueSpec.reset! }

  describe "#research_gradebook" do
    subject { get :research_gradebook, params: { id: course.id }}

    it_behaves_like "a successful resque job", GradeExportJob
  end
end
