=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/12.
  #--Description: 带有WebView的侧边栏
=end
require_relative 'taskpane'
require_relative 'webview'
require_relative '../api/common'

module KSO_SDK::View

  TIP_PICTURE_GEOMETRY = Qt::Rect.new(0, 126, 205, 83)
  CLOSE_CONFIRM_FORM_HEIGHT = 346

  class CloseConfirmForm < SDK::FormWindow

    attr_writer :onClose, :onAddTool, :onNotAddTool, :onClosePane, :onSetStatus
    attr_accessor :scale

    define_label :tip_picture, :tip_line, :button_picture, :button_title, :menu_text, :bulb_picture
    define_button :close_button, :add_tool_button
    define_radio_button :add_toolbar_radio, :not_need_tool_radio

    def initialize(title, icon, scale, parent = nil)
      super(parent)

      self.scale = scale

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
      tip_line.setStyleSheet("QLabel {
        color:rgb(34, 34, 38);}")
      tip_line.setFont(font)  
    end

    def setToolButton
      font_size = 14 * scale
      add_tool_button.setText("确定")
      add_tool_button.setStyleSheet(
        "QPushButton {
          background: rgb(97, 153, 242);
          border: none;
          color:rgb(255, 255, 255); font-family: \"微软雅黑\"; font-size:#{font_size}px;}")
      add_tool_button.setCursor(Qt::Cursor.new(Qt::PointingHandCursor))
      add_tool_button.onClicked = :addToolClicked
    end

    def closeClicked
      @onClose.call(self) unless @onClose.nil?
    end

    def addToolClicked
      if add_toolbar_radio.isChecked
        @onAddTool.call(self) unless @onAddTool.nil?
        KSO_SDK::Web::Internal::infoCollect({:action=>"script_close_ribbon"})
      else
        @onNotAddTool.call(self) unless @onNotAddTool.nil?
        KSO_SDK::Web::Internal::infoCollect({:action=>"script_close_never"})
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
      button_picture.setGeometry(
        91 * scale + dx, 162 * scale, 20 * scale, 20 * scale)
      button_title.setGeometry(
        79 * scale + dx, 185 * scale, 68 * scale, 14 * scale)
      # bulb_picture.setGeometry(48 + dx, 37, 32, 32)

      close_button.setGeometry(self.width - 25 * scale, 4 * scale, 21 * scale, 21 * scale)
      
      tip_line.setGeometry(30 * scale + dx, 43 * scale, 278 * scale, 22 * scale)

      add_tool_button.setGeometry(
        55 * scale, 290 * scale, self.width - 110 * scale, 36 * scale)

      add_toolbar_radio.setGeometry(
        40 * scale + dx, 97 * scale, 288 * scale, 17 * scale)
      not_need_tool_radio.setGeometry(
        40 * scale + dx, 232 * scale, 288 * scale, 17 * scale)
    end
  end
  
  class GreyForm < SDK::FormWindow

    def initialize(parent = nil)
      super(parent)

      setAttribute(Qt::WA_DeleteOnClose, false);
      setWindowFlags(Qt::FramelessWindowHint | Qt::DialogType)
      setStyleSheet(
        "QWidget {background: rgb(0, 0, 0);}")
      setWindowOpacity(0.4)
    end

  end

  ##
  # 侧边栏WebView

  class WebViewPane < TaskPane

    attr_accessor :close_confirm_form
    attr_accessor :confirm_grey_form
    attr_accessor :icon

    ##
    # 初始化
    #
    # title: 标题
    #
    # parent: 父容器
    #
    # jsApi: js接口类
    #
    # url: 网址

    def initialize(
      context:nil,
      title:, 
      parent:nil,
      url:, 
      jsApi:, 
      icon:,
      feedbackUrl:)
      super(title, parent, context)

      appId = context.scriptId unless context.nil?
      self.icon = icon
      objectName = "kso_application_scene_#{appId}"
      setObjectName(objectName)
      writeRegistry(appId, title, icon)
      readRegistry

      @webview = WebView.new(self, context)
      setWidget(@webview)

      registerJsApi(jsApi) unless jsApi.nil?
      setFeedbackUrl(feedbackUrl) unless feedbackUrl.nil?
      showUrl(url) unless url.nil?
    end

    ##
    # 注册Js接口
    #
    # apis: 对象数组

    def registerJsApi(apis)
      @webview.registerJsApi(*apis)
    end

    def closeClicked
      if !getShowButton
        if self.close_confirm_form.nil?
          self.close_confirm_form = CloseConfirmForm.new(
            windowTitle, smallIcon, scale, KSO_SDK.getCurrentMainWindow())
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
        KSO_SDK::Web::Internal::infoCollect({:action=>"script_close"})
      end
      KSO_SDK.getCurrentMainWindow().installEventFilter(self)
    end

    ##
    # 显示指定URL网页
    #
    # url: 网址

    def showUrl(url)
      @webview.showUrl(url)
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

    def smallIcon
      if @small_icon.nil?
        @small_icon = self.icon.insert(self.icon.length - 4, "_s")
        if !File.exist?(@small_icon)
          @small_icon = self.icon
        end
      end
      @small_icon
    end

    Move = 13                              # move widget

    def eventFilter(o, e)
      resizeEvent(0) if e.type == Move
      super(o, e)
    end

    def self.run(
      context: nil,
      title: '', 
      parent: KSO_SDK.getCurrentMainWindow(),
      url:, 
      jsApi:, 
      icon:,
      feedbackUrl:)
      return if context.nil?
      @list = {} if @list.nil?
      pane = @list[context.scriptId]
      if pane.nil?
        pane = WebViewPane.new(
          context: context,
          title: title, 
          parent: parent,
          url: url, 
          jsApi: jsApi, 
          icon: icon,
          feedbackUrl: feedbackUrl)
        @list[context.scriptId] = pane
      else
        pane.setVisible(true)
      end
    end
  end

end