# frozen_string_literal: true

require 'concurrent-edge'
require 'securerandom'

class Player
  attr_accessor :game_over_channel, :messages_channel
  attr_reader :id, :level

  def initialize(game_over_channel, id, level, messages_channel)
    @game_over_channel = game_over_channel
    @id = id
    @level = level
    @messages_channel = messages_channel
  end

  def self.random
    new(
      Concurrent::Channel.new(capacity: 1),
      SecureRandom.uuid,
      rand(1..1000),
      Concurrent::Channel.new(capacity: 1)
    )
  end

  def close_channels
    messages_channel.close
    game_over_channel.close
  end

  def send_messages(msgs)
    msgs.each { |msg| messages_channel.put(msg) }
  end
end
