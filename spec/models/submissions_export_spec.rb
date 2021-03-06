require "active_record_spec_helper"
require "formatter"

RSpec.describe SubmissionsExport do
  subject { build :submissions_export }

  it "includes S3Manager::Rescource" do
    expect(subject).to respond_to :stream_s3_object_body
    expect(subject).to respond_to :rebuild_s3_object_key
  end

  it "includes Export::Model::ActiveRecord" do
    expect(subject).to respond_to :object_key_microseconds
  end

  describe "#generate_secure_token" do
    it "creates a new secure token with the export data" do
      token = subject.generate_secure_token
      expect(token.class).to eq SecureToken
      expect(token.user_id).to eq subject.professor.id
      expect(token.course_id).to eq subject.course.id
      expect(token.target).to eq subject
    end
  end

  describe "#s3_object_key_prefix" do
    before do
      allow(subject).to receive_messages \
        object_key_date: "some-date",
        object_key_microseconds: "12345",
        course_id: 99,
        assignment_id: 100
    end

    it "builds a path for the s3 object" do
      expect(subject.s3_object_key_prefix).to eq \
        "exports/courses/99/assignments/100/some-date/12345"
    end
  end

  describe "export_file_basename" do
    before(:each) do
      allow(subject).to receive_messages \
        archive_basename: "some_great_submissions",
        filename_timestamp: "2000-01-01 - 123AM"

      subject.instance_variable_set :@export_file_basename, nil
    end

    it "includes the fileized_assignment_name" do
      expect(subject.export_file_basename).to match /^some_great_submissions/
    end

    it "is appended with a YYYY-MM-DD formatted timestamp" do
      expect(subject.export_file_basename).to match /2000-01-01/
    end

    it "caches the filename" do
      subject.export_file_basename
      expect(subject).not_to receive :archive_basename
      subject.export_file_basename
    end

    it "sets the filename to an @export_file_basename" do
      subject.export_file_basename
      expect(subject.instance_variable_get :@export_file_basename)
        .to eq "some_great_submissions - 2000-01-01 - 123AM"
    end
  end

  describe "archive_basename" do
    let(:result) { subject.archive_basename }

    before do
      allow(subject).to receive_messages \
        formatted_assignment_name: "The Assignment",
        formatted_team_name: "The Team"
    end

    it "combines the formatted assignment and team names" do
      expect(result).to eq "The Assignment - The Team"
    end

    it "strips out whitespace" do
      allow(subject).to receive_messages \
        formatted_assignment_name: "           The Assignment",
        formatted_team_name: "The Team    "

      expect(result).to eq "The Assignment - The Team"
    end

    it "compacts out nil team names" do
      allow(subject).to receive(:formatted_team_name) { nil }
      expect(result).to eq "The Assignment"
    end
  end

  describe "#formatted_team_name" do
    let(:result) { subject.formatted_team_name }

    # make sure that stale instance variables don't interfere with caching
    before(:each) { subject.instance_variable_set(:@team_name, nil) }

    context "has_team? is false and @team_name is nil" do
      before do
        allow(subject).to receive(:has_team?) { false }
      end

      it "returns nil" do
        expect(result).to be_nil
      end

      it "doesn't set a @team_name" do
        result
        expect(subject.instance_variable_get(:@team_name)).to be_nil
      end
    end

    context "has_team? is true" do
      before do
        allow(subject).to receive(:has_team?) { true }
        allow(subject).to receive_message_chain(:team, :name) { "Super Team" }
      end

      it "titleizes the team name" do
        expect(Formatter::Filename).to receive(:titleize).with "Super Team"
        result
      end

      it "sets a @team_name" do
        result
        expect(subject.instance_variable_get(:@team_name)).to eq "Super Team"
      end

      it "caches the team name" do
        result
        expect(Formatter::Filename).not_to receive(:titleize)
        result
      end
    end
  end

end
