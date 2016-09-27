require "./app/presenters/assignments/grades/mass_edit_presenter"
require "active_record_spec_helper"

describe Assignments::Grades::MassEditPresenter do
  let(:assignment) { double(:assignment) }
  subject { described_class.new }

  before(:each) { allow(subject).to receive(:assignment).and_return assignment }

  describe "#title" do
    it "includes the assignment name" do
      assignment_name = "Mock Assignment"
      allow(assignment).to receive(:name).and_return assignment_name
      expect(subject.title).to include assignment_name
    end
  end

  describe "#assignment" do
    it "returns the assignment" do
      expect(subject.assignment).to eq assignment
    end
  end

  describe "#groups" do
    it "returns the assignment groups" do
      groups = double(:groups, name: "Mock Group")
      allow(assignment).to receive(:groups).and_return groups
      expect(subject.groups).to eq groups
    end
  end

  describe "#assignment_score_levels" do
    it "returns ordered assignment_score_levels" do
      assignment_score_levels = double(:assignment_score_levels)
      allow(assignment).to receive(:assignment_score_levels).and_return assignment_score_levels
      allow(assignment_score_levels).to receive(:order_by_points).and_return assignment_score_levels
      expect(subject.assignment_score_levels).to eq assignment_score_levels
    end
  end
end
