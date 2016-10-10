require "light-service"
require "active_record_spec_helper"
require "./app/services/creates_grade/iterates_grade_attributes"

describe Services::Actions::IteratesGradeAttributes do
  let(:assignment) { create(:assignment, course: course) }
  let(:professor) { create(:user) }
  let!(:course_membership_1) { create :student_course_membership, course: course }
  let!(:course_membership_2) { create :student_course_membership, course: course }
  let(:course) { create(:course) }
  let(:grade_attributes) { { "0" => { graded_by_id: professor.id, instructor_modified: true, student_id: assignment.course.students.first,
    raw_points: 1000, status: "Graded" }, "1" => { graded_by_id: professor.id, instructor_modified: true, student_id: assignment.course.students.second,
      raw_points: 1000, status: "Graded" } } }

  it "expects assignment_id" do
    expect { described_class.execute({ graded_by_id: professor.id, grade_attributes: grade_attributes })}.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expects graded_by_id" do
    expect { described_class.execute({ assignment_id: assignment.id, grade_attributes: grade_attributes })}.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expects grade_attributes" do
    expect { described_class.execute({ graded_by_id: professor.id, assignment_id: assignment.id })}.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "should create grades" do
    expect(Services::CreatesGrade).to receive(:create).exactly(grade_attributes.length).times.and_call_original
    described_class.execute({ graded_by_id: professor.id, assignment_id: assignment.id, grade_attributes: grade_attributes })
  end
end
