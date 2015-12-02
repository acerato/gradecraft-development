require "light-service"
require "active_record_spec_helper"
require "./app/services/cancels_course_membership/destroys_grades"

describe Services::Actions::DestroysGrades do
  let(:course) { membership.course }
  let(:membership) { create :student_course_membership }
  let(:student) { membership.user }

  it "expects the membership to find the submissions to destroy" do
    expect { described_class.execute }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "destroys the grade" do
    another_grade = create :grade, student: student
    course_grade = create :grade, student: student, course: course
    described_class.execute membership: membership
    expect(student.reload.grades).to eq [another_grade]
  end

  it "destroys the rubric grades for the course submission" do
    another_submission = create :submission, student: student
    course_submission = create :submission, student: student, course: course
    another_grade = create :rubric_grade, submission: another_submission,
      student: student
    course_grade = create :rubric_grade, submission: course_submission,
      student: student
    described_class.execute membership: membership
    expect(RubricGrade.for_student(membership.user)).to eq [another_grade]
  end

  it "destroys the rubric grades for the course assignments" do
    course_assignment = create :assignment, course: course
    another_grade = create :rubric_grade, student: student
    course_grade = create :rubric_grade, assignment: course_assignment,
      student: student
    described_class.execute membership: membership
    expect(RubricGrade.for_student(membership.user)).to eq [another_grade]
  end
end
