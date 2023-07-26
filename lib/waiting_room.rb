# frozen_string_literal: true

require 'concurrent-edge'
require 'logger'

class WaitingRoom
  attr_reader :players

  def initialize
    @players = Concurrent::Hash.new

    @logger = Logger.new($stdout)
  end

  def sit(new_players)
    new_players.each do |player|
      players[player.id] = player

      msg = "[waiting-room] player #{player.id} (level #{player.level}) sat at the waiting room"
      player.send_messages([msg])
      logger.info(msg)
    end
  end

  def pair
    new_players = [random_player_waiting]

    players.delete(new_players[0].id)

    while new_players.size < 2
      player = random_player_waiting

      next if player.nil? || new_players[0].id == player.id

      new_players << player

      players.delete(new_players[1].id)
    end

    new_players
  end

  def players_waiting
    players.size
  end

  def kill_all
    players.each { |id, _| kill(id) }
  end

  def kill_random
    kill(random_player_key)
  end

  private

  attr_reader :logger
  attr_writer :players

  def kill(key)
    return if key.empty?

    player = players[key]
    players.delete(key)

    return if player.nil?

    msg = "[#{player.id}] [waiting-room] killed"
    player.send_messages([msg])
    logger.info(msg)

    player.game_over_channel.close
  end

  def random_player_waiting
    key = random_player_key

    return nil if key.empty?

    players[key]
  end

  def random_player_key
    keys = players.keys

    return '' if keys.empty?

    keys.sample
  end
end
