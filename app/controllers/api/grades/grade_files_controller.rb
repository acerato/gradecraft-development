class API::Grades::GradeFilesController < ApplicationController

  before_action :ensure_staff?

  # POST /api/grades/:grade_id/grade_files
  def create
    grade = Grade.find(params[:grade_id])

    params[:grade_files].each do |f|
      grade.grade_files << GradeFile.create(file: f, filename: f.original_filename[0..49], grade_id: grade.id)
    end

    render json: { message: "success uploading grade files"}
  end
end
