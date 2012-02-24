class Hand < ActiveRecord::Base
  belongs_to :game_table
  include PokerCalculator

  has_many :cards 
  has_many :community_cards, :as => :dealable, :class_name => 'Card'

  has_many :rounds do
    def currently_open
      where(:open => true).first
    end
  end

  attr_accessor :winner
  
  def deck
    @deck ||= Deck.new
  end


  def play!
    save 
    deal_pocket_cards
    while next_round do
      rounds.currently_open.play!
      deal_community_cards
    end
    close_hand!
  end

  def next_round
    if next_betting_phase
      rounds.create(:betting_phase => next_betting_phase, :open => true, :hand => self)
    else
      false
    end
  end

  def deal_pocket_cards
    2.times do 
      active_players.each do |player|
        deal_card(player)
      end
    end
  end

  def add_community_card
    puts "adding community card"
    puts deal_card(self)
  end

  def deal_card(dealable)
    Card.create(deck.card!.merge(:dealable => dealable, :hand_id => id))
  end

  def deal_community_cards
    deck.burn!
    case rounds.last.betting_phase
    when 'pre_flop'
      3.times do
        add_community_card
      end
    when 'river'
      return
    else
      add_community_card
    end
  end

  def close_hand!
    end_of_round = active_players.inject({}){ |sum, player| sum.merge({full_player_hand(player) => player})}
    @winner = end_of_round[end_of_round.keys.sort.last]
  end

  def full_player_hand(player)
    PokerHand.new((player.cards.where(:hand_id => self) + community_cards).map{|card| card.to_code})
  end

  #If we have a currently open round, then get the betting phase after that
  def next_betting_phase
    if rounds.last
      return betting_phases[betting_phases.index(rounds.last.betting_phase.to_sym)  + 1]
    else
      betting_phases.first
    end
  end

  def current_betting_phase
    (rounds.currently_open && rounds.currently_open.betting_phase) || -1
  end

  # Can never have nil
  def betting_phases
    @betting_phases ||= [:pre_flop, :flop, :turn, :river]
  end

  def players
    game_table.players
  end

  def active_players
    players.all.select { |p| 
      p.actions.where(:action_name => "fold", :round_id => self.rounds).count == 0
    }
  end


end
