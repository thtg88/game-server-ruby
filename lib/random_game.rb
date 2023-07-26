# frozen_string_literal: true

require 'concurrent-edge'
require 'logger'
require 'securerandom'

class RandomGame
  attr_accessor :over_channel
  attr_reader :end_date, :id, :player1, :player2

  def initialize(players)
    raise 'only 2 players supported by this game' unless players.size == 2

    # seconds
    offset = 1

    @id = SecureRandom.uuid
    @over_channel = Concurrent::Channel.new(capacity: 1)
    @player1 = players[0]
    @player2 = players[1]
    @end_date = Time.now + offset

    @logger = Logger.new($stdout)
  end

  def start
    i = 0

    until over?
      logger.info("[#{id}] [game] round #{i}")
      round(i)
      i += 1
    end

    logger.info("[#{id}] [game] game over")

    # TODO: Increment player levels

    # First let the clients disconnect
    player1.close_channels
    player2.close_channels

    # Then let the server clean up the game
    over_channel.close
  end

  def over?
    # end date is in the past
    end_date < Time.now
  end

  def send_messages(msgs)
    player1.send_messages(msgs)
    player2.send_messages(msgs)
  end

  private

  attr_reader :logger

  def round(i)
    send_messages(["[#{id}] [game] round #{i} starting..."])

    sleep(0.5)

    send_messages(["[#{id}] [game] round #{i} over!"])
  end
end
