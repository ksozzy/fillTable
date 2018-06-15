$LOAD_PATH << "#{__dir__}/lib"
require 'sdk'
require_relative 'src/apis'
require 'Qt'

def getIcon
  path = File::dirname(__FILE__)
  result = path + '/icon.png'
  if File.exist?(result)
    result
  else
    nil
  end
end

module Demo
  
  class MainApp < KSO_SDK::App
  
    def onCreate(context)
	  web = KSO_SDK::View::WebViewWidget.new(context)
      web.showUrl(__dir__ + '\web\demo.html')
      web.registerJsApi(Sample.new())
      setContentWidget(web)      
    end

  end
  
  KSO_SDK.start(dir:__dir__, page: MainApp)
end