require "active_record_spec_helper"
require "./app/models/course_analytics_export"
require_relative "../../support/uni_mock/rails"

describe Export::Model do
  include UniMock::StubRails

  # test a class that is actually using this module
  describe CourseAnalyticsExport do
    subject { create :course_analytics_export }

    describe "#downloadable?" do
      let(:result) { subject.downloadable? }

      context "export has a last_export_completed_at time" do
        it "is downloadable" do
          subject.last_export_completed_at = Time.now
          expect(result).to be_truthy
        end
      end

      context "export doesn't have a last_export_completed_at time" do
        it "isn't download able" do
          subject.last_export_completed_at = nil
          expect(result).to be_falsey
        end
      end
    end

    describe "#update_export_completed_time" do
      let(:time_now) { Date.parse("Oct 20 1999").to_time }

      it "updates the last_export_completed_at time to now" do
        allow(Time).to receive(:now) { time_now }
        subject.update_export_completed_time
        expect(subject.last_export_completed_at).to eq(time_now)
      end
    end

    describe "#object_key_date" do
      it "formats the created_at date" do
        time_now = Date.parse("Oct 20 2020").to_time
        allow(subject).to receive(:filename_time) { time_now }
        expect(subject.object_key_date).to eq time_now.strftime("%F")
      end
    end

    describe "#object_key_microseconds" do
      it "formats the created_at time in microseconds" do
        time_now = Date.parse("Oct 20 2020").to_time
        allow(subject).to receive(:filename_time) { time_now }
        expect(subject.object_key_microseconds).to eq time_now.to_f.to_s.tr(".", "")
      end
    end

    describe "#update_export_completed_time" do
      let(:result) { subject.update_export_completed_time }
      let(:sometime) { Date.parse("Oct 20 1982").to_time }

      before { allow(Time).to receive(:now) { sometime } }

      it "calls update_attributes on the submissions export with the export time" do
        expect(subject).to receive(:update_attributes)
          .with(last_export_completed_at: sometime, last_completed_step: "complete")
        result
      end

      it "updates the last_export_completed_at timestamp to now" do
        result
        expect(subject.last_export_completed_at).to eq(sometime)
      end
    end

    describe "#filename_time" do
      context "subject has a created_at timestamp" do
        it "uses the created_at datetime" do
          # make sure there's no cached time to screw with us
          subject.instance_variable_set :@filename_time, nil
          expect(subject.filename_time).to eq subject.created_at
        end
      end

      context "export has not been created" do
        # note that this is being built instead of created
        subject { build :course_analytics_export }
        let(:right_now) { Date.parse("oct 20 2020").to_time }

        it "just uses right now if the export hasn't been created" do
          allow(Time).to receive(:now) { right_now }
          expect(subject.filename_time).to eq right_now
        end
      end
    end

    describe "#filename_timestamp" do
      let(:result) { subject.filename_timestamp }
      let(:filename_time) { Date.parse("Jan 20 1995").to_time }

      it "formats the filename time" do
        allow(subject).to receive(:filename_time) { filename_time }
        expect(result).to eq "1995-01-20 - 1200AM"
      end
    end

  end
end
