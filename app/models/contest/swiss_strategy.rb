class Contest::SwissStrategy < Contest::DoubleEliminationStrategy
  def dynamic_rounds?
    true
  end

  def with_additional_rounds?
    false
  end

  def total_rounds
    @total_rounds ||= Math.log(@contest.members.count, 2).ceil + 2
  end

  def fill_round_with_matches round
    if round.first?
      super
    else
      create_matches(
        round,
        @contest.members.size.times.map { ContestMatch::UNDEFINED },
        group: round.last? ? ContestRound::F : ContestRound::W,
        date: round.prior_round.matches.last.finished_on +
          @contest.matches_interval.days
      )
    end
  end

  def advance_members round, prior_round
    members_ids = @statistics.sorted_scores.keys

    round.matches.each do |match|
      left_id = members_ids.shift
      right_id = (members_ids - @statistics.opponents_of(left_id)).first

      if right_id
        members_ids.delete right_id
      else
        right_id = members_ids.shift
      end

      match.update!(
        left_id: left_id,
        left_type: @contest.member_klass.name,
        right_id: right_id,
        right_type: @contest.member_klass.name
      )
    end
  end

  def advance_loser match
  end

  def advance_winner match
  end

  def results round = nil
    @statistics.sorted_scores(round).map do |id, scores|
      @statistics.members[id]
    end
  end
end
