class LevelBadgesController< ApplicationController
  before_filter :ensure_staff?

  def create
    level_badge = LevelBadge.create level_badge_params
    render json: level_badge, serializer: ExistingLevelBadgeSerializer
  end

  def destroy
    LevelBadge.find(params[:id]).destroy
    render nothing: true
  end

  private

  def level_badge_params
    params.require(:level_badge).permit :badge_id, :level_id
  end
end
