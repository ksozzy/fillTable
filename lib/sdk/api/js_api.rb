=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:JavaScript调用Ruby的通用组件
=end
require_relative 'common'

module KSO_SDK

  # Js接口桥接类
  class JsBridge

    # :nodoc:
    attr_accessor :owner, :context
    
    ##
    # 回调到JS方法
    #
    # jsfunc: 方法名
    #
    # parameters: 参数

    def callbackToJS(jsfunc, parameters)
      if jsfunc.kind_of?(Hash) and !jsfunc['guid'].nil? and !jsfunc['funcName'].nil?
        require 'json'
        id = jsfunc['guid']
        jsfunc = jsfunc['funcName']
        origin = JSON.parse(parameters)
        parameters = { :id => id, :res => origin }.to_json
      end
      self.owner.callbackToJS(jsfunc, parameters)
    end

  end

  # :nodoc:all
  class JsApi < KxCommonJsApi

    JS_PARAMS = 'KxWebViewJSContext&'

    def initialize(web, context)
      super(web.webView)
      @context = context
      @web = web
      service = KSO_SDK.getCloudService()
      service.disconnect(self)

      @apiSet = {}
    end

    def closeWeb
      @web.setVisible(false)
    end

    def setWebDragArea(left, top, width, height)
      klog "#{left}, #{top}, #{width}, #{height}"
      @web.onSetDragArea(Qt::Rect.new(left, top, width, height))
    end

    def register(api)
      if api.kind_of?(JsBridge) and @apiSet[api.class].nil?
        @apiSet[api.class] = 1

        api.public_methods(false).each do | method |
          m = api.method(method)
          klog m.name
          JsApi.slots(getSlotMethod(m))
          self.define_singleton_method m.name do | args |
            kw, par = getParametersArray(parseContextArgs(args), m)
            klog kw, par
            if par.empty?
              result = m.call()
            else
              if kw
                result = m.call(par)
              else
                result = m.call(*par)
              end
            end
            klog result
            setResult(args, Qt::Variant.new(result)) unless result.nil?
          end
        end
        api.owner = self
        api.context = @context
      end
    end

    # 从Context中获取方法所需参数
    def getParametersArray(context, method)
      param_arr = getParmas(method)
      kw = isKw(method.parameters())
      klog "params_arr:#{param_arr}"
      
      if kw
        args_arr = {}
        param_arr.each do |i|
          args_arr[i.to_sym] = getValue(context[i]) if context.has_key?(i)
        end
      else
        args_arr = []
        param_arr.each do |i|
          val = context[i]
          val = getValue(val)
          args_arr << val unless val.nil?
        end
      end
      return kw, args_arr
    end

    # 判断是否是 keyword 参数列表  def func(a:,b:2) end
    def isKw(arr)
      klog arr
      return false if arr.nil? or arr.empty?
      arr[0][0].to_s().start_with?('key')
    end

    # 递归将Variant类型转ruby原生数据类型
    def getValue(val)
      return val if val.nil?
      if val.kind_of?(Qt::Variant)
        type = val.type()
        case type
          when Qt::MetaType.QVariantList
            val = val.toList.map do | item |
              getValue(item)
            end
          when Qt::MetaType.QVariantMap
            val = val.toMap
            val.each_key do | key |
              val[key] = getValue(val[key])
            end
          else
            val = val.value()
        end
      end
      val
    end

    # 解析方法参数列表
    def getParmas(method)
      method.parameters().map do | param |
        param[1].to_s
      end
    end

    def getSlotMethod(method)
      "#{method.name}(#{JS_PARAMS})"
    end

    def cloneSingletonMethod(src)
      target = self
      src.instance_eval do      
        cloneSingletonMethodTo(target)
      end
    end

    private 

    def cloneSingletonMethodTo(target)
      @apiSet.each do |clazz, flag|
        apiObject = clazz.new
        target.register(apiObject)
      end
    end
  end
  
end