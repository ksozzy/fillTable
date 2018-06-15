=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:WebView视图组件
=end
require_relative '../api/js_api'
require 'Qt'

module KSO_SDK::View

  class WebViewWidget < Frame

    def initialize(context)
      super(nil)
      @webview = WebView.new(self, context)
      setLayout(Qt::VBoxLayout.new do | l |
        l.setContentsMargins(0, 0, 0, 0)
        l.addWidget(@webview)
      end)
    end

    ##
    # 注册Js接口
    def registerJsApi(*apis)
      @webview.registerJsApi(*apis)
    end

    ##
    # 显示指定URL网页
    def showUrl(url)
      @webview.showUrl(url)
    end

  end

  # :nodoc:all
  class WebView < KxWebViewWidget

    def initialize(parent, context)
      super(parent, 0)
      @api = KSO_SDK::JsApi.new(self, context)
      setObjectName('WebView')
      registerJsApi(*findWebApi())
    end

    ##
    # 注册Js接口
    def registerJsApi(*apis)
      apis.each do | a |
        @api.register(a)
      end
    end

    ##
    # 显示指定URL网页
    def showUrl(url)
      showWebView(url, @api)
    end

    private
    ##
    # 扫描 KSO_SDK::Web 中的Api接口
    def findWebApi
      array = []
      KSO_SDK::Web.constants.each do | const |
        constName = "#{KSO_SDK::Web}::#{const}"
        clazz = Object.const_get(constName)
        array << clazz.new() if clazz.class != Module && clazz.superclass == KSO_SDK::JsBridge
      end
      klog array
      array
    end

  end
end