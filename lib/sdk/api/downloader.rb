=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:实现文件下载
=end

require 'net/http'
require 'openssl'

module KSO_SDK

  # :nodoc:all
  class Net::HTTP::GetHead < Net::HTTPRequest
    METHOD = 'GET'
    REQUEST_HAS_BODY = false
    RESPONSE_HAS_BODY = false
  end

  # :nodoc:all
  class DownLoader < Qt::Object

    # 超时时间为5秒
    DOWNLOAD_MAX_TIMEOUT 	= 5
    #DirectGetOperation
    DIRECT_GET_OPERATION = 5

    slots 'onDownloadProgress(long long, long long, long long)',
          'onDownloadSuccess(long long, const QString&)',
          'onDownloadError(long long, int, int)'

    attr_writer :onProgress, :onSuccess, :onError

    def initialize()
      super(nil)
      @taskQueue = {}
      @taskSize = {}
    end

    def createDownloadTask
      task = KSmokeDownloader.new(self)
      task.setOperation(DIRECT_GET_OPERATION)
      task.setConnectionTimeout(DOWNLOAD_MAX_TIMEOUT)
      connect(task, SIGNAL('onSuccess(long long, const QString&)'),
              self, SLOT('onDownloadSuccess(long long, const QString&)'))
      connect(task, SIGNAL('onError(long long, int, int)'),
              self, SLOT('onDownloadError(long long, int, int)'))
      connect(task, SIGNAL('onProgress(long long, long long, long long)'),
              self, SLOT('onDownloadProgress(long long, long long, long long)'))
      return task
    end

    def download(url)
      savePath, fileSize = getTempSavePath(url)
      if savePath.nil?
        return -1, nil
      end
      if File.exist?(savePath)
        onDownloadSuccess(0, savePath)
        return 0, URI::escape(savePath)
      else
        task = createDownloadTask
        taskId = task.download(url, savePath)
        @taskQueue[taskId] = task
        @taskSize[taskId] = fileSize
        return taskId, URI::escape(savePath)
      end
    end

    def cancel(taskId)
      task = @taskQueue[taskId]
      if !task.nil?
        return task.cancel
      end
      return false
    end

    def onDownloadSuccess(taskId, savePath)
      @onSuccess.call(taskId, savePath) unless @onSuccess.nil?
    end

    def onDownloadError(taskId, errorCode, httpCode)
      @onError.call(taskId, errorCode, httpCode) unless @onError.nil?
    end

    def onDownloadProgress(taskId, totalBytes, receivedBytes)
      @onProgress.call(taskId, totalBytes == 0? @taskSize[taskId] : totalBytes, receivedBytes) unless @onProgress.nil?
    end

    def makeTempDir
      @tempDir = "#{KxUtil.getOfficeHome}/cache"
      Dir.mkdir(@tempDir) if !Dir.exists?(@tempDir)
      @tempDir += "/paper"
      Dir.mkdir(@tempDir) if !Dir.exists?(@tempDir)
    end

    def getTempSavePath(url)
      makeTempDir if @tempDir.nil? 

      uri = URI(url)
      host, path = url.split(/#{uri.host}/)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = uri.scheme == 'https'
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      request = Net::HTTP::GetHead.new(path, nil)
      response = http.request(request)

      content = response['Content-Disposition']
      if !content.nil?
        fileSize = response['file-size']
        if fileSize.nil?
          fileSize = 0
        end
        attachment, filename = content.split(/filename=/)
        regex = /\"([^\"]*)\"/
        if !(filename =~ regex).nil?
          filename = filename.split(regex)          
          filename = URI::unescape(filename[1])
        end
        return @tempDir + "/" + filename, fileSize.to_i
      else
        return nil, 0
      end
    end
  end
end