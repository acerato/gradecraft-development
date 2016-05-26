# TODO: refactor as AssignmentPredictionScore of type Aggregate::Average
class AssignmentPrediction
  include Analytics::Aggregate

  field :assignment_id, type: Integer

  scope_by :assignment_id

  increment_keys "%{granular_key}.count" => 1
  # "%{granular_key}.total" => lambda{ |event| event.score.to_f /
  # event.possible.to_f },

  # assignment_id: 1,
  # all_time: %,
  # yearly: {
  #   key: {
  #     total: %,
  #     count: %,
  #     average: %%
  #   }
  # },
  # monthly: {
  #   ...
  # },
  # ...

  def self.incr(event)
    super
    # TODO: Increment cached average
    # This is not yet possible in an update command without first performing
    # a separate find() command.
    # See open MongoDB support request:
    # https://jira.mongodb.org/browse/SERVER-458
  end
end
