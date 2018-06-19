=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:下载接口
=end
require 'json'
require_relative '../js_api'
require_relative '../downloader'

module KSO_SDK::Web

  # JS下载接口
  class Download < KSO_SDK::JsBridge

    public

    # 下载文件
    #
    # url: 下载地址

    def downLoadFile(url, local_file = nil)
      checkDownLoader
      if url.nil?
        json_result = {:id => 0}
        return json_result.to_json
      else
        taskId, localFile = @download.download(url, local_file)
        json_result = {:id => taskId, :local_file => localFile}
        return json_result.to_json
      end
    end
    
    private

    def onDownloadProgress(taskId, totalBytes, receivedBytes)
      josn_result = {:id => taskId, :total_bytes => totalBytes, :received_bytes => receivedBytes}
      callbackToJS("onDownloadProgress", josn_result.to_json)
    end

    def onDownloadSuccess(taskId, savePath)
      josn_result = {:id => taskId, :local_file => savePath}
      callbackToJS("onDownloadSuccess", josn_result.to_json)
    end

    def onDownloadError(taskId, errorCode, httpCode)
      josn_result = {:id => taskId, :error_code => errorCode, :http_code => httpCode}
      callbackToJS("onDownloadError", josn_result.to_json)
    end

    def checkDownLoader
      if @download.nil?
        @download = KSO_SDK::DownLoader.new(context)
        @download.onProgress = lambda do |taskId, totalBytes, receivedBytes|
          onDownloadProgress(taskId, totalBytes, receivedBytes)
        end
        @download.onSuccess = lambda do |taskId, savePath|
          onDownloadSuccess(taskId, savePath)
        end
        @download.onError = lambda do |taskId, errorCode, httpCode|
          onDownloadError(taskId, errorCode, httpCode)
        end
      end
    end

  end

end