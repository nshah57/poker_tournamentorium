class Player < ActiveRecord::Base
  include RemotePlayer

  belongs_to :tournament
  has_one :seating
  has_many :actions

  has_and_belongs_to_many :game_tables, :join_table => :seatings do
    def current_table
      where(:seatings => {:active => true}).first
    end
  end

  validates_presence_of :tournament

  def current_bet
    last_bet = actions.where(:action_name => 'bet').last
    last_bet && last_bet.amount
  end

  def blind(amount)
    actions.create(:amount => amount, :action_name => 'blind')
  end
  
  # Attempt to seat.
  def seat(table)
    if accepts_seat?(table)
      sit_at(table)
      return true
    else
      return false
    end
  end


  private
  
  def sit_at(table)
    Seating.create(:player => self, :game_table => table, :active => true)
  end

end
