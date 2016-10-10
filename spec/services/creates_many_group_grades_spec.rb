require "./app/services/creates_many_group_grades"

describe Services::CreatesManyGroupGrades do
  describe ".create" do
    let(:professor) { create(:user) }
    let(:assignment) { create(:assignment) }
    let(:params) { { grades_by_group: { "0" => { "graded_by_id": "1", "instructor_modified" => "true",
      "raw_points" => "10", "status" => "graded", "group_id" => "1" } } } }

    it "iterates assignment groups to create grades" do
      expect(Services::Actions::IteratesAssignmentGroupsToCreateGrades).to receive(:execute).and_call_original
      described_class.create assignment.id, professor.id, params
    end
  end
end
