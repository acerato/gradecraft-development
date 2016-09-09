require "rails_spec_helper"

describe SubmissionFilesController do
  let(:course) { Course.last }
  let(:student) { User.last }
  let(:submission_file) { create(:submission_file) }
  let(:submission) { submission_file.submission }
  let(:ability) { Object.new.extend(CanCan::Ability) }
  let(:presenter_class) { Presenters::SubmissionFiles::Base }

  before do
    create(:course)
    create(:user)
  end

  before(:each) do
    session[:course_id] = course.id
  end

  context "user is authorized" do
    let(:course_membership) { CourseMembership.last }
    let(:params) { { submission_file_id: submission_file.id, index: 20 } }

    before do
      create(:course_membership,
        user: student,
        course: course,
        role: "student"
      )
    end

    before(:each) do
      login_user student
    end

    describe "#presenter" do
      let(:result) { controller.presenter }

      it "builds a new presenter_class with the params" do
        allow(controller).to receive(:params) { params }
        expect(presenter_class).to receive(:new).with params: params
        result
      end

      it "caches the presenter" do
        result
        expect(presenter_class).not_to receive :new
        result
      end

      it "sets the presenter to @presenter" do
        presenter_double = double(presenter_class)
        allow(presenter_class).to receive(:new) { presenter_double }
        result
        expect(controller.instance_variable_get(:@presenter))
          .to eq presenter_double
      end
    end

    describe "GET download" do
      let(:result) { get :download, params.merge(format: "html") }
      let(:presenter) { presenter_class.new params }

      before do
        allow(controller).to receive_messages(
          presenter: presenter,
          current_ability: ability
        )

        allow(presenter).to receive_messages(
          submission_file_streamable?: true,
          submission: submission,
          submission_file: submission_file
        )

        request.env["HTTP_REFERER"] = "http://some-referrer.com"
      end

      context "user is authorized to download the submission" do
        before { ability.can :download, submission_file }
        let(:send_data_options) { ["some_data", { filename: "stuff.xyz" }] }

        context "the submission file is streamable" do
          it "streams the submission file with the filename" do
            allow(presenter).to receive(:send_data_options) { send_data_options }
            expect(controller).to receive(:send_data).with(*send_data_options) do
              # expressly render nothing so that the controller doesn't attempt
              # to render the template
              controller.render nothing: true
            end
            result
          end
        end

        context "the submission file is not streamable" do
          before do
            allow(presenter).to receive(:submission_file_streamable?) { false }
          end

          it "marks the submission_file_missing" do
            expect(presenter).to receive(:mark_submission_file_missing)
            result
          end

          it "returns a flash alert saying the file was not found" do
            result
            expect(controller.flash[:alert])
              .to match(/requested file was not found/)
          end

          it "redirects to the referrer" do
            result
            expect(response).to redirect_to "http://some-referrer.com"
          end
        end
      end

      context "user is not authorized to read the submission" do
        before { ability.cannot :download, submission_file }

        it "raises an Access Denied error" do
          expect { result }.to raise_error(CanCan::AccessDenied)
        end
      end
    end
  end
end
