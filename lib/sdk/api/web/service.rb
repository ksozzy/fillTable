=begin
  #--Description:Service 组件类
=end
require 'json'
require 'digest/md5'

module KSO_SDK::Web

  module Internal

    class ServiceImpl < Qt::Object

      attr_accessor :network, :owner
      attr_accessor :callbackName

      slots 'onFinished(QNetworkReply*)'

      # parent is WebView
      def initialize(owner)
        super(nil)
        self.owner = owner
        self.callbackName = "onServiceFinished"
      end

      def get(url)
        checkNetwork
        request = Qt::NetworkRequest.new(Qt::Url.new(url))
        cookie = "wps_sid=#{KSO_SDK::getCloudService().getUserInfo().sessionId};"
        request.setRawHeader(Qt::ByteArray.new('Cookie'), Qt::ByteArray.new(cookie)) if KSO_SDK::getCloudService().getUserInfo().logined
        klog request.rawHeader(Qt::ByteArray.new('Cookie'))
        self.network.get(request)
      end

      private

      def onFinished(reply)
        if reply.error == Qt::NetworkReply::NoError
          bytes = reply.readAll
          josn = JSON.parse(bytes.data.force_encoding("UTF-8"))
        else
          josn = {:code => 0, :message => "reply error is #{reply.error}"}
        end
        begin
          josn[:context] = reply.objectName() unless reply.objectName().nil?
          owner.callbackToJS(callbackName, josn.to_json)
        rescue
        end
        klog '[Network:', reply.url.toString(), *getHeaders(reply.request()), josn.to_json, 'End]'
        reply.deleteLater
      end

      def getHeaders(request)
        list = ['Headers:']
        request.rawHeaderList().each do |header|
          list << "#{header}:#{request.rawHeader(Qt::ByteArray.new("Cookie")).data}"
        end
        list << 'Headers End'
        return *list
      end

      def checkNetwork
        if self.network.nil?
          self.network = Qt::NetworkAccessManager.new(self)
          connect(self.network, SIGNAL('finished(QNetworkReply *)'),
            self, SLOT('onFinished(QNetworkReply *)'))
        end

      end

    end # end ServiceImpl

  end # end Internal
  

  class Service < KSO_SDK::JsBridge

    def initialize
      @impl = Internal::ServiceImpl.new(self)
    end

    def dbGet(url, context = nil)
      reply = @impl.get(url)
      reply.setObjectName(context) unless context.nil?
      return nil
    end

    def dbCreatUniqueFileId(context = nil)
      hash = baseInfo
      dbGet(toUrl("getfileid?", hash.sort), context)
    end

    def dbPostData(file_id: nil, table:, key:, value:, include_user: false, context: nil)
      postDbData(file_id, table, key, value, include_user, context)
    end

    def dbPostCommonData(table, key, value, context = nil)
      postDbData("00000000-0000-0000-0000-000000000000", table, key, value, false, context)
    end

    def dbPostUserData(table, key, value, context = nil)
      postDbData(nil, table, key, value, true, context)
    end

    def postDbData(file_id, table, key, value, include_user = false, context = nil)
      hash = baseInfo
      hash.delete(:user_id) unless include_user
      hash[:file_id] = file_id unless file_id.nil?
      hash[:table] = table
      if value.kind_of?(Hash)
        hash[key.to_sym] = value.to_json
      else
        hash[key.to_sym] = value.to_s
      end
      dbGet(toUrl("edit?", hash.sort), context)
    end
  
    def dbGetData(file_id:nil, table:, include_comm: false, include_users: true, context: nil)
      getDbData(file_id, table, include_comm, include_users, context)
    end

    def getDbData(file_id, table, include_comm = false, include_users = true, context = nil)
      hash = baseInfo
      hash[:file_id] = file_id unless file_id.nil?
      hash[:table] = table
      hash[:include_comm] = include_comm
      hash.delete(:user_id) if include_users
      dbGet(toUrl("get?", hash.sort), context)
    end

    def dbGetCommonData(table, context = nil)
      getDbData("00000000-0000-0000-0000-000000000000", table, true, true, context)
    end

    def dbGetUserData(table, context = nil)
      getDbData(nil, table, false, false, context)
    end

    def dbRemoveData(file_id, table, context)
      hash = baseInfo()
      hash[:file_id] = file_id
      hash[:table] = table
      hash[:is_dev] = false
      dbGet(toUrl("remove?", hash.sort), context)
    end

    def toUrl(head, hash)
      checkAssistant

      keys = Array.new
      values = Array.new

      hash.each do |key, val|
        keys << Qt::Variant.new(key.to_s)
        values << Qt::Variant.new(val.to_s)
      end

      url = assistant.makeUrl(head, Qt::Variant.new(keys), Qt::Variant.new(values))
      return url
    end

    def baseInfo
      info = {
        :app_db => "#{self.context.appDb}",
        :app_id => "#{self.context.appId}",
        :is_dev => self.context.isDev
      }
      if KSO_SDK.getCloudService().getUserInfo().logined
        info[:user_id] = KSO_SDK.getCloudService().getUserInfo().userId.to_s
      end
      info
    end

    def checkAssistant
      @assistant = KSmokeDbAssistant.new(context.dbService) if assistant.nil?
    end
    
    private :toUrl, :baseInfo, :postDbData, :getDbData, :dbGet

    private

    def assistant
      @assistant
    end

  end # end Service
  
end # end module