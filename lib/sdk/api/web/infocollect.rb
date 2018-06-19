=begin
  #--Description:上传金山云接口
=end

require 'json'

module KSO_SDK::Web

  module Internal

    class NetworkWrap < Qt::Object

      slots 'onFinished(QNetworkReply*)'

      # parent is WebView
      def initialize
        super(nil)

        @network_access = Qt::NetworkAccessManager.new(self)
        connect(@network_access, SIGNAL('finished(QNetworkReply *)'),
          self, SLOT('onFinished(QNetworkReply *)'))
      end

      def get(url)
        @network_access.get(Qt::NetworkRequest.new(Qt::Url.new(url)))
      end

      private

      def onFinished(reply)
        if reply.error != Qt::NetworkReply::NoError
          puts "reply error is #{reply.error}"
        end
        reply.deleteLater
      end
    end  

    class InfoCollectImpl

      attr_accessor :context

      def initialize(context)
        @context = context
      end
        
      def getHdid
        KxInfoCollHelper.getHDID
      end

      def getUuid
        KxInfoCollHelper.getUUID
      end

      def getVersion
        KxInfoCollHelper.getVersion
      end

      def getType
        'assistant' 
      end

      ApplicationName = $kxApp.applicationName

      def getApplicationName
        ApplicationName
      end

      def getAction
        context.action
      end

      def getChannel
        KxInfoCollHelper.getMC
      end
      
      def getSid
        context.scriptId
      end

      def getAppid
        context.appId
      end

      def infoCollect(args)
        if args.kind_of?(String)
          args = transToHash(args)
        end
        return if !args.kind_of?(Hash)
        action = (!args[:action].nil?? args[:action] : getAction)
        type = (!args[:type].nil?? args[:type] : getType)
        tid = (!args[:tid].nil?? args[:tid] : nil)
        sid = (!args[:sid].nil?? args[:sid] : getSid)
        appid = (!args[:appid].nil?? args[:appid] : getAppid)
        if $kxApp.cloudServiceProxy.getUserInfo.logined
          uid = (!args[:uid].nil?? args[:uid] : $kxApp.cloudServiceProxy.getUserInfo.userId.to_s)
        else
          uid = ''
        end

        url = 'http://info.meihua.docer.com/pc/infos.ads?d='
        params = ""
        params << "&type=#{type}"
        params << "&action=#{action}"
        params << "&tid=#{tid}" if !tid.nil?
        params << "&sid=#{sid}"
        params << "&appid=#{appid}"
        params << "&uid=#{uid}"
        
        params << "&hdid=#{getHdid}"
        params << "&uuid=#{getUuid}"

        args.each do |key, value|
          params << "&#{key}=#{value}" if key != :action && key != :tid && key != :sid && key != :appid && key != :uid && key != :type
        end
      
        url << KxInfoCollHelper.base64Encode(params)

        @network = NetworkWrap.new if @network.nil?
        @network.get(url)
        url
      end

      def transToHash(json)
        obj = JSON.parse(json)
        if obj.kind_of?(Hash)
          res = {}
          obj.each do |key, value|
            res[key.to_sym] = value
          end
          return res
        end
        return obj
      end
    end
  end

  # 信息收集接口

  class InfoCollect < KSO_SDK::JsBridge

    public

    # 下载文件
    #
    # url: 下载地址

    def infoCollect(args)
      checkImpl
      impl.infoCollect(args)
    end

    private

    def checkImpl
      @impl = Internal::InfoCollectImpl.new(context) if impl.nil?
    end

    private

    def impl
      @impl
    end
  
  end

end