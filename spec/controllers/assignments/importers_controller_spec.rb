require "rails_spec_helper"
require "./app/services/imports_lms_assignments"

describe Assignments::ImportersController do
  let(:course) { create :course }
  let(:professor) { professor_membership.user }
  let(:professor_membership) { create :professor_course_membership, course: course }
  let(:provider) { :canvas }

  before { allow(controller).to receive(:current_course).and_return course }

  describe "GET courses" do
    context "as a professor" do
      before { login_user(professor) }

      context "without an existing authentication" do
        it "redirects to authorize with canvas" do
          get :courses, importer_provider_id: provider

          expect(response).to redirect_to "/auth/canvas"
        end
      end

      context "with an expired authentication" do
        let(:access_token) { "BLAH" }
        let!(:user_authorization) do
          create :user_authorization, :canvas, user: professor, access_token: access_token,
            expires_at: 2.days.ago
        end

        it "retrieves a refresh token" do
          allow_any_instance_of(ActiveLMS::Syllabus).to receive(:courses).and_return []
          expect_any_instance_of(UserAuthorization).to receive(:refresh!)

          get :courses, importer_provider_id: provider
        end
      end
    end
  end

  describe "POST assignments_import" do
    let(:course_id) { "COURSE_ID" }

    context "as a professor" do
      let(:access_token) { "BLAH" }
      let(:assignment_ids) { ["123", "456"] }
      let(:assignment_type) { create :assignment_type }
      let(:result) { double(:result, success?: true, message: "") }
      let!(:user_authorization) do
        create :user_authorization, :canvas, user: professor, access_token: access_token,
          expires_at: 2.days.from_now
      end

      before do
        login_user(professor)
        allow(Services::ImportsLMSAssignments).to receive(:import).and_return result
      end

      it "imports the selected assignments" do
        expect(Services::ImportsLMSAssignments).to \
          receive(:import).with(provider.to_s, access_token, course_id,
                                assignment_ids, course, assignment_type.id.to_s)
                          .and_return result

        post :assignments_import, importer_provider_id: provider, id: course_id,
          assignment_ids: assignment_ids, assignment_type_id: assignment_type.id
      end

      it "renders the results" do
        post :assignments_import, importer_provider_id: provider, id: course_id,
          assignment_ids: assignment_ids, assignment_type_id: assignment_type.id

        expect(response).to render_template :assignments_import_results
      end

      context "with an invalid request" do
        it "re-renders the template with the error" do
          allow(result).to receive(:success?).and_return false
          syllabus = double(course: {}, assignments: [])
          allow(controller).to receive(:syllabus).and_return syllabus

          post :assignments_import, importer_provider_id: provider, id: course_id,
            assignment_ids: assignment_ids, assignment_type_id: assignment_type.id

          expect(response).to render_template :assignments
        end
      end
    end

    context "as a student" do
      it "redirects to the root url" do
        post :assignments_import, importer_provider_id: provider, id: course_id

        expect(response).to redirect_to root_path
      end
    end
  end

  describe "POST #refresh_assignment" do
    let(:assignment) { create :assignment, course: course }

    context "as a professor" do
      let(:access_token) { "BLAH" }
      let(:result) { double(:result, success?: true, message: "") }
      let!(:user_authorization) do
        create :user_authorization, :canvas, user: professor, access_token: access_token,
          expires_at: 2.days.from_now
      end

      before { login_user(professor) }

      it "updates the assignment from the provider details" do
        expect(Services::ImportsLMSAssignments).to \
          receive(:refresh).with(provider.to_s, access_token, assignment).and_return result

        post :refresh_assignment, importer_provider_id: provider, id: assignment.id
      end

      it "redirects back to the assignment show view and displays a notice" do
        allow(Services::ImportsLMSAssignments).to receive(:refresh).and_return result

        post :refresh_assignment, importer_provider_id: provider, id: assignment.id

        expect(response).to redirect_to(assignment_path(assignment))
        expect(flash[:notice]).to \
          eq "You have successfully updated #{assignment.name} from Canvas"
      end

      context "for an assignment that was not imported" do
        it "redirects back to the assignment show view and displays an alert" do
          allow(result).to receive_messages(success?: false,
                                            message: "This was not imported")
          allow(Services::ImportsLMSAssignments).to receive(:refresh).and_return result

          post :refresh_assignment, importer_provider_id: provider, id: assignment.id

          expect(response).to redirect_to(assignment_path(assignment))
          expect(flash[:alert]).to eq "This was not imported"
        end
      end
    end

    context "as a student" do
      it "redirects to the root url" do
        post :refresh_assignment, importer_provider_id: provider, id: assignment.id

        expect(response).to redirect_to root_path
      end
    end
  end

  describe "POST #update_assignment" do
    let(:assignment) { create :assignment, course: course }

    context "as a professor" do
      let(:access_token) { "BLAH" }
      let(:result) { double(:result, success?: true, message: "") }
      let!(:user_authorization) do
        create :user_authorization, :canvas, user: professor, access_token: access_token,
          expires_at: 2.days.from_now
      end

      before { login_user(professor) }

      it "updates the canvas assignment from the assignment details" do
        expect(Services::ImportsLMSAssignments).to \
          receive(:update).with(provider.to_s, access_token, assignment).and_return result

        post :update_assignment, importer_provider_id: provider, id: assignment.id
      end

      it "redirects back to the assignment show view and displays a notice" do
        allow(Services::ImportsLMSAssignments).to receive(:update).and_return result

        post :update_assignment, importer_provider_id: provider, id: assignment.id

        expect(response).to redirect_to(assignment_path(assignment))
        expect(flash[:notice]).to \
          eq "You have successfully updated #{assignment.name} on Canvas"
      end

      context "for an assignment that was not imported" do
        it "redirects back to the assignment show view and displays an alert" do
          allow(result).to receive_messages(success?: false,
                                            message: "This was not updated")
          allow(Services::ImportsLMSAssignments).to receive(:update).and_return result

          post :update_assignment, importer_provider_id: provider, id: assignment.id

          expect(response).to redirect_to(assignment_path(assignment))
          expect(flash[:alert]).to eq "This was not updated"
        end
      end
    end

    context "as a student" do
      it "redirects to the root url" do
        post :update_assignment, importer_provider_id: provider, id: assignment.id

        expect(response).to redirect_to root_path
      end
    end
  end
end
