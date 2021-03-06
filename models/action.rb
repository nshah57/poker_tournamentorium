class Action < ActiveRecord::Base
  belongs_to :player
  belongs_to :round

  def is_fold?
    return action_name == 'fold'
  end

  def is_blind?
    return action_name == 'blind'
  end

  def is_win?
    return action_name == 'won'
  end
end
