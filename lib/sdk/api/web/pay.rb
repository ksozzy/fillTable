=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:支付相关接口
=end
require 'json'

module KSO_SDK::Web

  # module Internal

  #   class PayAssistant < Qt::Object

  #     attr_accessor :onFinished
  #     attr_accessor :assistant

  #     slots 'finished(const QString&, int)'

  #     def initialize
  #       super(nil)

  #       @network_access = Qt::NetworkAccessManager.new(self)
  #       puts @network_access.methods.inspect

  #       self.assistant = KSmokePayAssistant.new
  #       connect(assistant, SIGNAL('onFinished(const QString&)'),
  #               self, SLOT('finished(const QString&)'))
  #     end
      
  #     def finished(params)
  #         self.onFinished.call(params) unless self.onFinished.nil?
  #     end

  #     def closePay(order_id, sign, app_id)
  #       assistant.closePay(order_id, sign, app_id)
  #     end
  #   end

  # end

  module Internal

    class PayAssistant < Qt::Object

      attr_accessor :onFinished
      attr_accessor :assistant

      slots 'finished(QNetworkReply *)'

      def initialize
        super(nil)

        @network = Qt::NetworkAccessManager.new(self)
        connect(@network, SIGNAL('finished(QNetworkReply *)'),
          self, SLOT('finished(QNetworkReply *)'))
      end
      
      def finished(reply)
        if reply.error != Qt::NetworkReply::NoError
          puts "reply error is #{reply.error}"
        end

        byte_array = reply.readAll()
        reply.deleteLater
        self.onFinished.call(byte_array.to_s) unless self.onFinished.nil?
      end

      def closePay(order_id, sign, app_id)
        url = "http://pay.docer.wps.cn/api/pay/index/finish_order"
        url += "?"
        url += "order_id="
        url += order_id.to_s
        url += "&pay_sign="
        url += sign.to_s
        url += "&app_id="
        url += app_id.to_s

        request = Qt::NetworkRequest.new(Qt::Url.new(url))
        cookie = "wps_sid=#{KSO_SDK::getCloudService().getUserInfo().sessionId};"
        request.setRawHeader(Qt::ByteArray.new('Cookie'), Qt::ByteArray.new(cookie)) if KSO_SDK::getCloudService().getUserInfo().logined
        @network.get(request)
      end
    end

  end

  # 支付接口
  class Pay < KSO_SDK::JsBridge

    public

    # 显示支付窗口
    #
    # url: 支付地址
    def showPayDlg(url)
      @pay_dlg = nil unless @pay_dlg.nil?
      @pay_dlg = PayDlg.new(@webWidget)
      @pay_dlg.rubyPayed = lambda do | methodName, params |
        onRubyPayed(methodName, params)
      end
      @pay_dlg.showWindow(url) if !url.nil?
      nil
    end

    def closePay(order_id, sign)
      checkPayAssistant()
      @pay_assistant.closePay(order_id, sign, context.appId)
      nil
    end
    
    private

    def onRubyPayed(methodName, params)
      json_params = {:method_name => methodName, :params => params}
      callbackToJS("onPayed", json_params.to_json)
    end

    def checkPayAssistant
      @pay_assistant = Internal::PayAssistant.new if @pay_assistant.nil?
      @pay_assistant.onFinished = lambda do |params|
        finished(params)
      end    
    end

    private

    def finished(params)
      callbackToJS("onClosePay", params)
      nil
    end

  end

  # :nodoc:
  class PayDlg < KxRubyPayDlg

    # :nodoc:
    signals 'rubyPayed(const QString&, const QString&)'

    # :nodoc:
    attr_accessor :rubyPayed

    # :nodoc:
    def initialize(parent)
      super(parent)
    end

    # :nodoc:
    def onRubyPayed(methodName, params)
      rubyPayed.call(methodName, params) unless rubyPayed.nil?
    end
  end

end

