class Abilities::VideoModerator
  include CanCan::Ability

  def initialize user
    can :manage, AnimeVideoReport
    can [:new, :create, :edit, :update], AnimeVideo do |anime_video|
      !user.banned? && !anime_video.banned? && !anime_video.copyrighted?
    end
  end
end