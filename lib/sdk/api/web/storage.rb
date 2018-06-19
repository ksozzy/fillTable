=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:下载接口
=end

module KSO_SDK::Web

  # JS下载接口
  class Storage < KSO_SDK::JsBridge

    public

    # 获取 localStorageGet
    #
    def localStorageGet(key)
      settings = KSO_SDK::Settings.new(context)
      value = settings.read(key, nil)
      if value.nil? 
        nil
      else
        return value.value
      end
    end

    # 设置 localStorageSet
    #
    def localStorageSet(key, value)
      settings = KSO_SDK::Settings.new(context)
      settings.write(key.to_s, value)
      nil
    end

    # 设置 localStorageRemove
    #
    def localStorageRemove(key)
      settings = KSO_SDK::Settings.new(context)
      settings.remove(key)
      nil
    end
  end

end