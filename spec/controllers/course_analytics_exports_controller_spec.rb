require "rails_spec_helper"

RSpec.describe CourseAnalyticsExportsController, type: :controller do

  let(:course) { create(:course) }
  let(:professor) { create(:professor, course: course) }

  let(:course_analytics_export) do
    create(:course_analytics_export, course: course)
  end

  let(:course_analytics_exports) do
    create_list(:course_analytics_export, 2, course: course)
  end

  let(:presenter_class) { Presenters::CourseAnalyticsExports::Base }

  before do
    login_user professor
    allow(controller).to receive_messages \
      current_course: course,
      current_user: professor,
      presenter: presenter
  end

  describe "POST #create" do
    subject { post :create, course_id: course.id }

    context "the presenter successfully creates and enqueues the export" do
      it "sets the job success flash message" do
        subject
        expect(flash[:success]).to match(/Your course analytics export is being prepared/)
      end
    end

    context "the presenter failes to create and enqueue the export" do
      it "sets the job failure flash message" do
        subject
        expect(flash[:alert]).to match(/Your course analytics export failed to build/)
      end
    end

    it "redirects to the assignment page for the given assignment" do
      subject
      expect(response).to redirect_to(assignment_path(assignment))
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, id: course_analytics_export.id }

    context "the export is successfully destroyed" do
      it "notifies the user of success" do
        allow_any_instance_of(presenter_class).to receive(:destroy_export) { true }
        subject
        expect(flash[:success]).to match(/Assignment export successfully deleted/)
      end
    end

    context "the export is not destroyed" do
      it "notifies the user of the failure" do
        allow_any_instance_of(presenter_class).to receive(:destroy_export) { false }
        subject
        expect(flash[:alert]).to match(/Unable to delete the course analytics export/)
      end
    end

    it "redirects to the exports path" do
      subject
      expect(response).to redirect_to(exports_path)
    end
  end

  describe "GET #download" do
    let(:result) { get :download, id: course_analytics_export.id }

    before do
      allow(controller.presenter).to receive_messages \
        stream_export: "some data", filename: "some_filename.txt"
    end

    it "streams the s3 object to the client" do
      expect(controller).to receive(:send_data)
        .with "some_data", filename: "some_filename.txt"
      result
    end
  end

  describe "secure downloads" do
    describe "GET #secure_download" do
      let(:result) { get :secure_download, secure_download_params }

      before do
        allow(controller.presenter).to receive_messages \
          stream_export: "some data", filename: "some_filename.txt"
      end

      context "the SecureDownloadAuthenticator authenticates" do
        before do
          allow(authenticator).to receive(:authenticates?) { true }
        end

        it "streams the s3 object to the client" do
          expect(controller).to receive(:stream_file_from_s3)
          result
        end
      end

      context "the SecureDownloadAuthenticator doesn't authenticate" do
        before do
          allow(authenticator).to receive(:authenticates?) { false }
        end

        context "the request was for a valid token that has expired" do
          it "alerts the user that their token has expired" do
            allow(authenticator).to receive(:valid_token_expired?) { true }
            result
            expect(flash[:alert]).to match /email link.*expired/
          end
        end

        context "the request completely failed to authenticate" do
          it "alerts the user that their request was invalid" do
            allow(authenticator).to receive(:valid_token_expired?) { false }
            result
            expect(flash[:alert]).to match /does not exist/
          end
        end

        it "redirects the user to the root page and tells them to log in" do
          result
          expect(flash[:alert]).to match /Please login/
          expect(response).to redirect_to root_path
        end
      end

      describe "skipped filters" do
        let(:result) { get :secure_download, secure_download_params }

        it "doesn't require login" do
          expect(controller).not_to receive(:require_login)
          result
        end

        it "doesn't increment the page views" do
          expect(controller).not_to receive(:increment_page_views)
          result
        end

        it "doesn't get course scores" do
          expect(controller).not_to receive(:course_scores)
          result
        end
      end
    end

  end
end
