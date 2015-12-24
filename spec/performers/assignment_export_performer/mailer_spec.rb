require 'rails_spec_helper'

RSpec.describe AssignmentExportPerformer, type: :background_job do
  extend Toolkits::Performers::AssignmentExport::Context
  define_context

  subject { performer }

  describe "mailer outcomes" do
    describe "#deliver_outcome_mailer" do
      before(:each) { performer.instance_variable_set(:@check_s3_upload_success, nil) }
      subject { performer.instance_eval { deliver_outcome_mailer }}

      context "the s3 upload is successful" do
        before { allow(performer).to receive(:check_s3_upload_success) { true }}

        it "should deliver the success mailer" do
          expect(performer).to receive(:deliver_archive_success_mailer)
          subject
        end
      end

      context "the s3 upload failed" do
        before { allow(performer).to receive(:check_s3_upload_success) { false }}

        it "should deliver the failure mailer" do
          expect(performer).to receive(:deliver_archive_failed_mailer)
          subject
        end
      end
    end

    describe "#deliver_archive_success_mailer" do
      subject { performer.instance_eval { deliver_archive_success_mailer }}

      context "a @team is present" do
        before { performer.instance_variable_set(:@team, true) }

        it "should deliver the team success mailer" do
          expect(performer).to receive(:deliver_team_export_successful_mailer)
          subject
        end
      end

      context "no @team is present" do
        before { performer.instance_variable_set(:@team, false) }

        it "should deliver the non-team success mailer" do
          expect(performer).to receive(:deliver_export_successful_mailer)
          subject
        end
      end
    end

    describe "#deliver_archive_failed_mailer" do
      subject { performer.instance_eval { deliver_archive_failed_mailer }}

      context "a @team is present" do
        before { performer.instance_variable_set(:@team, true) }

        it "should deliver the team failure mailer" do
          expect(performer).to receive(:deliver_team_export_failure_mailer)
          subject
        end
      end

      context "no @team is present" do
        before { performer.instance_variable_set(:@team, false) }

        it "should deliver the non-team failure mailer" do
          expect(performer).to receive(:deliver_export_failure_mailer)
          subject
        end
      end
    end
  end

  describe "mailer methods" do
    let(:professor) { create(:user) }
    let(:assignment) { create(:assignment) }
    let(:team) { create(:team) }
    let(:archive_data) {{ format: "zip", url: "http://gc.com/exports-or-whatevs" }}
    let(:mailer_double) { double(:mailer_double) }

    before(:each) do
      performer.instance_variable_set(:@professor, professor)
      performer.instance_variable_set(:@assignment, assignment)
      performer.instance_variable_set(:@team, team)
      allow(performer).to receive(:archive_data) { archive_data }
      subject
    end

    describe "#deliver_export_successful_mailer" do
      subject { performer.instance_eval { deliver_export_successful_mailer }}
      before(:each) { allow(performer).to receive(:deliver_export_successful_mailer) { mailer_double }}

      it "creates an export success mailer" do
        expect(ExportsMailer).to receive(:submissions_export_success).with(professor, assignment, archive_data)
      end

      it "delivers the mailer" do
        expect(mailer_double).to receive(:deliver_now)
      end
    end

    describe "#deliver_team_export_successful_mailer" do
      subject { performer.instance_eval { deliver_team_export_successful_mailer }}
      before(:each) { allow(performer).to receive(:deliver_team_export_successful_mailer) { mailer_double }}


      it "delivers a team export success mailer" do
        expect(ExportsMailer).to receive(:team_submissions_export_successful).with(professor, assignment, team, archive_data)
      end

      it "delivers the mailer" do
        expect(mailer_double).to receive(:deliver_now)
      end
    end

    describe "#deliver_export_failure_mailer" do
      subject { performer.instance_eval { deliver_export_failure_mailer }}
      before(:each) { allow(performer).to receive(:deliver_export_failure_mailer) { mailer_double }}

      it "delivers an export failure mailer" do
        expect(ExportsMailer).to receive(:submissions_export_failure).with(professor, assignment, archive_data)
      end

      it "delivers the mailer" do
        expect(mailer_double).to receive(:deliver_now)
      end
    end

    describe "#deliver_team_export_failure_mailer" do
      subject { performer.instance_eval { deliver_team_export_failure_mailer }}
      before(:each) { allow(performer).to receive(:deliver_team_export_failure_mailer) { mailer_double }}

      it "delivers a team export failure mailer" do
        expect(ExportsMailer).to receive(:team_submissions_export_failure).with(professor, assignment, team, archive_data)
      end

      it "delivers the mailer" do
        expect(mailer_double).to receive(:deliver_now)
      end
    end
  end
end
