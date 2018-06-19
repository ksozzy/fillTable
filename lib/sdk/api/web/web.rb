=begin
=end
require_relative '../../view/webview'
require_relative '../broadcast'

module KSO_SDK::Web

  module Internal

    # 使用cef，注意，使用cef必须在cefplugin ready为前提，关注kxcefpluginstate
    KXWEBVIEW_IMPL_TYPE_CEF = 0

    Window = 0x00000001    
    Dialog = 0x00000002 | Window

    #web view waiting widget size
    WaitingSize = Qt::Size.new(526, 281)

    class PositionCalculator

      def initialize(rect, scale)
        @rect = rect
        @scale = scale
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

      def initialize(rect, scale)
        super(rect, scale)
      end
  
      def getGeometry
        left, top, width, height = super
  
        if left == 0
          left = ($kxApp.currentMainWindow.width - width * @scale) / 2 + $kxApp.currentMainWindow.geometry.left
        end
        if top == 0
          top = ($kxApp.currentMainWindow.height - height * @scale) / 2 + $kxApp.currentMainWindow.geometry.top
        end
  
        return left, top, width, height
      end
    end
  
    class CurrentSubWindowLeft < PositionCalculator

      def initialize(rect, scale)
        super(rect, scale)
      end
  
      def getGeometry
        left, top, width, height = super
  
        if !$kxApp.currentMainWindow.centralWidget.nil?
          left = $kxApp.currentMainWindow.centralWidget.width - width * @scale
        else
          left = ($kxApp.currentMainWindow.width - width * @scale) / 2
        end
        top = ($kxApp.currentMainWindow.height - height * @scale) / 2
  
        return left, top, width, height
      end
    end
  
    class CurrentSubWindowClient < PositionCalculator

      def initialize(rect, scale)
        super(rect, scale)
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

    class EditWindowCenter < PositionCalculator

      def initialize(rect, scale)
        super(rect, scale)
      end
  
      def getGeometry
        left, top, width, height = super
        
        if !$kxApp.currentMainWindow.centralWidget.nil? and 
          !$kxApp.currentMainWindow.centralWidget.parent.nil?
          geo = $kxApp.currentMainWindow.centralWidget.geometry
          y = $kxApp.currentMainWindow.centralWidget.parent.y
          left = (geo.width - width * @scale)/2 + geo.left
          top = (geo.height - height * @scale)/2 + y
        end
  
        return left, top, width, height
      end
    end
  
    # 几个位置计算类的 映射表
    POSITION_CALCULATOR_OBJ = {
      :current_sub_window_left => CurrentSubWindowLeft,
      :current_sub_window_client => CurrentSubWindowClient,
      :main_window_center => MainWindowCenter,
      :edit_window_center => EditWindowCenter
      }

    class WebImpl < Qt::Object

      attr_accessor :api_object
      attr_accessor :web_widget
      attr_reader :js_api
      attr_accessor :broadcast
      attr_accessor :scale

      slots 'onNotifyToWidget(const QString&)'
      signals 'notifyToWidgetEvent(const QString&)'
  
      # parent is WebView
      def initialize(api_object, context)
        super(nil)
        self.api_object = api_object
        @context = context
      end
  
      def navigateNewWidget(show_mode, url, left, top, width, height, position_type, show_waiting, btnClose)
        # self.web_widget.setVisible(true) unless self.web_widget.nil?
        # return unless self.web_widget.nil?
        if !url.nil?
          klog 'url:' + url
          if show_waiting.nil?
            show_waiting = false
          end
          
          self.scale = KxWebViewWidget::dpiScaled(1.0)
          @web_widget = KSO_SDK::View::WebViewDialog.new(@context, show_mode == :show_modal, btnClose)
          @web_widget.api.cloneSingletonMethod(api_object.owner)
          self.web_widget.showUrl(url)

          geometry = Qt::Rect.new((left.nil?)? 0 : left.to_i, (top.nil?)? 0 : top.to_i, (width.nil?)? 0 : width.to_i, (height.nil?)? 0 : height.to_i)
          position_calculator = 
            getPositionCalculator((position_type.nil?)? nil : position_type.to_sym, geometry, scale)
          left, top, width, height = position_calculator.getGeometry

          klog left,top,width,height
          self.web_widget.setGeometry(left, top, width * scale, height * scale)
          @geometry = Qt::Rect.new(left, top, width * scale, height * scale)

          if show_waiting
            geometry = Qt::Rect.new(0, 0, WaitingSize.width, WaitingSize.height)
            position_calculator = 
              getPositionCalculator((position_type.nil?)? nil : position_type.to_sym, geometry, scale)
            left, top, width, height = position_calculator.getGeometry
            self.web_widget.setGeometry(left, top, width * scale, height * scale)
            # self.web_widget.layout.setCurrentIndex(1)
          else
            loadedWebFinished
          end
          klog 'navigate show'
          self.web_widget.setVisible(true)
          nil
        end
      end

      def loadedWebFinished
        if !self.web_widget.nil?
          self.web_widget.geometry = @geometry
          # self.web_widget.layout.setCurrentIndex(0)
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
        # emit notifyToWidgetEvent(context)
        broadcast.send('notifyToWidgetEvent', context) unless broadcast.nil?
      end

      def setDragArea(left, top, width, height)
        self.web_widget.onSetDragArea(Qt::Rect.new(left * scale, top * scale, width * scale, height * scale)) unless self.web_widget.nil?
      end
        
      private

      def getWaitingWidget(parent)
        @waiting_widget = Qt::Label.new('', parent)
        @movie = Qt::Movie.new(":images/webloading.gif")
        @waiting_widget.setMovie(@movie)
        @movie.start
        @waiting_widget
      end

      def getPositionCalculator(type, rect, scale)
        (POSITION_CALCULATOR_OBJ[type] or MainWindowCenter).new(rect, scale)
      end  

      def getImpl(webview_api, show_mode)
        webview_api.instance_eval do
          impls(show_mode)
        end
      end

    end  
  end

  class WebView < KSO_SDK::JsBridge

    # 弹出WebView框体
    # posType: 'main_window_center':居中主窗体，'edit_window_center':居中工作面板(文档面板),'current_sub_window_client':铺满工作面板(文档面板)
    def navigateOnNewWidget(url:, width:500, height:500, bModal:false, closeBtn:false, posType: 'main_window_center')
      navigateNewWidget(:show_modal, url, 
        0,          # left
        0,          # top
        width, 
        height, 
        posType, 
        false,      # show_waiting
        closeBtn)
    end

    def navigateOnShowWidget(url, left, top, width, height, position_type, show_waiting)
      # navigateNewWidget(:show, url, left, top, width, height, position_type, show_waiting)
    end

    def onLoadedFinished
      if !@impl.nil?
        @impl.loadedWebFinished
      end
    end
    
    def closeNavigate
      if !@impls.nil?
        @impls.each do |impl|
          impl.closeNavigate
        end
      end
      nil
    end

    def closeWindow
      self.owner.closeWeb
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

    def setDragArea(left, top, width, height)
      klog "#{left}, #{top}, #{width}, #{height}"
      self.owner.setWebDragArea(left, top, width, height)
    end

    private

    def lastImlp()
      klog @impls
      @impls.last
    end

    def impls(show_mode)
      @impls = [] if @impls.nil?
      # @impl = @impls[show_mode]
      # if @impl.nil?
      #   @impl = Internal::WebImpl.new(self, context)
      #   @impls[show_mode] = @impl
      # end
      # @impl
      @impl = Internal::WebImpl.new(self, context)
      @impls << @impl
      @impl
    end

    def navigateNewWidget(show_mode, url, left, top, width, height, position_type, show_waiting, closeBtn)
      @impl = impls(show_mode)
      @impl.navigateNewWidget(show_mode, url, left, top, width, height, position_type, show_waiting, closeBtn)
    end

  end
end