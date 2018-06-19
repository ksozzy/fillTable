=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:WebView视图组件
=end
require_relative '../api/js_api'
require 'Qt'

module KSO_SDK::View

  # :nodoc:all
  class WebView < KxWebViewWidget

    attr_reader :api
    
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

    # 重新加载
    def reloadUrl(url)
      reload(url, @api)
    end

    private
    ##
    # 扫描 KSO_SDK::Web 中的Api接口
    def findWebApi
      array = []
      KSO_SDK::Web.constants.each do | const |
        constName = "#{KSO_SDK::Web}::#{const}"
        clazz = Object.const_get(constName)
        begin
          array << clazz.new() if clazz.class != Module && clazz.superclass == KSO_SDK::JsBridge
        rescue => e
          klog "rescue exception when add :#{constName} = #{clazz}"
        end
      end
      klog array
      array
    end

  end

  #Webview弹窗
  class WebViewDialog < WebView

    Window = 0x00000001
    Dialog = 0x00000002 | Window

    def initialize(context, modal = false, delColse = true)
      super((modal)? KSO_SDK::getCurrentMainWindow() : nil , context)
      KShadowBorder.new(self, self , false, 10)

      if modal
        setAttribute(Qt::WA_ShowModal, true)
        setWindowFlags(Dialog | Qt::Window | Qt::FramelessWindowHint)
      end
      setAttribute(Qt::WA_DeleteOnClose, true) if delColse
    end

    def self.newSheetModal(context)
      dialog = KSO_SDK::View::WebViewWidget.new(context)
      dialog.setParent(KSO_SDK.getCurrentMainWindow)
      dialog.setWindowFlags(Qt::Sheet | Qt::MSWindowsFixedSizeDialogHint)
      dialog.setAttribute(Qt::WA_ShowModal, true)
      dialog
    end

  end

  #Webview控件
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

    def reload(url)
      @webview.reload(url)
    end

  end

  
end