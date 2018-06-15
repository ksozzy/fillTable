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

    attr_accessor :service

    module_function

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
			"script"
		end

		def getChannel
			KxInfoCollHelper.getMC
    end
    
    def getSid
      $scriptId
    end

    def getAppid
      $appId
    end

    def infoCollect(args)
      action = (!args[:action].nil?? args[:action] : getAction)
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
			params << "&type=#{getType}"
			params << "&action=#{action}"
			params << "&tid=#{tid}" if !tid.nil?
      params << "&sid=#{sid}"
      params << "&appid=#{appid}"
      params << "&uid=#{uid}"
      
			params << "&hdid=#{getHdid}"
			params << "&uuid=#{getUuid}"
	
      url << KxInfoCollHelper.base64Encode(params)

      @network = NetworkWrap.new if @network.nil?
      @network.get(url)
    end
  end

  # 信息收集接口

  class InfoCollect < KSO_SDK::JsBridge

    attr_accessor :service

    public

    # 下载文件
    #
    # url: 下载地址

    def infoCollect(args)
      Internal::infoCollect(args)
    end

  end

end