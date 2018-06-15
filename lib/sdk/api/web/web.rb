=begin
=end

module KSO_SDK::Web

  module Internal

    # 使用cef，注意，使用cef必须在cefplugin ready为前提，关注kxcefpluginstate
    KXWEBVIEW_IMPL_TYPE_CEF = 0

    Window = 0x00000001    
    Dialog = 0x00000002 | Window

    #web view waiting widget size
    WaitingSize = Qt::Size.new(526, 281)

    class PositionCalculator

      def initialize(rect)
        @rect = rect
      end
  
      def getGeometry
        return getLeft, getTop, getWidth, getHeight
      end
  
      def getWidth
        width = @rect.width
        if width == 0
          $kxApp.currentMainWindow.width * 2 / 4
        else
          width
        end
      end
  
      def getHeight
        height = @rect.height
        if height == 0
          $kxApp.currentMainWindow.height * 3 / 4
        else
          height
        end
      end
  
      def getLeft
        @rect.left
      end
  
      def getTop
        @rect.top
      end
    end
  
    class MainWindowCenter < PositionCalculator

      def initialize(rect)
        super(rect)
      end
  
      def getGeometry
        left, top, width, height = super
  
        if left == 0
          left = ($kxApp.currentMainWindow.width - width) / 2
        end
        if top == 0
          top = ($kxApp.currentMainWindow.height - height) / 2
        end
  
        return left, top, width, height
      end
    end
  
    class CurrentSubWindowLeft < PositionCalculator

      def initialize(rect)
        super(rect)
      end
  
      def getGeometry
        left, top, width, height = super
  
        if !$kxApp.currentMainWindow.centralWidget.nil?
          left = $kxApp.currentMainWindow.centralWidget.width - width
        else
          left = ($kxApp.currentMainWindow.width - width) / 2
        end
        top = ($kxApp.currentMainWindow.height - height) / 2
  
        return left, top, width, height
      end
    end
  
    class CurrentSubWindowClient < PositionCalculator

      def initialize(rect)
        super(rect)
      end
  
      def getGeometry
        left, top, width, height = super
        
        if !$kxApp.currentMainWindow.centralWidget.nil? and 
          !$kxApp.currentMainWindow.centralWidget.parent.nil?
  
          width = $kxApp.currentMainWindow.centralWidget.width
          height = $kxApp.currentMainWindow.centralWidget.height
          left = $kxApp.currentMainWindow.centralWidget.parent.x
          top = $kxApp.currentMainWindow.centralWidget.parent.y
        end
  
        return left, top, width, height
      end
    end
  
    # 几个位置计算类的 映射表
    POSITION_CALCULATOR_OBJ = {
      :current_sub_window_left => CurrentSubWindowLeft,
      :current_sub_window_client => CurrentSubWindowClient,
      :main_window_center => MainWindowCenter
      }

    class WebImpl < Qt::Object

      attr_accessor :api_object
      attr_accessor :web_widget
      attr_reader :js_api

      slots 'onNotifyToWidget(const QString&)'
      signals 'notifyToWidgetEvent(const QString&)'
  
      # parent is WebView
      def initialize(api_object)
        super(nil)
        self.api_object = api_object
      end
  
      def navigateNewWidget(show_mode, url, left, top, width, height, position_type, show_waiting)
        if !url.nil?
          if show_waiting.nil?
            show_waiting = false
          end

          checkWebViewWidget(show_mode)
          if checkWebWidgetApi(show_mode)
            self.web_widget.reload(url, self.js_api)
          else
            self.web_widget.webView().loadEncodedURL(Qt::Url.new(url))
          end

          geometry = Qt::Rect.new((left.nil?)? 0 : left.to_i, (top.nil?)? 0 : top.to_i, (width.nil?)? 0 : width.to_i, (height.nil?)? 0 : height.to_i)
          position_calculator = 
            getPositionCalculator((position_type.nil?)? nil : position_type.to_sym, geometry)
          left, top, width, height = position_calculator.getGeometry
          @geometry = Qt::Rect.new(left, top, width, height)

          if show_waiting
            geometry = Qt::Rect.new(0, 0, WaitingSize.width, WaitingSize.height)
            position_calculator = 
              getPositionCalculator((position_type.nil?)? nil : position_type.to_sym, geometry)
            left, top, width, height = position_calculator.getGeometry
            self.web_widget.setGeometry(left, top, width, height)
            self.web_widget.layout.setCurrentIndex(1)
          else
            loadedWebFinished
          end
          self.web_widget.setVisible(true)
          nil
        end
      end

      def loadedWebFinished
        if !self.web_widget.nil?
          self.web_widget.geometry = @geometry
          self.web_widget.layout.setCurrentIndex(0)
        end
      end
      
      def onNotifyToWidget(param)
        self.api_object.callbackToJS("onNotifyToWidget", param)
      end

      def closeNavigate
        if !self.web_widget.nil?
          self.web_widget.setVisible(false)
        end
      end

      def notifyToOtherWidget(context)
        emit notifyToWidgetEvent(context)
      end
        
      private

      def getWaitingWidget(parent)
        @waiting_widget = Qt::Label.new('', parent)
        @movie = Qt::Movie.new(":images/webloading.gif")
        @waiting_widget.setMovie(@movie)
        @movie.start
        @waiting_widget
      end
  
      def checkWebViewWidget(show_mode)
        if self.web_widget.nil?
          @web_widget = KxWebViewWidget.new(
            KSO_SDK::getCurrentMainWindow(), KXWEBVIEW_IMPL_TYPE_CEF)
          self.web_widget.layout.addWidget(getWaitingWidget(self.web_widget));

          self.web_widget.setAttribute(Qt::WA_DeleteOnClose, false);
          if show_mode == :show_modal
            self.web_widget.setAttribute(Qt::WA_ShowModal, true);
            self.web_widget.setWindowFlags(Dialog | Qt::FramelessWindowHint | Qt::MSWindowsFixedSizeDialogHint)
          else
            self.web_widget.setWindowFlags(Qt::FramelessWindowHint | Qt::MSWindowsFixedSizeDialogHint)
          end
        end
      end

      def checkWebWidgetApi(show_mode)
        if self.js_api.nil?
          @js_api = KSO_SDK::JsApi.new(self.web_widget)
          @webview_api = KSO_SDK::Web::WebView.new
          self.js_api.register(@webview_api)
          self.js_api.cloneSingletonMethod(self.api_object.owner) # self.api_object.owner is KSO_SDK::JsApi
          
          webview_impl = getImpl(@webview_api, show_mode)
          webview_impl.web_widget = self.web_widget
          connect(self, SIGNAL('notifyToWidgetEvent(const QString&)'),
            webview_impl, SLOT('onNotifyToWidget(const QString&)'))
          connect(webview_impl, SIGNAL('notifyToWidgetEvent(const QString&)'),
            self, SLOT('onNotifyToWidget(const QString&)'))
          true
        else
          false
        end
      end

      def getPositionCalculator(type, rect)
        (POSITION_CALCULATOR_OBJ[type] or MainWindowCenter).new(rect)
      end  

      def getImpl(webview_api, show_mode)
        webview_api.instance_eval do
          impls(show_mode)
        end
      end
    end  
  end

  class WebView < KSO_SDK::JsBridge

    def navigateOnNewWidget(url, left, top, width, height, position_type, show_waiting)
      navigateNewWidget(:show_modal, url, left, top, width, height, position_type, show_waiting)
    end

    def navigateOnShowWidget(url, left, top, width, height, position_type, show_waiting)
      navigateNewWidget(:show, url, left, top, width, height, position_type, show_waiting)
    end

    def onLoadedFinished
      if !@impl.nil?
        @impl.loadedWebFinished
      end
    end
    
    def closeNavigate
      if !@impls.nil?
        @impls.each do |key, impl|
          impl.closeNavigate
        end
      end
      nil
  end
    
    def notifyToWidget(context)
      if !@impl.nil?
        if context.class == Hash
          @impl.notifyToOtherWidget(context.to_json)
        else
          @impl.notifyToOtherWidget(context.to_s)
        end
      end
    end
    
    SW_SHOWNORMAL = 1

    def showBrowser(url)
      if !url.nil? 
        require 'win32ole'
        shell = WIN32OLE.new('Shell.Application')
        shell.ShellExecute(url, '', '', 'open', SW_SHOWNORMAL)
        shell = nil
      end
    end    
    
    private

    def impls(show_mode)
      @impls = {} if @impls.nil?
      @impl = @impls[show_mode]
      if @impl.nil?
        @impl = Internal::WebImpl.new(self)
        @impls[show_mode] = @impl
      end
      @impl
    end

    def navigateNewWidget(show_mode, url, left, top, width, height, position_type, show_waiting)
      @impl = impls(show_mode)
      @impl.navigateNewWidget(show_mode, url, left, top, width, height, position_type, show_waiting)
    end
  end
end