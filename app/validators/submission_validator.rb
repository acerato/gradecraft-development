class SubmissionValidator < ActiveModel::Validator
  def validate(record)
    if record.link.blank? && record.text_comment.blank? &&
        record.submission_files.empty?
      record.errors[:base] << "Submission cannot be empty"
    end
  end
end
