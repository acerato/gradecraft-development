require "./app/services/creates_group_grades"

describe Services::CreatesGroupGrades do
  describe ".create" do
    let(:group) { create(:group) }
    let!(:assignment_group) { create(:assignment_group, group: group, assignment: assignment_with_group) }
    let(:assignment_with_group) { create(:group_assignment) }
    let(:professor) { create(:user) }
    let(:grade_attributes) { { "status": "Graded", "graded_by_id": professor.id,
      "instructor_modified": "true", "raw_points": "123" } }

    it "verifies the group" do
      expect(Services::Actions::VerifiesGroup).to receive(:execute).and_call_original
      described_class.create group.id, grade_attributes, assignment_with_group.id
    end

    it "iterates through the students in the group" do
      expect(Services::Actions::IteratesCreatesGrade).to receive(:execute).and_call_original
      described_class.create group.id, grade_attributes, assignment_with_group.id
    end
  end
end
