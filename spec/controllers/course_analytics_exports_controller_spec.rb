require "rails_spec_helper"
require "./app/presenters/course_analytics_exports/base"

RSpec.describe CourseAnalyticsExportsController, type: :controller do

  let(:course) { create(:course) }
  let(:professor) { create(:professor_course_membership, course: course).user }
  let(:course_analytics_export) { create(:course_analytics_export, course: course) }

  let(:presenter) { double(presenter_class).as_null_object }
  let(:presenter_class) { ::Presenters::CourseAnalyticsExports::Base }

  before do
    login_user professor

    allow(controller).to receive_messages \
      current_course: course,
      current_user: professor,
      presenter: presenter

    allow(presenter).to receive(:resource_name) { "course analytics export" }
  end

  describe "POST #create" do
    subject { post :create, params: { course_id: course.id }}

    context "the presenter successfully creates and enqueues the export" do
      it "sets the job success flash message" do
        allow(presenter).to receive(:create_and_enqueue_export) { true }
        subject
        expect(flash[:success]).to match(/Your course analytics export is being prepared/)
      end
    end

    context "the presenter failes to create and enqueue the export" do
      it "sets the job failure flash message" do
        allow(presenter).to receive(:create_and_enqueue_export) { false }
        subject
        expect(flash[:alert]).to match(/Your course analytics export failed to build/)
      end
    end

    it "redirects to course data exports page" do
      allow(presenter).to receive(:create_and_enqueue_export) { true }
      subject
      expect(response).to redirect_to(downloads_path)
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, params: { id: course_analytics_export.id }}

    context "the export is successfully destroyed" do
      it "notifies the user of success" do
        allow(presenter).to receive(:destroy_export) { true }
        subject
        expect(flash[:success]).to match(/Course analytics export successfully deleted/)
      end
    end

    context "the export is not destroyed" do
      it "notifies the user of the failure" do
        allow(presenter).to receive(:destroy_export) { false }
        subject
        expect(flash[:alert]).to match(/Unable to delete the course analytics export/)
      end
    end

    it "redirects to the exports path" do
      subject
      expect(response).to redirect_to(downloads_path)
    end
  end

  describe "GET #download" do
    let(:result) { get :download, params: { id: course_analytics_export.id }}

    before do
      allow(presenter).to receive(:send_data_options) { ["options"] }
    end

    it "streams the s3 object to the client" do
      expect(controller).to receive(:send_data).with "options" do
        # expressly render nothing so that the controller doesn't attempt
        # to render the template
        controller.render head: :ok, body: nil
      end

      result
    end
  end

  describe "secure downloads" do
    let(:secure_token) { create(:secure_token, target: course_analytics_export) }

    let(:secure_download_params) do
      {
        secure_token_uuid: secure_token.uuid,
        secret_key: secure_token.random_secret_key,
        id: course_analytics_export.id
      }
    end

    describe "GET #secure_download" do
      let(:result) { get :secure_download, params: secure_download_params }

      before do
        allow(presenter).to receive(:send_data_options) { ["options"] }
      end

      context "the secure download authenticates" do
        before do
          allow(presenter)
            .to receive(:secure_download_authenticates?) { true }
        end

        it "streams the s3 object to the client" do
          expect(controller).to receive(:send_data).with "options" do
            # expressly render nothing so that the controller doesn't attempt
            # to render the template
            controller.render head: :ok, body: nil
          end

          result
        end
      end

      context "the secure download doesn't authenticate" do
        before do
          allow(presenter)
            .to receive(:secure_download_authenticates?) { false }
        end

        context "the request was for a valid token that has expired" do
          it "alerts the user that their token has expired" do
            allow(presenter).to receive(:secure_token_expired?) { true }
            result
            expect(flash[:alert]).to match /email link.*expired/
          end
        end

        context "the request completely failed to authenticate" do
          it "alerts the user that their request was invalid" do
            allow(presenter).to receive(:secure_token_expired?) { false }
            result
            expect(flash[:alert]).to match /The email link you used has expired/
          end
        end

        it "redirects the user to the root page and tells them to log in" do
          result
          expect(flash[:alert]).to match /Please login/
          expect(response).to redirect_to root_path
        end
      end

      describe "skipped filters" do
        let(:result) { get :secure_download, params: secure_download_params }

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

    # let's test the presenter just to make sure that it builds and we don't
    # have any requirement or namespacing issues
    #
    describe "#presenter" do
      context "no @presenter has been built" do
        before(:each) do
          allow(controller).to receive(:presenter).and_call_original
          controller.instance_variable_set :@presenter, nil
        end

        it "builds a new presenter with the params, course and user" do
          expect(presenter_class).to receive(:new).with \
            params: controller.params,
            current_course: course,
            current_user: professor

          subject.instance_eval { presenter }
        end
      end
    end

  end
end
