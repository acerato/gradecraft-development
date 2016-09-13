module SortsPosition
  extend ActiveSupport::Concern

  private

  def sort_position_for(type)
    method = type.to_s.underscore.pluralize
    if current_course.respond_to? method
      params[type].each_with_index do |id, index|
        current_course.send(method).update(id, position: index + 1)
      end
    end
    render head: :ok, body: nil
  end
end
