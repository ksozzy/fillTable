=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:用户信息相关接口
=end
require 'json'

require_relative '../js_api'
require_relative '../common'

module KSO_SDK::Web

  module Internal

    class UserImpl < Qt::Object

      attr_accessor :apiObject, :callbackName

      slots 'onUserInfoChange()'

      # parent is WebView
      def initialize(apiObject)
        super(nil)
        self.apiObject = apiObject

        service = KSO_SDK.getCloudService()

        connect(service, SIGNAL('initFinished()'), self, SLOT('onUserInfoChange()'));
        connect(service, SIGNAL('userInfoChange(int)'), self, SLOT('onUserInfoChange()'));
        connect(service, SIGNAL('logincancel()'), self, SLOT('onUserInfoChange()'));
        connect(service, SIGNAL('disconnected()'), self, SLOT('onUserInfoChange()'));

        self.callbackName = "userStateChanged"
      end

      def onUserInfoChange()
        josn_result = {:logined => $kxApp.cloudServiceProxy.getUserInfo.logined}
        apiObject.callbackToJS(self.callbackName, josn_result.to_json)
      end

    end

  end

  # JS用户相关接口

  class User < KSO_SDK::JsBridge

    def initialize
      @impl = Internal::UserImpl.new(self)
    end

    public

    # 获取用户信息
    #
    # return: json字符串
    def getUserInfo()
      user_info = KSO_SDK.getCloudService().getUserInfo()
      if user_info.logined
        json_result = {:logined=>user_info.logined,:user_id => user_info.userId,:user_name => user_info.userName}
        return json_result.to_json()
      else
        json_result = {:logined=>user_info.logined}
        return json_result.to_json()
      end
    end

    # 注册用户变化接收函数
    #
    # callbackName: 函数名
    def registerUserChanged(callbackName = 'userStateChanged')
      @impl.callbackName = callbackName;
    end

  end
end
