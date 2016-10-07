# The Grade Scheme Elements define the point thresholds earned at which students
# earn course wide levels and grades
class GradeSchemeElementsController < ApplicationController
  before_filter :ensure_staff?, except: [:index]

  def index
    @grade_scheme_elements = current_course
                             .grade_scheme_elements.order_by_highest_points
  end

  def edit
    @grade_scheme_element = current_course.grade_scheme_elements.find(params[:id])
  end

  def update
    @grade_scheme_element = current_course.grade_scheme_elements.find(params[:id])
    if @grade_scheme_element.update_attributes(grade_scheme_element_params)
      redirect_to grade_scheme_elements_path,
        notice: "#{@grade_scheme_element.name} successfully updated"
    else
      render action: "edit"
    end
  end

  # Edit all the grade scheme items for a course
  def mass_edit
    @course = current_course
    @total_points = current_course.total_points
    @grade_scheme_elements =  current_course
                              .grade_scheme_elements.order_by_highest_points.select(
                                :id,
                                :level,
                                :lowest_points,
                                :letter,
                                :highest_points,
                                :course_id)
  end

  def mass_update
    @course = current_course
    GradeSchemeElement.transaction do
      begin
        @course.grade_scheme_elements.where(id: params[:deleted_ids]).destroy_all
        @course.update_attributes(grade_scheme_elements_attributes_params)
      rescue
        raise "HandleThis"
      end
    end
    respond_to do |format|
      if @course.save
        format.json do
          render json: current_course.grade_scheme_elements.select(
            :id,
            :level,
            :lowest_points,
            :letter,
            :highest_points,
            :course_id)
        end
      else
        format.json { render json: false, status: :internal_server_error }
      end
    end
  end

  def export_structure
    course = current_user.courses.find_by(id: params[:id])
    respond_to do |format|
      format.csv { send_data GradeSchemeExporter.new.export(course), filename: "#{ course.name } Grading Scheme - #{ Date.today }.csv" }
    end
  end

  private

  def grade_scheme_element_params
    params.require(:grade_scheme_element).permit :id, :letter, :lowest_points,
      :highest_points, :level, :description, :course_id, unlock_conditions_attributes: [:id, :unlockable_id, :unlockable_type, :condition_id, :condition_type, :condition_state, :condition_value, :condition_date, :_destroy]
  end

  def grade_scheme_elements_attributes_params
    fix_grade_scheme_elements_attributes_params
    params.permit grade_scheme_elements_attributes: [:id, :letter, :lowest_points,
      :highest_points, :level, :description, :course_id]
  end

  # Clean up the grade_scheme_elements_attributes param and modify
  # highest_points for each Element to be one point lower than the next level's
  # lowest_points.
  def fix_grade_scheme_elements_attributes_params
    gse_attributes = params["grade_scheme_elements_attributes"]

    gse_attributes.sort_by! { |e| e["lowest_points"] }

    # Make sure first element's lowest_points is zero
    if gse_attributes.first["lowest_points"] != 0
      gse_attributes.unshift({
        "level"=>"-", "lowest_points"=>0, "letter"=>"", "highest_points"=>0
      })
    end

    gse_attributes.each_with_index do |gse, i|
      next_gse = gse_attributes[i+1]
      if next_gse.nil?
        # TODO: Make sure last element's highest_points is course's max points
        if gse["lowest_points"] < @course.total_points.to_i
          gse["highest_points"] = @course.total_points.to_i
        else
          gse["highest_points"] = gse["highest_points"].to_i + 1
        end
      else
        gse["highest_points"] = next_gse["lowest_points"].to_i - 1
      end
    end
  end
end
