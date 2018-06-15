=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:Office组件类
=end

module KSO_SDK::Web

  # only wpp
  if KSO_SDK::isWpp

    class Wpp < KSO_SDK::JsBridge
      
      def openLocalFile(local_file)
        if !local_file.nil?
          if File.exist?(local_file)
            KSO_SDK::Application.Presentations.Open(local_file)
            return true
          else
            return false
          end
        else
          josn_result = {:result=>false,:error_message=>"local_file is null!"}
          return josn_result.to_json
        end
      end
      
    end
  end

end