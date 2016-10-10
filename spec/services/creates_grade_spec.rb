require "./app/services/creates_grade"

describe Services::CreatesGrade do
  let(:professor) { create(:user) }
  let(:group) { create(:group) }
  let!(:assignment_group) { create(:assignment_group, group: group, assignment: assignment_with_group) }
  let(:assignment_with_group) { create(:group_assignment) }
  let(:grade) { create(:grade, assignment: assignment_with_group) }
  let(:params) { { "group_id" => group.id, grade: grade, assignment: assignment_with_group } }

  describe ".create" do
    it "confirms the student and assignment" do
      expect(Services::Actions::VerifiesAssignmentStudent).to receive(:execute).and_call_original
      described_class.create params, professor.id
    end

    it "initializes new grade from params" do
      expect(Services::Actions::BuildsGrade).to receive(:execute).and_call_original
      described_class.create params, professor.id
    end

    it "adds the submission id to the grade" do
      expect(Services::Actions::AssociatesSubmissionWithGrade).to receive(:execute).and_call_original
      described_class.create params, professor.id
    end

    it "marks grade as graded" do
      expect(Services::Actions::MarksAsGraded).to receive(:execute).and_call_original
      described_class.create params, professor.id
    end

    it "saves the grade" do
      expect(Services::Actions::SavesGrade).to receive(:execute).and_call_original
      described_class.create params, professor.id
    end

    it "runs the grade updater job" do
      expect(Services::Actions::RunsGradeUpdaterJob).to receive(:execute).and_call_original
      described_class.create params, professor.id
    end
  end
end
