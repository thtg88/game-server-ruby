# frozen_string_literal: true

require 'concurrent-edge'
require 'logger'
require_relative 'random_game'
require_relative 'waiting_room'

class RandomGameServer
  def initialize
    @games = Concurrent::Hash.new
    @waiting_room = WaitingRoom.new
    @config = {
      can_clean_games_dangling: true,
      can_kill_random_waiting_players: true,
      can_print_stats: true,
      is_accepting_new_players: true
    }
    @games_mutex = Mutex.new

    @logger = Logger.new($stdout)
  end

  def shutdown
    logger.info('[random-game-server] shutting down...')

    config[:is_accepting_new_players] = false
    config[:can_kill_random_waiting_players] = false

    # wait for all games to be over
    sleep(1) while games.size.positive?

    config[:can_clean_games_dangling] = false

    waiting_room.kill_all

    config[:can_print_stats] = false
  end

  def join(player)
    raise 'not accepting new players' unless config[:is_accepting_new_players]

    waiting_room.sit([player])
  end

  def start
    logger.info('server started')

    Concurrent::Channel.go { start_new_games }
    Concurrent::Channel.go { kill_random_waiting_players }
    Concurrent::Channel.go { clean_dangling_games_over }
    Concurrent::Channel.go { print_stats }
  end

  private

  attr_accessor :config, :games, :games_mutex
  attr_reader :logger, :waiting_room

  def start_new_games
    while config[:is_accepting_new_players]
      while waiting_room.players_waiting >= 2
        # logger.debug('[game-starter] players waiting')

        games_mutex.lock

        pair = waiting_room.pair

        game = RandomGame.new(pair)
        games[game.id] = game

        games_mutex.unlock

        Concurrent::Channel.go { wait_for_game_over(game) }
        Concurrent::Channel.go { game.start }

        msg = "[#{game.id}] [game-starter] new game started with players: #{pair[0].id} and #{pair[1].id}, it will end at #{game.end_date}"
        game.send_messages([msg])
        logger.info(msg)
      end

      sleep(1)
    end

    logger.info('[game-starter] stopped accepting new players')
  end

  def wait_for_game_over(game)
    # logger.debug("[#{game.id}] [game-ender] waiting...")

    game.over_channel.take

    games.delete(game.id)

    logger.info("[#{game.id}] [game-ender] game removed")
  end

  def kill_random_waiting_players
    while config[:can_kill_random_waiting_players]
      waiting_room.kill_random

      sleep(10)
    end

    logger.info('[random-player-killer] stopped killing')
  end

  def clean_dangling_games_over
    while config[:can_clean_games_dangling]
      if games.empty?
        logger.info('[game-over-cleaner] no games dangling')
        sleep(8)
        next
      end

      games_mutex.lock

      ids = games.select { |_, game| game.over? }.map { |id, _| id }

      if ids.empty?
        logger.info('[game-over-cleaner] no games dangling')
        games_mutex.unlock
        sleep(8)
        next
      end

      logger.info("[game-over-cleaner] removing #{ids.size} games dangling...")

      ids.each { |id| games.delete(id) }

      games_mutex.unlock

      sleep(8)
    end

    logger.info('[game-over-cleaner] stopped cleaning')
  end

  def print_stats
    while config[:can_print_stats]
      logger.info("[stats-printer] #{games.size} games active, #{waiting_room.players_waiting} players waiting")

      sleep(1)
    end

    logger.info('[stats-printer] stopped printing')
  end
end
