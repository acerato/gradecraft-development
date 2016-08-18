require "./lib/active_lms"

describe ActiveLMS::Syllabus do
  let(:access_token) { "BLAH" }

  describe "#initialize" do
    it "initializes with a provider" do
      expect(described_class.new(:canvas, access_token).provider).to \
        be_kind_of ActiveLMS::CanvasSyllabus
    end

    it "raises an InvalidProviderError with an invalid provider name" do
      expect { described_class.new(:blah, access_token) }.to \
        raise_error ActiveLMS::InvalidProviderError, "blah is not a supported provider"
    end
  end

  describe "#assignments" do
    subject { described_class.new :canvas, access_token }

    it "delegates to the provider" do
      expect(subject.provider).to receive(:assignments).with(123, nil)
      subject.assignments(123)
    end
  end

  describe "#course" do
    subject { described_class.new :canvas, access_token }

    it "delegates to the provider" do
      expect(subject.provider).to receive(:course).with(123)
      subject.course(123)
    end
  end

  describe "#courses" do
    subject { described_class.new :canvas, access_token }

    it "delegates to the provider" do
      expect(subject.provider).to receive(:courses)
      subject.courses
    end
  end

  describe "#grades" do
    subject { described_class.new :canvas, access_token }

    it "delegates to the provider" do
      expect(subject.provider).to receive(:grades).with(123, [456, 789])
      subject.grades(123, [456, 789])
    end
  end

  describe "#user" do
    subject { described_class.new :canvas, access_token }

    it "delegates to the provider" do
      expect(subject.provider).to receive(:user).with(123)
      subject.user(123)
    end
  end
end