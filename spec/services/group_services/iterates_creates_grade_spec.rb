require "light-service"
require "./app/services/group_services/iterates_creates_grade"

describe Services::Actions::IteratesCreatesGrade do
  let(:group) { create(:group) }
  let(:student) { create(:user) }
  let(:student_2) { create(:user) }
  let(:professor) { create(:user) }
  let!(:membership) { create(:group_membership, group: group, student: student) }
  let!(:membership_2) { create(:group_membership, group: group, student: student_2) }
  let!(:assignment_group) { create(:assignment_group, group: group) }
  let(:grade) { create(:grade, assignment: assignment_group.assignment) }
  let(:attributes) { { grade: grade, assignment: assignment_group.assignment } }

  it "expects a group" do
    expect { described_class.execute attributes: attributes, graded_by_id: professor.id }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expects attributes" do
    expect { described_class.execute group: group, graded_by_id: professor.id }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expects a graded_by_id" do
    expect { described_class.execute group: group, attributes: attributes }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "iterates over the students in the group" do
    expect(Services::CreatesGrade).to receive(:create).exactly(group.students.length).times.and_call_original
    described_class.execute attributes: attributes, group: group, graded_by_id: professor.id
  end
end
