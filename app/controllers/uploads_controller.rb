class UploadsController < ApplicationController
  def remove
    fetch_upload
    @upload.delete_from_s3

    if @upload.exists_on_s3?
      flash[:alert] = "File was not successfully deleted from the server."
    else
      destroy_upload_with_flash
    end

    redirect_to :back
  end

  protected

  def fetch_upload
    @upload = params[:model].classify.constantize.find params[:upload_id]
  end

  def destroy_upload_with_flash
    if @upload.destroy # destroy the actual persisted active record object resource
      flash[:success] = "File was successfully removed from the server and deleted."
    else
      flash[:alert] = "File was deleted from the server but the corresponding record could not be destroyed."
    end
  end
end
