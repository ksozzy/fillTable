require_relative '../api/settings'

module KSO_SDK::View

  DRAW_CLOSE_BUTTON_SCRIPT = "
    PADDING = 7

    def paintEvent(event)
      @painter = Qt::Painter.new if @painter.nil?
      @painter.begin(self)
      @painter.setPen(Qt::Pen.new(Qt::Color.new(162, 162, 162)))
      @painter.drawLine(PADDING, PADDING, width() - PADDING, height() - PADDING)
      @painter.drawLine(PADDING, height() - PADDING, width() - PADDING, PADDING)
      @painter.end
    end"

  module Internal
    
    class RubyPluginSettings < KSettings

      def initialize
        super
        beginGroup($kxApp.productVersion)
        beginGroup("plugins")
        beginGroup("krubytemplate")
      end

      def appId=(value)
        beginGroup("#{value}")
      end

      def setRegValue(key, val)
        setValue(key, Qt::Variant::fromValue(val))
      end

      def getRegValue(key)
        return value(key)
      end

      def isRegExist(key)
        return !value(key).isNull
      end
    end

  end

  # :nodoc: default webview width
  DEFAULT_WEBVIEW_WIDTH = 360

  # :nodoc: small screen webview width
  SMALL_SCREEN_WEBVIEW_WIDTH = 300

  def self.getWebviewWidth
    if @webview_width.nil?
      if $kxApp::desktop().height <= 768
        @webview_width = SMALL_SCREEN_WEBVIEW_WIDTH
      else
        @webview_width = DEFAULT_WEBVIEW_WIDTH
      end
    end
    @webview_width
  end

  AssistantPopupWidth = 311
  AssistantPopupHeight = 73

  class AssistantPopup < SDK::FormWindow

    attr_writer :onAddToolButton, :onShowToolbarTip, :onSetStatus
    attr_accessor :show_button, :title

    define_label :background, :alert, :tip_line, :tip_picture
    define_button :close_button, :add_tool_button, :tip_button

    def initialize(title, scale, parent)
      super(parent)

      self.title =  title

      setWindowFlags(Qt::FramelessWindowHint | Qt::DialogType)
      # setWindowFlags(Qt::FramelessWindowHint | Qt::DialogType | Qt::WindowSystemMenuHint | Qt::WindowStaysOnTopHint)      

      setAttribute(Qt::WA_TranslucentBackground)    
      setStyleSheet("QWidget { border: none;}")

      width = AssistantPopupWidth * scale
      height = AssistantPopupHeight * scale

      tip_picture.setGeometry(0, 0, width, height)
      pixmap = Qt::Pixmap.new
      pixmap.load(":images/bg_popup.png")
      tip_picture.setPixmap(pixmap.scaled(width, height, Qt::IgnoreAspectRatio, Qt::SmoothTransformation))
      tip_picture.setVisible(true)
      
      pixmap = Qt::Pixmap.new
      pixmap.load(":images/gray.png")      
      alert.setPixmap(pixmap.scaled(16 * scale, 16 * scale, Qt::IgnoreAspectRatio, Qt::SmoothTransformation))
      alert.setGeometry(17 * scale, 17 * scale, 16 * scale, 16 * scale)
      alert.setVisible(true)

      font_size = 12 * scale
      tip_line.setText("将#{title}添加到菜单栏，下次使用更方便")
      tip_line.setStyleSheet("QLabel {
        color:rgb(136, 136, 136); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      tip_line.setGeometry(40 * scale, 18 * scale, 258 * scale, 16 * scale)

      tip_button.setText("查看")
      tip_button.setStyleSheet(
        "QPushButton {
          text-align: left;
          border: none;
          color:rgb(97, 153, 242); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      tip_button.setGeometry(40 * scale, 39 * scale, 25 * scale, 17 * scale)
      tip_button.setCursor(Qt::Cursor.new(Qt::PointingHandCursor))
      tip_button.onClicked = :showToolbarTip

      add_tool_button.setText("添加到菜单栏")
      add_tool_button.setGeometry(40 * scale, 39 * scale, 118 * scale, 16 * scale)
      pixmap = Qt::Pixmap.new
      pixmap.load(":images/ic_add.png")
      add_tool_button.setIcon(Qt::Icon.new(pixmap.scaled(11 * scale, 11 * scale, Qt::IgnoreAspectRatio, Qt::SmoothTransformation)))
      add_tool_button.setStyleSheet(
        "QPushButton {
          border: none;
          text-align: left;
          color:rgb(80, 179, 121); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      add_tool_button.setCursor(Qt::Cursor.new(Qt::PointingHandCursor))
      add_tool_button.onClicked = :addToolButtClicked

      close_button.setFixedSize(Qt::Size.new(16 * scale, 16 * scale))
      close_button.onClicked = :closeClicked
      close_button.setGeometry(280 * scale, 8 * scale, 16 * scale, 16 * scale)
      close_button.setToolTip("关闭")

      close_button.instance_eval ("
        PADDING = 5 * scale

        def paintEvent(event)
          @painter = Qt::Painter.new if @painter.nil?
          @painter.begin(self)
          @painter.setPen(Qt::Pen.new(Qt::Color.new(162, 162, 162)))
          @painter.drawLine(PADDING, PADDING, width() - PADDING, height() - PADDING)
          @painter.drawLine(PADDING, height() - PADDING, width() - PADDING, PADDING)
          @painter.end
        end"
      )
      
      self.show_button = false
      showButtonChanged
    end

    def addToolButtClicked
      self.setVisible(false)
      @onAddToolButton.call(self) unless @onAddToolButton.nil?
      @onSetStatus.call(false) unless @onSetStatus.nil?      
      KSO_SDK::Web::Internal::infoCollect({:action=>"script_fav_ribbon"})
    end

    def showToolbarTip
      self.setVisible(false)
      @onShowToolbarTip.call unless @onShowToolbarTip.nil?      
    end

    def setShowButton(value)
      if self.show_button != value
        self.show_button = value
        showButtonChanged
      end
    end

    def showButtonChanged
      if self.show_button
        tip_line.setText("助手已添加到菜单栏：文档助手>#{self.title}")
        tip_button.setVisible(true)
        add_tool_button.setVisible(false)
        tip_picture.setVisible(true)
      else
        tip_line.setText("将#{self.title}添加到菜单栏，下次使用更方便")
        tip_button.setVisible(false)
        add_tool_button.setVisible(true)
        tip_picture.setVisible(true)
      end
    end

    def closeClicked
      self.setVisible(false)
      KSO_SDK::Web::Internal::infoCollect({:action=>"script_fav_close"})
    end

  end

  # :nodoc:all
  class TaskPane < Qt::DockWidget
    
    attr_accessor :appId, :status, :show_button, :scale
    attr_accessor :title_bar
    attr_reader :context
    attr_accessor :onCloseClicked

    def initialize(title, parent, context)
      super(title, parent)
      @context = context
      self.scale = KxWebViewWidget::dpiScaled(1.0)

      setStyleSheet(
        "QWidget {background: rgb(255, 255, 255);}")
        
      width = KSO_SDK::View::getWebviewWidth()
      max_width = width
      max_width += 300 if $kxApp::desktop().width > 1920

      setMaximumWidth(max_width)
      setMinimumWidth(width)
      setAllowedAreas(Qt::RightDockWidgetArea | Qt::LeftDockWidgetArea)
      setFeatures(Qt::DockWidget::AllDockWidgetFeatures)

      font = Qt::Font.new
      font.setPixelSize(12 * scale)
      font.setFamily("微软雅黑")
      setFont(font)

      self.title_bar = TaskPaneTitle.new(title, scale, self)
      title_bar.onClosePane = method(:closeClicked)
      setTitleBarWidget(title_bar)
      setUpFavoriteButton()

      # KSO_SDK.getCurrentMainWindow().addDockWidget(Qt::RightDockWidgetArea, self, Qt::Horizontal)
      
      taskpane = KSO_SDK.getCurrentMainWindow().findDockWidget("KxTaskPaneContainer")
      if !taskpane.nil?
        KSO_SDK.getCurrentMainWindow().splitDockWidget(self, taskpane, Qt::Horizontal)
        taskpane.setVisible(false)
      end

      KSO_SDK.getCurrentMainWindow().installEventFilter(self.title_bar)
      self.installEventFilter(self.title_bar)
    end

    def setUpFavoriteButton()
      settings = KSO_SDK::Settings.new(context)
      isShow = settings.readBool(IsShowButton)
      title_bar.setShowButton(isShow)
    end

    ApplicationName = "application_name"
    Icon = "icon"
    IsShowButton = "is_show_button"
    RunFirst = "run_first"
    StartShow = "start_show"
    Title = "title"
    TipCount = "tip_count"
    

    def setStatus(status)
      if (self.status != status)
        self.status = status
        write(StartShow, status)
      end
    end
    
    def getStatus
      self.status
    end
    
    def getTipCount
      @tip_count
    end

    def incTipCount
      @tip_count = @tip_count + 1
      write(TipCount, @tip_count)
    end

    def readRegistry
      reg = Internal::RubyPluginSettings.new
      reg.appId = self.appId

      self.status = readBool(reg, StartShow, true)      
      @run_first = readBool(reg, RunFirst, true)
      self.show_button = readBool(reg, IsShowButton, false)
      @tip_count = readInt(reg, TipCount, 0)

      title_bar.setShowButton(self.show_button)
    end
    
    def readBool(reg, key, default)
      val = reg.getRegValue(key)
      if val.isNull
        default
      else
        val.toBool
      end
    end

    def readInt(reg, key, default)
      val = reg.getRegValue(key)
      if val.isNull
        default
      else
        val.toInt
      end
    end

    def write(key, val)
      reg = Internal::RubyPluginSettings.new
      reg.appId = self.appId
      reg.setRegValue(key, val)
    end

    def setRunFirst(run_first)
      if @run_first != run_first
        @run_first = run_first
        write(RunFirst, run_first)
      end
    end

    def getRunFirst
      @run_first
    end

    def setShowButton(show_button)
      if self.show_button != show_button
        self.show_button = show_button
        title_bar.setShowButton(self.show_button)
        showToolbarTip
      end
    end

    def getShowButton
      self.show_button
    end

    def showToolbarTip
      KSO_SDK.addFavorite(context)
    end

    def setFeedbackUrl(feedbackUrl)
      title_bar.feedbackUrl = feedbackUrl
    end

    def writeRegistry(appId, title, icon)
      reg = Internal::RubyPluginSettings.new
      reg.appId = self.appId      
      reg.setRegValue(Title, title) if reg.getRegValue(Title).isNull
      reg.setRegValue(ApplicationName, "#{KSO_SDK::getAppType()}") if reg.getRegValue(ApplicationName).isNull
      reg.setRegValue(Icon, icon) if !icon.nil? && reg.getRegValue(Icon).isNull
    end

    def addToolButton(sender)
      setShowButton(true)
    end

    def closeClicked
      setVisible(false)
      @onCloseClicked.call() unless @onCloseClicked.nil?
    end

  end

  SW_SHOWNORMAL = 1

  # :nodoc:all
  class TaskPaneTitle < SDK::FormWindow

    attr_writer :feedbackUrl
    attr_accessor :title, :show_button, :onClosePane, :assistant_popup, :info_collect
    attr_accessor :scale

    define_label :title_label
    define_button :close_button, :feedback_button, :add_to_toolbar_button

    def initialize(title, scale, parent)
      super(parent)
      self.title = title
      self.scale = scale

      feedback_button.setFixedSize(Qt::Size.new(21 * scale, 21 * scale))
      feedback_button.setStyleSheet(
        "QPushButton{border:0px;border-image:url(:images/feedback_normal.png);} 
         QPushButton:hover{border:0px;border-image:url(:images/feedback_hovered.png);}")
      feedback_button.setCursor(Qt::Cursor.new(Qt::PointingHandCursor))
      feedback_button.setToolTip("问题反馈")
      feedback_button.onClicked = :feedbackClicked
      feedback_button.setGeometry(4 * scale, 9 * scale, 21 * scale, 21 * scale)

      font_size = 12 * scale
      title_label.setText("#{title}：告诉我们...")
      title_label.setAlignment(Qt::AlignLeft | Qt::AlignVCenter)
      title_label.setFixedSize(Qt::Size.new(168 * scale, 16 * scale))
      title_label.setStyleSheet("QLabel {
        color:rgb(105, 105, 105); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      title_label.setGeometry(27 * scale, 11 * scale, 168 * scale, 16 * scale)
  
      add_to_toolbar_button.setFixedSize(Qt::Size.new(21 * scale, 21 * scale))
      add_to_toolbar_button.setStyleSheet(
        "QPushButton {border:0px;border-image:url(:images/addtotoolbar.png);} 
         QPushButton:hover {border:0px;border-image:url(:images/addtotoolbar_added.png);}")
      add_to_toolbar_button.setCursor(Qt::Cursor.new(Qt::PointingHandCursor))
      add_to_toolbar_button.setToolTip("添加到菜单栏")
      add_to_toolbar_button.onClicked = :onAddToBoolbarClicked
      add_to_toolbar_button.setGeometry(parent.width - 51 * scale, 10 * scale, 21 * scale, 21 * scale)

      close_button.setFixedSize(Qt::Size.new(21 * scale, 21 * scale))
      close_button.onClicked = :closeClicked
      close_button.setToolTip("关闭")
      close_button.instance_eval(DRAW_CLOSE_BUTTON_SCRIPT)      
      close_button.setGeometry(parent.width - 25 * scale, 10 * scale, 21 * scale, 21 * scale)
    end

    def sizeHint
      return Qt::Size.new(30, 40 * scale)
    end

    def paintEvent(event)
      @painter = Qt::Painter.new if @painter.nil?
      @painter.begin(self)
      @painter.fillRect(rect, Qt::Color.new(255, 255, 255))
      @painter.end
    end

    def feedbackClicked
      if !@feedbackUrl.nil?
        require 'win32ole'
        shell = WIN32OLE.new('Shell.Application')
        shell.ShellExecute(@feedbackUrl, '', '', 'open', SW_SHOWNORMAL)
      end
      KSO_SDK::Web::Internal::infoCollect({:action=>"script_feedback"})
    end

    def closeClicked
      if !self.assistant_popup.nil? && self.assistant_popup.isVisible
        self.assistant_popup.setVisible(false)
      end
      self.onClosePane.call unless self.onClosePane.nil?
    end

    def onAddToBoolbarClicked
      if self.assistant_popup.nil?
        # self.assistant_popup = AssistantPopup.new(
        #   title, scale, KSO_SDK.getCurrentMainWindow())
          self.assistant_popup = AssistantPopup.new(
            title, scale, self.parent)
          assistant_popup.onAddToolButton = self.parent.method(:addToolButton)
        assistant_popup.onShowToolbarTip = self.parent.method(:showToolbarTip)
        assistant_popup.onSetStatus = self.parent.method(:setStatus)        
      end
      assistant_popup.setShowButton(self.show_button)
      assistant_popup.show
      setAssistantPopupGeometry
      KSO_SDK::Web::Internal::infoCollect({:action=>"script_fav"})
    end

    def setAssistantPopupGeometry
      if self.assistant_popup.isVisible
        point = self.mapToGlobal(Qt::Point.new(0, 0))
        self.assistant_popup.setGeometry(
          point.x + (self.width - AssistantPopupWidth * scale) / 2, 
          point.y + 43 * scale, 
          AssistantPopupWidth * scale, 
          AssistantPopupHeight * scale)
      end
    end

    def setShowButton(show_button)
      if self.show_button != show_button || self.show_button.nil?
        self.show_button = show_button
        if show_button
          add_to_toolbar_button.setStyleSheet(
              "QPushButton {border:0px;border-image:url(:images/addtotoolbar_added.png);} "    
          )
        else
          add_to_toolbar_button.setStyleSheet(
            "QPushButton {border:0px;border-image:url(:images/addtotoolbar.png);} 
             QPushButton:hover {border:0px;border-image:url(:images/addtotoolbar_added.png);}"
          )
        end
      end
    end

    Move = 13                               # move widget
    Resize = 14                             # resize widget

    def eventFilter(o, e)
      if e.type == Move || e.type == Resize
        setAssistantPopupGeometry 
        close_button.setGeometry(parent.width - 25 * scale, 10 * scale, 21 * scale, 21 * scale)
        add_to_toolbar_button.setGeometry(parent.width - 51 * scale, 10 * scale, 21 * scale, 21 * scale)
      end
      
      super(o, e)
    end
  end

end