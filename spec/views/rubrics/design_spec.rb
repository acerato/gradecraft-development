# encoding: utf-8
require "rails_spec_helper"
include CourseTerms

describe "rubrics/design" do

  before(:all) do
    @course = create(:course)
    @assignment = create(:assignment, course: @course)
    @rubric = create(:rubric, assignment: @assignment)
    @criterion_1 = create(:criterion, rubric: @rubric)
    @criterion_2 = create(:criterion, rubric: @rubric)
    @rubric.criteria << [ @criterion_1, @criterion_2 ]
    @criteria = @rubric.criteria
  end

  before(:each) do
    assign(:course_badges, nil)
    assign(:course_badge_count, 0)
    allow(view).to receive(:current_course).and_return(@course)
  end

  it "renders successfully" do
    render
  end
end
