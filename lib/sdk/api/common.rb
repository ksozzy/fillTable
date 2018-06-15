=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:Office组件类
=end
require 'win32ole'
require_relative 'event'
require_relative 'settings'

module KSO_SDK

  public

  class App

    def initialize(context)
      @context = context
    end

    def context
      @context
    end

    def dispatchCreate(context)
      newTaskPane(context) if @taskPane.nil?
      onCreate(context)

      bindPage(self) if context.bindPage
    end

    def setContentWidget(widget)
      @taskPane.setWidget(widget)
      widget.setParent(@taskPane)
    end

    def onCreate(context)
    end

    def onDestroy()
    end

    def setVisible(visible)
      @taskPane.setVisible(visible)
    end

    private 

    # 插件绑定文档
    def bindPage(app)
      startedPage = KSO_SDK::ActivePage()
      bindFullName = startedPage.FullName
      pageEvent = PageEvent.new()
      pageEvent.bindActive do | fullname |
        return if bindFullName.nil?
        current = bindFullName.eql?(fullname)
        app.setVisible(current)
      end

      return if bindFullName.nil?
      pageEvent.bindClose startedPage do ||
        pageEvent.unbindActive()
        app.setVisible(false)
      end
    end

    def newTaskPane(context)
      @taskPane = KSO_SDK::View::TaskPane.new(context.title, nil, context)
      @taskPane.onCloseClicked = lambda do
        klog "close"
        self.onDestroy()
      end
      @taskPane.setFeedbackUrl(context.feedbackUrl) unless context.feedbackUrl.nil?
      KSO_SDK.getCurrentMainWindow().addDockWidget(Qt::RightDockWidgetArea, @taskPane, Qt::Horizontal)
    end
    
  end

  # 插件启动入口
  def self.start(dir:, page:)
    context = newContext(dir, 'config.json')
    registerApp(context)
    instance = page.new(context)
    instance.dispatchCreate(context)
  end

  # 获取存储文件夹
  def self.getStorageDir(context)
    dir = KingsoftDir
    Dir.mkdir(dir) unless File.exist?(dir)
    dir = File.join(dir, context.scriptId)
    Dir.mkdir(dir) unless File.exist?(dir)
    dir
  end

  # 获取宿主窗体
  def self.getCurrentMainWindow
    $kxApp.currentMainWindow
  end

  # 获取WPS 操作文档对象
  def self.getApplication
    Application
  end

  # 获取当前文档
  def self.ActivePage
    page = nil
    case AppType
      when :wps then page = Application.ActiveDocument
      when :et then page = Application.ActiveWorkbook
      when :wpp then page = Application.ActivePresentation
    end
    page
  end

  #添加当前插件到菜单栏
  def self.addFavorite(context)
    settings = Settings.new(context)
    settings.write(IsShowButton, 1) unless settings.keyExist?(IsShowButton)

    if @add_doc_tool_command.nil?
      @add_doc_tool_command = 
        KSO_SDK.getCurrentMainWindow().commands.findCommandByIdMso("AddDocumentToolCommand")
    end
    if !@add_doc_tool_command.nil?
      @add_doc_tool_command.setProperty("app_id", Qt::Variant::fromValue(context.scriptId))
      @add_doc_tool_command.trigger
    end
    nil
  end

  #从菜单栏中移除
  def self.removeFavorite(context)
    settings = Settings.new(context)
    settings.write(IsShowButton, 0) unless settings.keyExist?(IsShowButton)
  end

  # :nodoc:
  def self.getCloudService
    $kxApp.cloudServiceProxy
  end

  # :nodoc:
  def self.getAppType
    AppType
  end

  # :nodoc:
  def self.isWps
    AppType == :wps
  end

  # :nodoc:
  def self.isWpp
    AppType == :wpp
  end

  # :nodoc:
  def self.isEt
    AppType == :et
  end

  private

  # :nodoc:
  Application = WIN32OLE::setdispatch(KxWin32ole::getDispatch)
  
  # :nodoc:
  AppType = $kxApp.applicationName.to_sym()

  # :nodoc:
  KingsoftDir = File.join(KxUtil.getOfficeHome, 'krubytemplate')

  ApplicationName = "application_name"
  Icon = "icon"
  IsShowButton = "is_show_button"
  RunFirst = "run_first"
  StartShow = "start_show"
  Title = "title"

  # :nodoc:
  def self.newContext(dir, name)
    require 'json'
    json = File.read(File.join(dir, name))
    json = JSON.parse(json)
    json['pluginPath'] = dir
    json['resPath'] = File.join(dir, 'res')

    context = Object.new()
    json.each do |key, val|
      context.define_singleton_method key do
        val
      end
    end
    context.define_singleton_method 'to_s' do 
      json.to_s
    end
    context
  end

  # :nodoc:
  # 注册插件信息
  def self.registerApp(context)
    settings = Settings.new(context)
    settings.write(Title, context.title) unless settings.keyExist?(Title)
    settings.write(ApplicationName, "#{KSO_SDK::getAppType()}") unless settings.keyExist?(ApplicationName)
    settings.write(Icon, "#{File.join(context.resPath, context.icon)}") unless settings.keyExist?(Icon)
  end

end