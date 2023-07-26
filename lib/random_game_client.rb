# frozen_string_literal: true

require 'concurrent-edge'
require 'logger'
require_relative 'player'

class RandomGameClient
  attr_reader :player

  def initialize
    @player = Player.random

    @logger = Logger.new($stdout)
  end

  def self.spawn(random_game_server)
    logger = Logger.new($stdout)

    # TODO
    # var wg sync.WaitGroup
    # defer wg.Wait()

    # i = 0

    10_000.times do
      client = new

      # TODO
      # wg.Add(1)
      Concurrent::Channel.go do
        # TODO
        # defer wg.Done()
        client.game_loop
      end

      begin
        random_game_server.join(client.player)
      rescue StandardError => e
        logger.error("[client-loop] error joining the server: #{e}")
        break
      end

      # logger.debug("[client-loop] client #{i} started a game")

      sleep(0.1)

      # i = i + 1
    end
  end

  def game_loop
    over = false

    until over
      Concurrent::Channel.select do |selector|
        selector.take(player.messages_channel) do |msg|
          # logger.debug("[client-loop] got message `#{msg}` from server")
        end
        selector.take(player.game_over_channel) do |_|
          logger.info("[#{player.id}] [client-loop] it's game over!")

          over = true
        end
      end
    end
  end

  private

  attr_reader :logger
end
