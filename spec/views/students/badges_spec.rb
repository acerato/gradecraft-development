# encoding: utf-8
require 'spec_helper'
include CourseTerms

describe "students/badges" do

  before(:all) do
    clean_models
    @course = create(:course)
    @student = create(:user)
    @course.students << @student
  end

  before(:each) do
    view.stub(:current_course).and_return(@course)
    view.stub(:current_student).and_return(@student)
  end

  it "renders successfully" do
    pending
    render
    assert_select "h4", :count => 1
  end

end