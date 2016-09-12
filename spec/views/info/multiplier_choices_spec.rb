# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "info/multiplier_choices" do

  before(:all) do
    @course = create(:course)
    @student_1 = create(:student_course_membership, course: @course).user
    @student_2 = create(:student_course_membership, course: @course).user
    @students = @course.students

    @assignment_type_1 = create(:assignment_type, course: @course)
    @assignment_type_2 = create(:assignment_type, course: @course)
    @assignment_types = @course.assignment_types
  end

  before(:each) do
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "renders successfully" do
    render
  end
end
