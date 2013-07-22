class Grade < ActiveRecord::Base
  self.inheritance_column = 'something_you_will_not_use'

  include Canable::Ables

  belongs_to :course
  belongs_to :gradeable, :polymorphic => :true
  belongs_to :assignment
  belongs_to :submission
  has_many :grade_scheme_elements, :through => :assignment
  has_many :earned_badges, :as => :gradeable, :dependent => :destroy
  has_many :badges, :through => :earned_badges

  before_validation :set_course

  validates_uniqueness_of :gradeable_id, :scope => :assignment_id

  accepts_nested_attributes_for :earned_badges
  accepts_nested_attributes_for :gradeable
  attr_accessible :type, :raw_score, :final_score, :feedback, :assignment,
    :assignment_id, :badge_id, :created_at, :updated_at, :complete, :semis,
    :finals, :status, :attempted, :substantial, :user, :badge_ids, :grade,
    :gradeable, :gradeable_id, :gradeable_type, :earned_badges_attributes,
    :earned, :submission_id, :badge_ids, :earned_badge_id,
    :gradeable_attributes, :earned_badges, :earned_badges_attributes,
    :assignment

  validates_presence_of :gradeable, :assignment

  delegate :name, :description, :due_date, :assignment_type, :to => :assignment

  after_save :save_gradeable_score
  after_destroy :save_gradeable_score

  scope :completion, -> { where(order: "assignments.due_date ASC", :joins => :assignment) }
  scope :released, -> { where(status: "Released") }
  scope :for_assignment_type, ->(assignment_type) { where(:assignment_type_id => assignment_type.id) }

  def raw_score
    super || 0
  end

  def score(student)
    if final_score?
      final_score
    else
      (raw_score * weight_for_student(student)).to_i
    end
  end

  def unweighted_score
    if final_score?
      final_score
    else
      raw_score
    end
  end

  def point_total(student)
    assignment.point_total * weight_for_student(student)
  end

  def weight_for_student(student)
    assignment.weight_for_student(student)
  end

  def has_feedback?
    feedback != "" && feedback != nil
  end

  def save_gradeable_score
    gradeable.save
  end

  def is_released?
    status == "Released"
  end

  #Canable Permissions
  def updatable_by?(user)
    creator == user
  end

  def creatable_by?(user)
    gradeable_id = user.id
  end

  def viewable_by?(user)
    gradeable_id == user.id
  end

  def self.to_csv(options = {})
    #CSV.generate(options) do |csv|
      #csv << ["First Name", "Last Name", "Score", "Grade"]
      #students.each do |user|
        #csv << [user.first_name, user.last_name]
        #, user.earned_grades(course), user.grade_level(course)]
      #end
    #end
  end

  private

  def set_course
    self.course = assignment.course
  end
end
