# encoding: utf-8
require "rails_spec_helper"

describe "assignment_types/all_grades" do

  before(:all) do
    @course = create(:course)
    @assignment_type = create(:assignment_type, course: @course)
    @student_1 = create(:student_course_membership, course: @course).user
    @student_2 = create(:student_course_membership, course: @course).user
    @students = @course.students
  end

  before(:each) do
    assign(:assignment_type, @assignment_type)
    allow(view).to receive(:current_course).and_return(@course)
    allow(view).to receive(:term_for).and_return("Assignment")
  end

  describe "as faculty" do

    it "renders successfully" do
      allow(view).to receive(:current_user_is_staff?).and_return(true)
      render
    end
  end
end
