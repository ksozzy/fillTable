=begin
  #--Created by caidong<caidong@wps.cn> on 2018/4/25.
  #--Description:注册表操作类
=end
module KSO_SDK

  class Settings

    def initialize(context, subDirs = [])
      @context = context
      @settings = KSettings.new()
      [$kxApp.productVersion, "plugins", 'krubytemplate', @context.scriptId.to_s].concat(subDirs).each do | item |
        @settings.beginGroup(item)
      end
    end
  
    def read(key, defval)
      val = @settings.value(key)
      return defval if val.isNull
      val
    end
  
    def write(key, val)
      @settings.setValue(key, Qt::Variant::fromValue(val))
    end

    def keyExist?(key)
      return !read(key, nil).nil?
    end

    def readBool(key, default = false)
      val = read(key, nil)
      return default if val.nil?
      val.toBool()
    end
  
    def readInt(key, default = false)
      val = read(key, nil)
      return default if val.nil?
      val.toInt()
    end
  
    def remove(key)
      @settings.remove(key)
    end
  end

  
end
