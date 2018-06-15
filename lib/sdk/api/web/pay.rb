=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:支付相关接口
=end
require 'json'

module KSO_SDK::Web

  # 支付接口
  class Pay < KSO_SDK::JsBridge

    public

    # 显示支付窗口
    #
    # url: 支付地址
    def showPayDlg(url)      
      if !url.nil?
        @dlg = PayDlg.new(@webWidget)
        @dlg.showWindow(url)
        @dlg.rubyPayed = lambda do | methodName, params |
          onRubyPayed(methodName, params)
        end
      end
    end

    private

    def onRubyPayed(methodName, params)
      json_params = {:method_name => methodName, :params => params}
      callbackToJS("onPayed", json_params.to_json)
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

