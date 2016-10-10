json.data @assignments do |assignment|
  next unless assignment.full_points > 0 || assignment.pass_fail?
  next unless assignment.visible_for_student?(@student)
  next unless assignment.include_in_predictor?
  json.type "assignments"
  json.id assignment.id.to_s
  json.attributes do
    json.merge! assignment.attributes

    json.predictor_display_type assignment.predictor_display_type

    json.score_levels assignment.assignment_score_levels.map do |asl|
      {name: asl.name, points: asl.points}
    end

    json.unlock_conditions assignment.unlock_conditions.map do |uc|
      condition.requirements_description_sentence
    end

    json.unlocked_conditions assignment.unlock_conditions.map do |uc|
      condition.requirements_completed_sentence
    end

    json.unlock_keys  assignment.unlock_keys.map do |key|
      key.key_description_sentence
    end
  end
end

json.meta do
  json.term_for_assignment term_for :assignment
  json.term_for_pass current_course.pass_term
  json.term_for_fail current_course.fail_term
  json.update_assignments false
end
