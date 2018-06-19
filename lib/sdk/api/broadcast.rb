=begin
  #--Created by caidong<caidong@wps.cn> on 2018/4/26.
  #--Description:广播类
=end

module KSO_SDK

  class Broadcast

    def register(signal, &block)
      @receivers = {} if @receivers.nil?
      @receivers[signal] = [] unless @receivers.has_key?(signal)
      @receivers[signal] << block
    end

    def send(signal, *args)
      return if @receivers.nil? || !@receivers.has_key?(signal)
      @receivers[signal].each do | receiver |
        receiver.call(*args)
      end
    end

    def unregister(signal, owner)

    end

  end

  class Receiver

    attr_reader :owner

    def initialize(owner, &block)
      @owner = owner
      @block = block
    end

    def call(*args)
      @block.call(*args) unless @block.nil?
    end

  end
  
end

# 测试代码
# broadcast = KSO_SDK::Broadcast.new()
# broadcast.send('test')
# broadcast.register 'test' do
#   puts 'received'
# end
# broadcast.send('test')
# broadcast.unregister('test')
# broadcast.send('test')