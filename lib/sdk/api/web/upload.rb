=begin
  #--Description:上传金山云接口
=end

require 'json'

module KSO_SDK::Web

  module Internal

    class Uploader < Qt::Object

      attr_accessor :onFileUploadStarting, :onUploadFileSucceeded, :onUploadFileFailed
      attr_accessor :ks3_uploader

      slots 'fileUploadStarting(const QString&, int)',
            'uploadFileSucceeded(const QString&, int, const QString&, const QString&)',
            'uploadFileFailed(const QString&, int, const QString&)'

      def initialize
        super(nil)

        self.ks3_uploader = KSmokeks3Uploader.new
        connect(ks3_uploader, SIGNAL('onFileUploadStarting(const QString&, int)'),
                self, SLOT('fileUploadStarting(const QString&, int)'))
        connect(ks3_uploader, SIGNAL('onUploadFileSucceeded(const QString&, int, const QString&, const QString&)'),
                self, SLOT('uploadFileSucceeded(const QString&, int, const QString&, const QString&)'))
        connect(ks3_uploader, SIGNAL('onUploadFileFailed(const QString&, int, const QString&)'),
                self, SLOT('uploadFileFailed(const QString&, int, const QString&)'))
      end
      
      def fileUploadStarting(folderId, fileId)
          self.onFileUploadStarting.call(folderId, fileId) unless self.onFileUploadStarting.nil?
      end

      def uploadFileSucceeded(folderId, fileId, fileName, uniqueKey)
        self.onUploadFileSucceeded.call(folderId, fileId, fileName, uniqueKey) unless self.onUploadFileSucceeded.nil?
      end
      
      def uploadFileFailed(folderId, fileId, fileName)
        self.onUploadFileFailed.call(folderId, fileId, fileName) unless self.onUploadFileFailed.nil?
      end

      def upLoadFile(context, locate_file)
        ks3_uploader.uploadFiles(context.appId.to_s, locate_file)
      end
    end

  end

  # JS上传接口
  class Upload < KSO_SDK::JsBridge

    public

    # 上传文件到金山云
    #
    # locate_file: 本地文件

    def upLoadFile(locate_file)
      if uploader.nil?
        @uploader = Internal::Uploader.new()
        uploader.onFileUploadStarting = lambda do |folderId, fileId|
          fileUploadStarting(folderId, fileId)
        end
        uploader.onUploadFileSucceeded = lambda do |folderId, fileId, fileName, uniqueKey|
          uploadFileSucceeded(folderId, fileId, fileName, uniqueKey)
        end
        uploader.onUploadFileFailed = lambda do |folderId, fileId, fileName|
          uploadFileFailed(folderId, fileId, fileName)
        end
      end
      uploader.upLoadFile(context, locate_file)
      nil
    end

    private

    def fileUploadStarting(folderId, fileId)
      josn_result = {:file_id => fileId}
      callbackToJS("onFileUploadStarting", josn_result.to_json)
    end

    def uploadFileSucceeded(folderId, fileId, fileName, uniqueKey)
      url = "https://ks3-cn-beijing.ksyun.com/assistant/" + uniqueKey
      josn_result = {:file_id => fileId, :file_name => fileName, :url => url, :unique_key => uniqueKey}
      callbackToJS("onUploadFileSucceeded", josn_result.to_json)
    end

    def uploadFileFailed(folderId, fileId, fileName)
      josn_result = {:file_id => fileId, :file_name => fileName}
      callbackToJS("onUploadFileFailed", josn_result.to_json)
    end

    def uploader
      @uploader
    end

  end

end