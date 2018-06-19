=begin
  #--Created by caidong<caidong@wps.cn> on 2018/4/28.
  #--Description:引导页接口类
=end
module KSO_SDK::Internal

  class Guide < KSO_SDK::JsBridge

    # 启动插件首页
    def startMain(isAddToMenu)
      KSO_SDK::addFavorite(context) if isAddToMenu
      KSO_SDK::setFirstStart(context, false)
      app = KSO_SDK::currentApp(context)
      app.dispatchCreate(app.context, false)
    end

    # 不需要不再启动
    def turnDown()
      KSO_SDK::currentApp(context).setVisible(false)
      KSO_SDK::disableAutoStart(context)
    end

  end
  
end