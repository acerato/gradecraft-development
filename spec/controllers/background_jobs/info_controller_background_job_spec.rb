require "rails_spec_helper"

RSpec.describe InfoController, type: :controller, background_job: true do
  include InQueueHelper

  let(:course) { create(:course) }
  let(:course_membership_attributes) {{ user_id: professor.id, course_id: course.id }}
  let(:enroll_professor) { CourseMembership.create(course_membership_attributes.merge(role: "professor")) }
  let(:job_attributes) { course_membership_attributes.merge(filename: "#{ course.name } Gradebook - #{ Date.today }.csv") }
  let(:professor) { create(:user) }

  before do
    enroll_professor
    login_user(professor)
    session[:course_id] = course.id
  end

  before(:each) { ResqueSpec.reset! }

  describe "#gradebook" do
    it "increases the queue size by one" do
      expect{ get :gradebook, params: { id: course.id }}.to \
        change { queue(GradebookExporterJob).size }.by(1)
    end

    it "queues the job" do
      get :gradebook, params: { id: course.id }
      expect(GradebookExporterJob).to have_queued(job_attributes)
    end

    it "creates calls #new on GradebookExporterJob" do
      expect(GradebookExporterJob).to respond_to(:new).with(1).argument
      get :gradebook, params: { id: course.id }
    end
  end
end
