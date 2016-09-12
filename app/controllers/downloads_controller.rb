require_relative "../presenters/downloads/base"

class DownloadsController < ApplicationController
  before_action :ensure_staff?

  def index
    @title = "Downloads"
    render :index, locals: { presenter: presenter }
  end

  protected

  def presenter
    @presenter ||= ::Presenters::Downloads::Base.new \
      params: params,
      current_course: current_course,
      current_user: current_user
  end
end
