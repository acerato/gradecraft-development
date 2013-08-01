class AssignmentType < ActiveRecord::Base
  attr_accessible :due_date_present, :levels, :max_value, :name,
    :percentage_course, :point_setting, :points_predictor_display,
    :predictor_description, :resubmission, :universal_point_value, :course,
    :course_id, :order_placement, :student_weightable, :mass_grade,
    :score_levels_attributes, :score_level, :mass_grade_type, :course

  belongs_to :course
  belongs_to :grade_scheme
  has_many :assignments
  has_many :grades
  has_many :score_levels
  accepts_nested_attributes_for :score_levels, allow_destroy: true

  validates_presence_of :name, :points_predictor_display, :point_setting

  scope :student_weightable, -> { where(:student_weightable => true) }

  #Displays how much the assignment type is worth in the list view
  def weight
    if percentage_course?
      percentage_course.to_s << "%"
    elsif max_value?
      max_value.to_s << " possible points"
    elsif student_weightable?
      "#{course.user_term.pluralize} decide!"
    else
      "#{total_points} possible points"
    end
  end
  
  def total_points 
    assignments.pluck('point_total').sum
  end

  def multiplier_open?
    course.student_weight_close_date > Date.today
  end

  def slider?
    points_predictor_display == "Slider"
  end

  def fixed?
    points_predictor_display == "Fixed"
  end

  def select?
    points_predictor_display == "Select List"
  end

  def has_levels?
    levels == true
  end

  def has_soon_assignments?
    assignments.any?(&:soon?)
  end

  def grade_checkboxes?
    mass_grade_type == "Checkbox"
  end

  def grade_select?
    mass_grade_type == "Select List"
  end

  def grade_radio?
    mass_grade_type == "Radio Buttons"
  end
end
