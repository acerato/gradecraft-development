class Challenge < ActiveRecord::Base
  include Copyable
  include ScoreLevelable
  include UploadsMedia
  include UploadsThumbnails
  include MultipleFileAttributes

  # grade points available to the predictor from the assignment controller
  attr_accessor :prediction, :grade

  belongs_to :course, touch: true
  has_many :submissions
  has_many :challenge_grades, dependent: :destroy do
    def find_or_initialize_for_team(team)
      where(team_id: team.id).first || new(team: team, challenge_id: self.id)
    end
  end

  accepts_nested_attributes_for :challenge_grades

  has_many :predicted_earned_challenges, dependent: :destroy

  score_levels :challenge_score_levels

  multiple_files :challenge_files
  has_many :challenge_files, dependent: :destroy, inverse_of: :challenge
  accepts_nested_attributes_for :challenge_files

  scope :with_dates, -> { where("challenges.due_at IS NOT NULL OR challenges.open_at IS NOT NULL") }
  scope :visible, -> { where visible: TRUE }
  scope :chronological, -> { order("due_at ASC") }
  scope :alphabetical, -> { order("name ASC") }

  validates_presence_of :course, :name
  validates_inclusion_of :visible, :accepts_submissions, :release_necessary,
  in: [true, false], message: "must be true or false"

  validate :positive_points, :open_before_close

  def has_levels?
    challenge_score_levels.present?
  end

  def challenge_grade_for_team(team)
    challenge_grades.where(team_id: team.id).first
  end

  def future?
    !due_at.nil? && due_at >= Date.today
  end

  # TODO: should be removed
  def graded?
    challenge_grades.present?
  end

  def visible_for_student?(student)
    return true if visible?
  end

  def find_or_create_predicted_earned_challenge(student_id)
    if student_id == 0
      NullPredictedEarnedChallenge.new
    else
      PredictedEarnedChallenge.find_or_create_by(student_id: student_id, challenge_id: self.id)
    end
  end

  private

  def open_before_close
    if (due_at? && open_at?) && (due_at < open_at)
      errors.add :base, "Due date must be after open date."
    end
  end

  def positive_points
    if full_points? && full_points < 1
      errors.add :base, "Point total must be a positive number"
    end
  end
end
