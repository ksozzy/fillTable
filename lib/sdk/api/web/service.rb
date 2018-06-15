=begin
  #--Description:Service 组件类
=end
require 'json'
require 'digest/md5'

module KSO_SDK::Web

  module Internal

    class ServiceImpl < Qt::Object

      attr_accessor :network, :owner

      slots 'onFinished(QNetworkReply*)'

      # parent is WebView
      def initialize(owner)
        super(nil)
        self.owner = owner
      end

      def get(url)
        checkNetwork
        self.network.get(Qt::NetworkRequest.new(Qt::Url.new(url)))
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
          owner.callbackToJS("onServiceFinished", josn.to_json)
        rescue
        end
        klog '[Network:', reply.url.toString(), josn.to_json, 'End]'
        reply.deleteLater
      end

      def checkNetwork
        if self.network.nil?
          self.network = Qt::NetworkAccessManager.new(self)
          sid = KSO_SDK.getCloudService().getUserInfo().sessionId
          cookieJar = Qt::NetworkCookieJar.new()
          cookie = Qt::NetworkCookie.new(Qt::ByteArray.new('wps_sid'), Qt::ByteArray.new(sid))
          cookieJar.setCookiesFromUrl([cookie], Qt::Url.new('http://assist.docer.wps.cn/'))
          self.network.setCookieJar(cookieJar)
          connect(self.network, SIGNAL('finished(QNetworkReply *)'),
            self, SLOT('onFinished(QNetworkReply *)'))
        end
      end
    end
  end
  
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

    def dbPostData(file_id, table, key, value, include_user = false, context = nil)
      hash = baseInfo
      hash.delete(:user_id) unless include_user
      hash[:file_id] = file_id unless file_id.nil?
      hash[:table] = table
      if value.kind_of?(Hash)
        hash[key.to_sym] = value.to_json
      else
        hash[key.to_sym] = value
      end

      dbGet(toUrl("edit?", hash.sort), context)
    end

    def dbPostCommonData(table, key, value, context = nil)
      dbPostData(nil, table, key, value, true, context)
    end
    
    def dbGetData(file_id, table, include_comm = false, include_users = true, context = nil)
      hash = baseInfo
      hash[:file_id] = file_id unless file_id.nil?
      hash[:table] = table
      hash[:include_comm] = include_comm
      hash.delete(:user_id) if include_users

      dbGet(toUrl("get?", hash.sort), context)
    end

    def dbGetCommonData(table, context = nil)
      dbGetData(nil, table, false, true, context)
    end

    def dbRemoveData(file_id, table, context)
      hash = baseInfo()
      hash[:file_id] = file_id
      hash[:table] = table
      hash[:is_dev] = false

      dbGet(toUrl("remove?", hash.sort), context)
    end

    private

    def toSign(hash)
      sign_temp = ""
      hash.each do |key, val|
        sign_temp << "#{key}=#{val}"
      end

      sign_temp << "#{self.context.appKey}"
      puts sign_temp
      Digest::MD5.hexdigest(sign_temp)
    end

    def toUrl(head, hash)
      url = "http://assist.docer.wps.cn/mongotest/" << head
      hash.each_with_index do | entry, index|
        key = entry[0]
        val = entry[1]
        if index == 0
          url << "#{key}=#{val}"
        else
          url << "&#{key}=#{val}"
        end
      end

      sign = toSign(hash)
      url << "&sign=#{sign}"

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

  end

end