require "showtime"

class Assignments::Grades::MassEditPresenter < Showtime::Presenter
  def title
    "Quick Grade #{assignment.name}"
  end

  def assignment
    properties[:assignment]
  end

  def groups
    assignment.groups
  end

  def assignment_score_levels
    assignment.assignment_score_levels.order_by_points
  end
end
