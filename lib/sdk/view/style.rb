#
# form.rb
# Creator： laiw
# Created: time： 2018/1/16
# Description: 实现 ruby SDK 的 样式 的封装
#
#
#

require 'Qt'

module KSO_SDK

    # :nodoc:all
    class Style < Qt::Object

        signals 'styleChange(const QString&)'
    
        def initialize
            super(nil)
    
            initStyleList
        end

        def self.default
            if self.getStyles.size > 0
                self.set self.getStyles.keys[0]
            end
        end

        def self.addObject(object)
            instance.instance_eval(
                "addObject(object)"
            )
        end

        def self.set(style_name)
            instance.instance_eval(
                "set(style_name)"
            )
        end
    
        def self.getStyles
            instance.instance_eval(
                "getStyles"
            )
        end           
       
        private
    
        def self.instance
            if !defined? @instance
                @instance = Style.new
            end
            @instance
        end 
        
        def addObject(object)
    
            if !object.respond_to?('onStyleChange')
                object.class.class_eval ("
                    slots 'onStyleChange(const QString&)'
            
                    def onStyleChange(qss_content)
                        self.setStyleSheet(qss_content)
                    end"
                    )
            end
            
            connect(self, SIGNAL('styleChange(const QString&)'),
                    object, SLOT('onStyleChange(const QString&)'))

            if defined? @qss_content
                object.setStyleSheet(@qss_content)
            end        
        end

        def set(style_name)
            if @style_list.include?(style_name)
                if !defined? @style_name or @style_name != style_name
                    @style_name = style_name
                    styleChanged(style_name)
                end
            end
        end
    
        def getStyles
            if !defined? @style_list
                @style_list = {}
            end
            @style_list
        end           
       
        def initStyleList
            @style_list = {}
            Dir[File.dirname(__FILE__) + "/style/*.qss"].sort.each do |path|
                filename = File.basename(path)
                @style_list[filename.gsub(/\.[^\.]+$/,'')]=path
            end
        end
    
        def styleChanged(style_name)
            @qss_content = ''
            File.open(@style_list[style_name]).each do |line| 
                @qss_content << line
            end   
            emit styleChange @qss_content
        end
    end
    
    # 设置默认样式
    Style::default
end