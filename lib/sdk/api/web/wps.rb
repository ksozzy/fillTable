=begin
  #--Created by caidong<caidong@wps.cn> on 2018/3/11.
  #--Description: Wps组件类
=end

module KSO_SDK::Web

  # only wps
  if KSO_SDK::isWps
    
    class Event < Qt::Object

      attr_accessor :owner

      signals 'windowSelectionChange(const QString&)'
  
      slots 'onWindowSelectionChange(const QString&)'

      def initialize
        super(nil)
      end
  
      def connectChangeEvent
        connect(self, SIGNAL('windowSelectionChange(const QString&)'),
          self, SLOT('onWindowSelectionChange(const QString&)'))

        event.on_event('WindowSelectionChange') {
          |selection| onWpsWindowSelectionChange(selection)
        }
      end
  
      def onWpsWindowSelectionChange(selection)
        emit windowSelectionChange(selection.Text)
      end

      def onWindowSelectionChange(selection)
        josn_result = {:selection => selection}
        owner.callbackToJS("onWindowSelectionChange", josn_result.to_json)
      end

      private
      
      def event
        if @event.nil?
          @event = WIN32OLE_EVENT.new(KSO_SDK::Application)
        end
        @event
      end
    end
  

    class Wps < KSO_SDK::JsBridge

      def openLocalFile(local_file)
        if !local_file.nil?
          if File.exist?(local_file)
            KSO_SDK::Application.Documents.Open(local_file)
            return true
          else
            return false
          end
        else
          josn_result = {:result=>false,:error_message=>"local_file is null!"}
          return josn_result.to_json
        end
      end

      def getActiveDocumentFile()
        if !Application.ActiveDocument.nil?
          josn_result = {:active_document_file => Application.ActiveDocument.Name}
          return josn_result.to_json
        end
      end
    
      def connectSelectionChange(context)
        
        if @event.nil?
          @event = Event.new
          @event.owner = self
          @event.connectChangeEvent
        end

        nil
      end
        
    end
  end
  
end