class AnalyticsEventsController < ApplicationController
  skip_before_action :increment_page_views

  def predictor_event
    # limited to 5 predictor jobs/second in Resque initializer
    PredictorEventLogger.new(event_session_with_params).enqueue_with_fallback

    render nothing: true, status: :ok
  end

  def tab_select_event
    # limited to 20 pageview jobs/second in Resque initializer
    # only run at night during the Lull period
    event_logger = PageviewEventLogger.new(event_session_with_params)
    event_logger.build_page_from_params
    event_logger.enqueue_in_with_fallback(Lull.time_until_next_lull)

    render nothing: true, status: :ok
  end

  protected

  # event_session method is defined in ApplicationController
  def event_session_with_params
    event_session.merge params
  end
end
