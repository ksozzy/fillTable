=begin
  #--Created by caidong<caidong@wps.cn> on 2018/4/23.
  #--Description:事件类
=end
require_relative 'common'
require 'win32ole'

module KSO_SDK

  class Event

    def initialize(eventTarget:, eventName:)
      @eventName = eventName
      @target = eventTarget
    end
  
    def connect(&block)
      createEvent() unless connected()
      @event.on_event(@eventName) { |*range| 
        begin
          block.call(*range)
        rescue Exception => e  
          klog e.message  
          klog *e.backtrace 
        end
      }
    end
  
    def disConnect
      @event.off_event(@eventName)
      @event = nil
    end
  
    def connected
      !@event.nil?
    end
  
    def createEvent
      if @event.nil? && !@target.nil?
        @event = WIN32OLE_EVENT.new(@target)
      end
      return !@event.nil?
    end
  
  end

  # 管理文档切换和关闭类
  class PageEvent

    def initialize()
      @activeEvent = Event.new(eventTarget: KSO_SDK::Application, eventName: 'WindowActivate')
    end

    # 绑定文档切换
    def bindActive(&block)
      @activeEvent.connect do | page, wa |
        block.call(KSO_SDK::ActivePage().FullName)
      end
    end

    # 绑定文档关闭
    def bindClose(page, &block)
      target = page
      eventName = 'Close'
      fullname = page.FullName
      isWpp = KSO_SDK::isWpp()
      if isWpp
        target = KSO_SDK::Application
        eventName = 'PresentationClose'
      end
      @closeEvent = Event.new(eventTarget: target, eventName: eventName) if @closeEvent.nil?
      @closeEvent.connect do | pres |
        if isWpp && pres.FullName.eql?(fullname)
          block.call()
        elsif !isWpp
          block.call()
        end
      end
    end

    def unbindActive()
      @activeEvent.disConnect()
    end

  end
  
end
