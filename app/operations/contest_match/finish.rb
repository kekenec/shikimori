class ContestMatch::Finish
  method_object :contest_match

  def call
    ContestMatch.transaction do
      unvote_suspicious
      @contest_match.finish!
      @contest_match.update_column :winner_id, obtain_winner_id
    end
  end

private

  # rubocop:disable MethodLength
  def obtain_winner_id
    if @contest_match.right_id.nil?
      @contest_match.left_id

    elsif left_votes?
      @contest_match.left_id

    elsif right_votes?
      @contest_match.right_id

    elsif scores?
      max_scored

    else
      @contest_match.left_id
    end
  end
  # rubocop:enable MethodLength

  def left_votes?
    @contest_match.left_votes > @contest_match.right_votes
  end

  def right_votes?
    @contest_match.right_votes > @contest_match.left_votes
  end

  def scores?
    @contest_match.left.respond_to?(:score) &&
      @contest_match.right.respond_to?(:score)
  end

  def max_scored
    if @contest_match.right.score > @contest_match.left.score
      @contest_match.right_id
    else
      @contest_match.left_id
    end
  end

  def unvote_suspicious
    @contest_match.votes_for
      .where(voter_id: User.suspicious, voter_type: User.name)
      .each do |suspicious_vote|
        @contest_match.unvote_by suspicious_vote.voter
      end

    # спека и без этого не падает, но 30.10.2017 случился случай, когда
    # победу получил участник, набравший меньшее число голосов
    # возможно, это поможет
    # @contest_match.reload
  end
end
