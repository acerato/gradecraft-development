# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "info/earned_badges" do

  before(:all) do
    @course = create(:course)
    @student_1 = create(:student_course_membership, course: @course).user
    @student_2 = create(:student_course_membership, course: @course).user
    @students = @course.students

    @badge_1 = create(:badge, course: @course)
    @badge_2 = create(:badge, course: @course)
    @badges = @course.badges
  end

  before(:each) do
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "renders successfully" do
    render
  end
end
