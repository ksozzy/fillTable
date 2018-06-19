require_relative '../api/settings'
require 'uri'

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

  # :nodoc: default webview width
  DEFAULT_WEBVIEW_WIDTH = 330

  # :nodoc: small screen webview width
  SMALL_SCREEN_WEBVIEW_WIDTH = 300

  def self.getWebviewWidth
    # if @webview_width.nil?
    #   if $kxApp::desktop().height <= 768
    #     @webview_width = SMALL_SCREEN_WEBVIEW_WIDTH
    #   else
    #     @webview_width = DEFAULT_WEBVIEW_WIDTH
    #   end
    # end
    @webview_width = DEFAULT_WEBVIEW_WIDTH
    @webview_width
  end

  AssistantPopupWidth = 311
  AssistantPopupHeight = 73

  class AssistantPopup < FormWindow

    attr_writer :onAddToolButton, :onShowToolbarTip, :onSetStatus
    attr_accessor :show_button, :title
    attr_accessor :info_collect

    define_label :background, :alert, :tip_line, :tip_picture
    define_button :close_button, :add_tool_button, :tip_button

    def initialize(title, scale, parent, info_collect)
      super(parent)

      self.title = title
      self.info_collect = info_collect

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
      info_collect.infoCollect({:action=>"script_fav_ribbon"})
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
      info_collect.infoCollect({:action=>"script_fav_close"})
    end

  end

  SharePopupWidth = 322
  SharePopupHeight = 111

  class SharePopup < FormWindow

    attr_accessor :title, :info_collect
    define_label :background_picture_label, :lightTip_label, :shareOthers_label, :detail_label, :url_label
    define_button :close_button, :urlCopy_button

    def initialize(title, scale, parent, info_collect)
      super(parent)

      self.title = title
      self.info_collect = info_collect

      setWindowFlags(Qt::FramelessWindowHint | Qt::DialogType)
      setAttribute(Qt::WA_TranslucentBackground)
     # setStyleSheet("QWidget#background_picture_label { border: none;}")

      width = SharePopupWidth * scale
      height = SharePopupHeight * scale

      background_picture_label.setGeometry(0, 0, width, height)
      pixmap = Qt::Pixmap.new
      pixmap.load(":images/bg_share.png")
      background_picture_label.setPixmap(pixmap.scaled(width, height, Qt::IgnoreAspectRatio, Qt::SmoothTransformation))
      background_picture_label.setVisible(true)

      pixmap = Qt::Pixmap.new
      pixmap.load(":images/gray.png")
      lightTip_label.setPixmap(pixmap.scaled(16 * scale, 16 * scale, Qt::IgnoreAspectRatio, Qt::SmoothTransformation))
      lightTip_label.setGeometry(16 * scale, 16.1 * scale, 16 * scale, 16 * scale)
      lightTip_label.setVisible(true)

      font_size = 12 * scale
      shareOthers_label.setText("分享给其他人")
      shareOthers_label.setStyleSheet("QLabel {
        color:rgb(34, 34, 38); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      shareOthers_label.setGeometry(39 * scale, 16 * scale, 263 * scale, 16 * scale)


      detail_label.setText("在电脑上打开链接，启动WPS自动下载助手")
      detail_label.setStyleSheet("QLabel {
        color:rgb(136, 136, 136); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      detail_label.setGeometry(39 * scale, 33.3 * scale, 263 * scale, 16 * scale)


      close_button.setFixedSize(Qt::Size.new(16 * scale, 16 * scale))
      close_button.onClicked = :closeClicked
      close_button.setGeometry(295 * scale, 11 * scale, 16 * scale, 16 * scale)
      close_button.setToolTip("关闭")
      close_button.instance_eval ("
        PADDINGW1 = 5 * scale   #左上角为第一个点
        PADDINGH1 = 4 * scale
        PADDINGW1COR = 4 * scale  #跟第一个点对应的点
        PADDINGH1COR = 5 * scale

        PADDINGW2 = 5 * scale   #左下角为第二个点
        PADDINGH2 = 5 * scale
        PADDINGW2COR = 4 * scale  #跟第二个点对应的点
        PADDINGH2COR = 4 * scale

        def paintEvent(event)
          @painter = Qt::Painter.new if @painter.nil?
          @painter.begin(self)
          @painter.setPen(Qt::Pen.new(Qt::Color.new(162, 162, 162)))
          @painter.drawLine(PADDINGW1, PADDINGH1, width() - PADDINGW1COR, height() - PADDINGH1COR)
          @painter.drawLine(PADDINGW2, height() - PADDINGH2, width() - PADDINGW2COR, PADDINGH2COR)
          @painter.end
        end"
                                 )


      url_label.setGeometry(39 * scale, 59 * scale, 195 * scale, 27 * scale)
      url_label.setStyleSheet("QLabel {
        color:rgb(136, 136, 136); font-family: \"微软雅黑\"; font-size:#{font_size}px;
        background-color:#F5F5F5;
        border-width:1px; border-color:#E5E5E5; border-style:solid ;border-radius:2px}")


      urlCopy_button.setGeometry(234 * scale, 59 * scale, 70 * scale, 27 * scale)
      urlCopy_button.setText("复制链接")
      urlCopy_button.setStyleSheet("QPushButton {
        font-family: MicrosoftYaHei;
        font-size: 12px;
        color: #888888;
        letter-spacing: 0.8px;
        text-align: center;
        background-color:#FFFFFF;
        border-width:1px; border-color:#E5E5E5; border-style:solid; border-left:none;
        padding-top:5px; padding-left:9px; padding-right:9px; padding-bottom:6px}")
      urlCopy_button.onClicked = :copyClicked
    end

    def setShareUrlText(url)
      encodeUrl = URI.encode_www_form_component(url)
      url = "http://open.docer.wps.cn/#/share?open_assistant_url=" + encodeUrl
      url_label.setText(url)
    end

    def copyClicked()
      clipboard = Qt::Application::clipboard()
      clipboard.setText(url_label.text())
      self.setVisible(false)
    end

    def closeClicked
      self.setVisible(false)
      info_collect.infoCollect({:action=>"script_fav_close"})
    end

  end

  TIP_PICTURE_GEOMETRY = Qt::Rect.new(0, 126, 205, 83)
  CLOSE_CONFIRM_FORM_HEIGHT = 346

  # :nodoc:all
  class CloseConfirmForm < FormWindow

    attr_writer :onClose, :onAddTool, :onNotAddTool, :onClosePane, :onSetStatus
    attr_accessor :scale
    attr_accessor :info_collect

    define_label :tip_picture, :tip_line, :button_picture, :button_title, :menu_text, :bulb_picture
    define_button :close_button, :add_tool_button
    define_radio_button :add_toolbar_radio, :not_need_tool_radio

    def initialize(title, icon, scale, info_collect, parent = nil)
      super(parent)

      self.scale = scale
      self.info_collect = info_collect

      setAttribute(Qt::WA_DeleteOnClose, false)
      setWindowFlags(Qt::FramelessWindowHint | Qt::DialogType)

      setStyleSheet(
        "QWidget {background: rgb(255, 255, 255); font-family: \"微软雅黑\";}")
  
      showTipPicture(title, icon)
      setCloseButton
      setToolButton
      setTipText(title)
      setRadioButton(title)
    end

    def showTipPicture(title, icon)
      pixmap = Qt::Pixmap.new
      pixmap.load(":images/img_addtomenubar.png")
      
      tip_picture.setPixmap(pixmap.scaled(TIP_PICTURE_GEOMETRY.width * scale, TIP_PICTURE_GEOMETRY.height * scale, Qt::IgnoreAspectRatio, Qt::SmoothTransformation))
      tip_picture.setVisible(true)

      menu_text.setText("文档助手")
      font_size = 10 * scale
      menu_text.setStyleSheet("QLabel {
        color:rgb(97, 153, 242); font-family: \"微软雅黑\"; font-weight: bold; font-size:#{font_size.to_i}px;}")
    
      if !icon.nil?
        pixmap = Qt::Pixmap.new
        pixmap.load(icon)

        button_picture.setPixmap(pixmap.scaled(20 * scale, 20 * scale, Qt::IgnoreAspectRatio, Qt::SmoothTransformation))
        button_picture.setVisible(true)

        button_title.setText(title)
        button_title.setStyleSheet("QLabel {
          color:rgb(54, 49, 53);font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      end
      
    end

    def setCloseButton
      close_button.setFixedSize(Qt::Size.new(22 * scale, 22 * scale))
      close_button.onClicked = :closeClicked
      close_button.setToolTip("关闭")
      close_button.instance_eval (DRAW_CLOSE_BUTTON_SCRIPT)
    end

    def setTipText(title)
      pixmap = Qt::Pixmap.new
      pixmap.load(":images/bulb_large.png")
      
      bulb_picture.setPixmap(pixmap)
      bulb_picture.setVisible(true)
      bulb_picture.setVisible(false)

      font = Qt::Font.new
      font.setPixelSize(16 * scale)
      font.setFamily("微软雅黑")
      font.setLetterSpacing(1, 0.99)

      tip_line.setText("关闭“#{title}”窗口；默认不启动")
      tip_line.setStyleSheet("QLabel {color:rgb(34, 34, 38);}")
      tip_line.setFont(font)  
    end

    def setToolButton
      font_size = 14 * scale
      add_tool_button.setText("确定")
      if KSO_SDK::isEt
        add_tool_button.setStyleSheet(
          "QPushButton {
            background: rgb(80, 179, 121);
            border: none;
            color:rgb(255, 255, 255); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      else
        add_tool_button.setStyleSheet(
          "QPushButton {
            background: rgb(97, 153, 242);
            border: none;
            color:rgb(255, 255, 255); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      end
      add_tool_button.setCursor(Qt::Cursor.new(Qt::PointingHandCursor))
      add_tool_button.onClicked = :addToolClicked
    end

    def closeClicked
      @onClose.call(self) unless @onClose.nil?
    end

    def addToolClicked
      if add_toolbar_radio.isChecked
        @onAddTool.call(self) unless @onAddTool.nil?
        info_collect.infoCollect({:action=>"script_close_ribbon"})
      else
        @onNotAddTool.call(self) unless @onNotAddTool.nil?
        info_collect.infoCollect({:action=>"script_close_never"})
      end

      setStatus(false)
      closePane
    end

    def closePane
      @onClosePane.call(self) unless @onClosePane.nil?
    end

    def setRadioButton(title)
      font = Qt::Font.new
      font.setPixelSize(12)
      font.setFamily("微软雅黑")
      font.setLetterSpacing(1, 0.8)

      font_size = 12 * scale
      spacing = 9 * scale

      radio_button_style =
        "QRadioButton::indicator::unchecked {
          border-image: url(:/images/ic_radiobox.png);      
        }
        QRadioButton::indicator::checked {
          border-image: url(:/images/ic_radiobox_selected.png);      
        }
        QRadioButton {
          spacing: #{spacing}px;
          color:rgb(105, 105, 105); font-family: \"微软雅黑\"; font-size:#{font_size.to_i}px;}"

      add_toolbar_radio.setText("将助手添加到菜单栏，方便下次使用")
      add_toolbar_radio.setChecked(true)
      add_toolbar_radio.setStyleSheet(radio_button_style)
      add_toolbar_radio.setFont(font)

      not_need_tool_radio.setText("我不需要助手，不要再出现")
      not_need_tool_radio.setStyleSheet(radio_button_style)
      not_need_tool_radio.setFont(font)
    end

    def setStatus(status)
      @onSetStatus.call(status) unless @onSetStatus.nil?
    end

    def resizeEvent(size)
      dx = (self.width - 320 * scale) / 2

      tip_picture.setGeometry(65 * scale + dx, 126 * scale,
        TIP_PICTURE_GEOMETRY.width * scale, TIP_PICTURE_GEOMETRY.height * scale)
      menu_text.setGeometry(209 * scale + dx, 131 * scale, 49 * scale, 14 * scale)

      standard_font_width = button_title.fontMetrics.width("论文助手")
      font_width = button_title.fontMetrics.width(button_title.text)
      button_title_left = 79 - (font_width - standard_font_width) / 2
      button_picture_left = 91
      if button_title_left < 68
        button_picture_left = button_picture_left + (68 - button_title_left)
        button_title_left = 68
      end
      button_title.setGeometry(
        button_title_left  * scale + dx, 185 * scale, (font_width + 8) * scale, 14 * scale)
      button_picture.setGeometry(
        button_picture_left * scale + dx, 162 * scale, 20 * scale, 20 * scale)
  
      close_button.setGeometry(self.width - 25 * scale, 4 * scale, 21 * scale, 21 * scale)
      
      font_width = tip_line.fontMetrics.width(tip_line.text)
      tip_line_left = (self.width - font_width) / 2      
      tip_line.setGeometry(tip_line_left * scale + dx, 43 * scale, (font_width + 8) * scale, 22 * scale)

      add_tool_button.setGeometry(
        55 * scale, 290 * scale, self.width - 110 * scale, 36 * scale)

      add_toolbar_radio.setGeometry(
        40 * scale + dx, 97 * scale, 288 * scale, 17 * scale)
      not_need_tool_radio.setGeometry(
        40 * scale + dx, 232 * scale, 288 * scale, 17 * scale)
    end
  end 
  
  # :nodoc:all
  class GreyForm < FormWindow

    def initialize(parent = nil)
      super(parent)

      setAttribute(Qt::WA_DeleteOnClose, false);
      setWindowFlags(Qt::FramelessWindowHint | Qt::DialogType)
      setStyleSheet(
        "QWidget {background: rgb(0, 0, 0);}")
      setWindowOpacity(0.4)
    end

  end
  
  # :nodoc:all
  class TaskPane < Qt::DockWidget
    
    attr_accessor :appId
    attr_accessor :status
    attr_accessor :show_button
    attr_accessor :scale

    attr_accessor :close_confirm_form
    attr_accessor :confirm_grey_form
    attr_accessor :title_bar

    attr_accessor :onCloseClicked
    attr_accessor :info_collect
    attr_reader :context

    def initialize(title, parent, context)
      super(title, parent)
      @context = context
      self.info_collect = KSO_SDK::Web::InfoCollect.new
      info_collect.context = context

      self.scale = KxWebViewWidget::dpiScaled(1.0)
      # self.layout = Qt::VBoxLayout.new()
      self.layout.setContentsMargins(0, 0, 0, 0)
      # self.setContentsMargins(0, 0, 0, 0)
      self.layout.setSpacing(0)
      self.layout.setSizeConstraint(Qt::Layout::SetMinimumSize)

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

      self.title_bar = TaskPaneTitle.new(title, scale, self, info_collect)
      title_bar.shareUrl = context.shareUrl
      title_bar.onClosePane = method(:closeClicked)
      setTitleBarWidget(title_bar)
      setUpFavoriteButton()

      KSO_SDK.getCurrentMainWindow().installEventFilter(self.title_bar)
      self.installEventFilter(self.title_bar)

      readRegistry
    end

    def setUpFavoriteButton()
      settings = KSO_SDK::Settings.new(context)
      isShow = settings.readBool(IsShowButton)
      title_bar.setShowButton(isShow)
    end

    IsShowButton = "is_show_button"
    StartShow = "start_show"
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
      settings = KSO_SDK::Settings.new(context)

      self.status = settings.readBool(StartShow, true)
      self.show_button = settings.readBool(IsShowButton, false)
      @tip_count = settings.readInt(TipCount, 0)

      title_bar.setShowButton(self.show_button)
    end

    def refresh
      setUpFavoriteButton()
    end
    
    def write(key, val)
      settings = KSO_SDK::Settings.new(context)
      settings.write(key, val)
    end

    def setShowButton(show_button)
      if self.show_button != show_button
        self.show_button = show_button
        title_bar.setShowButton(self.show_button)
        showToolbarTip
      end
    end

    def getShowButton
      self.show_button = KSO_SDK::hasFavorite(context)
      self.show_button
    end

    def showToolbarTip
      KSO_SDK.addFavorite(context)
    end

    def setFeedbackUrl(feedbackUrl)
      title_bar.feedbackUrl = feedbackUrl
    end

    def addToolButton(sender)
      setShowButton(true)
    end

    def closeClicked
      if !getShowButton
        if self.close_confirm_form.nil?
          self.close_confirm_form = CloseConfirmForm.new(
            windowTitle, "#{File.join(@context.resPath, @context.icon)}", 
            scale, info_collect, KSO_SDK.getCurrentMainWindow())
          self.close_confirm_form.onClosePane = method(:closePane)
          self.close_confirm_form.onClose = method(:closeConfirm)
          self.close_confirm_form.onAddTool = method(:addTool)
          self.close_confirm_form.onNotAddTool = method(:notAddTool)
          self.close_confirm_form.onNotAddTool = method(:notAddTool)
          self.close_confirm_form.onSetStatus = method(:setStatus)
        end

        if self.confirm_grey_form.nil?
          self.confirm_grey_form = GreyForm.new(KSO_SDK.getCurrentMainWindow())
        end

        setConfirmFormGeometry
        self.close_confirm_form.setVisible(true)
        self.confirm_grey_form.setVisible(true)
      else
        if getTipCount < 3 
          showToolbarTip
          incTipCount
        end
        self.setVisible(false)
        @onCloseClicked.call() unless @onCloseClicked.nil?
        context.hidden = true
        KSO_SDK::disableAutoStart(context)
        info_collect.infoCollect({:action=>"script_close"})
      end
      KSO_SDK.getCurrentMainWindow().installEventFilter(self)
    end

    def resizeEvent(size)
      if !self.close_confirm_form.nil? && self.close_confirm_form.isVisible
        setConfirmFormGeometry
      end
    end

    def setConfirmFormGeometry
      point = self.mapToGlobal(Qt::Point.new(0, 0))
      self.close_confirm_form.setGeometry(
        point.x, 
        point.y + self.height - CLOSE_CONFIRM_FORM_HEIGHT * scale, 
        self.width, 
        CLOSE_CONFIRM_FORM_HEIGHT * scale)
      self.confirm_grey_form.setGeometry(
        point.x - 1, point.y, self.width,  
        self.height - CLOSE_CONFIRM_FORM_HEIGHT * scale)
    end

    def closePane(sender)
      confirm_grey_form.setVisible(false) unless confirm_grey_form.nil?
      sender.setVisible(false)
      self.setVisible(false)
      context.hidden = true
    end

    def closeConfirm(sender)
      confirm_grey_form.setVisible(false) unless confirm_grey_form.nil?
      sender.setVisible(false)
    end

    def addTool(sender)
      setShowButton(true)
    end

    def notAddTool(sender)
      setShowButton(false)
    end

    Move = 13                              # move widget
    Resize = 14                            # resize widget
    def eventFilter(o, e)
      resizeEvent(0) if e.type == Move || e.type == Resize
      super(o, e)
    end

    def setVisible(visible)
      super(visible)

      if !self.close_confirm_form.nil?
        if visible
          if !@close_confirm_form_visible.nil? && @close_confirm_form_visible
            self.close_confirm_form.setVisible(visible)
            self.confirm_grey_form.setVisible(visible)
            @close_confirm_form_visible = nil
          end
        else
          if self.close_confirm_form.visible
            @close_confirm_form_visible = true
            self.close_confirm_form.setVisible(visible)
            self.confirm_grey_form.setVisible(visible)
          end
        end
      end

      title_bar.setAssistantPopupVisible(visible)
      title_bar.setSharePopupVisible(visible)
    end

  end

  SW_SHOWNORMAL = 1

  # :nodoc:all
  class TaskPaneTitle < FormWindow

    attr_writer :feedbackUrl
    attr_accessor :title, :show_button, :onClosePane, :assistant_popup, :info_collect, :share_popup, :shareUrl
    attr_accessor :scale

    define_label :title_label
    define_button :close_button, :feedback_button, :add_to_toolbar_button, :share_button

    def initialize(title, scale, parent, info_collect)
      super(parent)
      self.title = title
      self.scale = scale
      self.info_collect = info_collect

      feedback_button.setFixedSize(Qt::Size.new(21 * scale, 21 * scale))
      feedback_button.setStyleSheet(
        "QPushButton{border:0px;border-image:url(:images/feedback_normal.png);} 
         QPushButton:hover{border:0px;border-image:url(:images/feedback_hovered.png);}")
      feedback_button.setCursor(Qt::Cursor.new(Qt::PointingHandCursor))
      feedback_button.setToolTip("问题反馈")
      feedback_button.onClicked = :feedbackClicked
      feedback_button.setGeometry(4 * scale, 9 * scale, 21 * scale, 21 * scale)

      font_size = 12 * scale
      title_label.setText("我要吐槽...")
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
      add_to_toolbar_button.setGeometry(parent.width - 51 * scale, 9 * scale, 21 * scale, 21 * scale)

      close_button.setFixedSize(Qt::Size.new(21 * scale, 21 * scale))
      close_button.onClicked = :closeClicked
      close_button.setToolTip("关闭")
      close_button.instance_eval(DRAW_CLOSE_BUTTON_SCRIPT)      
      close_button.setGeometry(parent.width - 25 * scale, 10 * scale, 21 * scale, 21 * scale)

      share_button.setFixedSize(Qt::Size.new(21 * scale, 21 * scale))
      share_button.setStyleSheet(
          "QPushButton {border:0px;border-image:url(:images/ic_share_normal.png);}
           QPushButton:hover {border:0px;border-image:url(:images/ic_share_hover.png);}")
      share_button.setCursor(Qt::Cursor.new(Qt::PointingHandCursor))
      share_button.setToolTip("分享提示")
      share_button.onClicked = :onShareClicked
      share_button.setGeometry(parent.width - 82 * scale, 9 * scale, 21 * scale, 21 * scale)
      share_button.setVisible(false)
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
      info_collect.infoCollect({:action=>"script_feedback"})
    end

    def closeClicked
      if !self.assistant_popup.nil? && self.assistant_popup.isVisible
        self.assistant_popup.setVisible(false)
      end
      self.onClosePane.call unless self.onClosePane.nil?
    end

    def onAddToBoolbarClicked
      if self.assistant_popup.nil?
        self.assistant_popup = AssistantPopup.new(
          title, scale, self.parent, info_collect)
        assistant_popup.onAddToolButton = self.parent.method(:addToolButton)
        assistant_popup.onShowToolbarTip = self.parent.method(:showToolbarTip)
        assistant_popup.onSetStatus = self.parent.method(:setStatus)        
      end
      assistant_popup.setShowButton(self.show_button)
      assistant_popup.show
      setAssistantPopupGeometry
      info_collect.infoCollect({:action=>"script_fav"})
    end

    def setAssistantPopupGeometry
      return if self.assistant_popup.nil?
      if self.assistant_popup.isVisible
        point = self.mapToGlobal(Qt::Point.new(0, 0))
        self.assistant_popup.setGeometry(
          point.x + (self.width - AssistantPopupWidth * scale) / 2, 
          point.y + 43 * scale, 
          AssistantPopupWidth * scale, 
          AssistantPopupHeight * scale)
      end
    end

    def onShareClicked
      if self.share_popup.nil?
        self.share_popup = SharePopup.new(
            title, scale, self.parent, info_collect)
      end
      share_popup.setShareUrlText(shareUrl)
      share_popup.show
      setSharePopupGeometry
    end

    def setSharePopupGeometry
      return if self.share_popup.nil?
      if self.share_popup.isVisible
        point = self.mapToGlobal(Qt::Point.new(0, 0))
        self.share_popup.setGeometry(
            point.x + (self.width - SharePopupWidth * scale) / 2,
            point.y + 39 * scale,
            SharePopupWidth * scale,
            SharePopupHeight * scale)
      end
    end

    def setAssistantPopupVisible(visible)
      return if assistant_popup.nil?
      if visible
        if !assistant_popup.nil? && @assistant_popup_visible
          assistant_popup.setVisible(visible)
          @assistant_popup_visible = nil
        end
      else
        if assistant_popup.visible
          @assistant_popup_visible = true
          assistant_popup.setVisible(visible)
        end
      end
    end

    def setSharePopupVisible(visible)
      return if share_popup.nil?
      if visible
        if !share_popup.nil? && @share_popup_visible
          share_popup.setVisible(visible)
          @share_popup_visible = nil
        end
      else
        if share_popup.visible
          @share_popup_visible = true
          share_popup.setVisible(visible)
        end
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
        setSharePopupGeometry
        close_button.setGeometry(parent.width - 25 * scale, 10 * scale, 21 * scale, 21 * scale)
        add_to_toolbar_button.setGeometry(parent.width - 51 * scale, 9 * scale, 21 * scale, 21 * scale)
      end
      
      super(o, e)
    end
  end
end

