=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:Office组件类
=end
require_relative '../event'

module KSO_SDK::Web

  if KSO_SDK::isEt

    # 具有回调JS事件基类
    class BaseEvent

      attr_accessor :owner, :context

      def initialize(owner: , context:nil, eventTarget:, eventName:, jsfunc:nil, callbackJs: true)
        @event = KSO_SDK::Event.new(eventTarget: eventTarget, eventName: eventName)
        @jsFuncName = jsfunc or "on#{eventName}"
        @callbackJs = callbackJs
        self.context = context
        self.owner = owner
      end

      def connect(&block)
        @event.connect do | *args |
          result = block.call(*args)
          result[:context] = context unless context.nil?
          self.owner.callbackToJS(@jsFuncName, result.to_json()) if @callbackJs
        end
      end

      def disConnect
        @event.disConnect()
      end

    end

    # 事件管理类
    # 负责context与BaseEvent对象的映射关系，根据context绑定/解绑事件
    class EventManager

      def initialize()
        @pools = {}
      end

      def newEvent(context)
      end

      def connect(context, &block)
        (@pools[context] = newEvent(context)).connect(&block) unless @pools.has_key?(context)
      end

      def disConnect(context)
        @pools.delete(context).disConnect() if @pools.has_key?(context)
      end

    end

    # 单元格选中事件
    class SelectionChangeEvent < EventManager

      def initialize(owner: owner)
        super()
        @owner = owner
        @eventName = 'SelectionChange'
        @jsFuncName = 'onSheetSelectionChange'
      end

      def newEvent(context)
        BaseEvent.new(owner: @owner, context: context, eventTarget: KSO_SDK::Application.ActiveSheet, eventName: @eventName, jsfunc: @jsFuncName)
      end
    end

    #单元格内容改变事件
    class CellChangeEvent < EventManager

      def initialize(owner: owner)
        super()
        @owner = owner
        @eventName = 'Change'
        @jsFuncName = 'onCellChange'
      end

      def newEvent(context)
        event = BaseEvent.new(owner: @owner, context: context, eventTarget: KSO_SDK::Application.ActiveSheet, eventName: @eventName, jsfunc: @jsFuncName)
        event
      end
    end

    # Sheet切换事件
    class SheetActivateEvent < EventManager

      def initialize(owner: owner)
        super()
        @owner = owner
        @eventName = 'SheetActivate'
        @jsFuncName = 'onSheetActivate'
      end

      def newEvent(context)
        BaseEvent.new(owner: @owner, context: context, eventTarget: KSO_SDK::Application.ActiveWorkbook, eventName: @eventName, jsfunc: @jsFuncName)
      end
  
    end
  
    # Workbook切换事件
    class WorkbookActivateEvent < BaseEvent

      def initialize(owner:)
        super(owner: owner,
            eventTarget: KSO_SDK::Application,
            eventName: 'WorkbookActivate',
            jsfunc: 'onWorkbookActivate')
      end

    end

    #Workbook关闭事件
    class WorkbookCloseEvent < BaseEvent

      def initialize(owner:)
        super(owner: owner,
          eventTarget: KSO_SDK::Application,
          eventName: 'WorkbookBeforeClose',
          jsfunc: 'onWorkbookClose')
      end

    end

    class Et < KSO_SDK::JsBridge

      def openLocalFile(local_file)
        if !local_file.nil?
          if File.exist?(local_file)
            KSO_SDK::Application.Workbooks.Open(local_file)
            return true
          else
            return false
          end
        else
          josn_result = {:result=>false,:error_message=>"local_file is null!"}
          return josn_result.to_json
        end
      end

      def getActiveWorkbookName
        if !KSO_SDK::Application.ActiveWorkbook.nil?
          josn_result = {:active_workbook_name => KSO_SDK::Application.ActiveWorkbook.name}
          return josn_result.to_json
        end
      end

      def connectSelectionChange(context)
        @selection_change_event = SelectionChangeEvent.new(owner: self) if @selection_change_event.nil?
        @selection_change_event.connect context do | range |
          {:address => range.Address}
        end
        nil
        # nil
      end

      def disConnectSelectionChange(context)
        @selection_change_event.disConnect(context) unless @selection_change_event.nil?
        nil
      end

      def connectSheetActivate(context)
        @sheet_activate_event = SheetActivateEvent.new(owner: self) if @sheet_activate_event.nil?
        @sheet_activate_event.connect context do | sh |
          {:name => sh.Name}
        end
        nil
      end

      def disConnectSheetActivate(context)
        @sheet_activate_event.disConnect(context) unless @sheet_activate_event.nil?
        nil
      end

      def connectWorkbookActivate()
        @workbook_activate_event = WorkbookActivateEvent.new(owner: self) if @workbook_activate_event.nil?
        @workbook_activate_event.connect { | wb |
          klog wb.Name
          {:name => wb.Name}
        }
        nil
      end

      def connectCellChange(context)
        if @cell_change_event.nil?
          @cell_change_event = CellChangeEvent.new(owner: self)
        end
        @cell_change_event.connect context do | range |
          {:address => range.Address, :value => range.Value}
        end
        nil
      end

      def disConnectCellChange(context)
        @cell_change_event.disConnect(context) unless @cell_change_event.nil?
      end

      def disConnectWorkbookActivate(context)
        @workbook_activate_event.disConnect if !@workbook_activate_event.nil?
        nil
      end
      
      def setCustomDocumentProperty(name, value, type = 4)
        if !KSO_SDK::Application.ActiveWorkbook.nil?
          props = KSO_SDK::Application.ActiveWorkbook.CustomDocumentProperties
          for i in 1..props.Count
            if props.Item(i).Name.eql?(name)
              item = props.Item(i)
              item.Value = value
              break
            end
          end
          props.Add(name, false, type, value) if item.nil?
          true
        else
          false
        end
      end

      def getCustomDocumentProperty(name)
        if !KSO_SDK::Application.ActiveWorkbook.nil?
          index = 1
          props = KSO_SDK::Application.ActiveWorkbook.CustomDocumentProperties
          while index <= props.Count
            klog "#{props.Item(index).Name} : #{props.Item(index).Value}"
            if props.Item(index).Name.eql?(name)
              return props.Item(index).Value
            end
            index += 1
          end
        end
        nil
      end

      # def connectWorkbookClose()
        # 事件绑定在Application会造成卡死
        # @workbookClose = BaseEvent.new(owner: self, eventTarget: KSO_SDK::Application.ActiveWorkbook, eventName: 'BeforeClose', jsfunc: 'onWorkbookClose') if @workbookClose.nil?
        # @workbookClose.connect { |cancel|
          # klog cancel
        # }
      # end

      def connectWorkbookClose()
        @wbCloseEvent = WorkbookCloseEvent.new(owner: self) if @wbCloseEvent.nil?
        @wbCloseEvent.connect do | cancel, wb | # 参数乱序
          {:workbookName => wb.name, :cancel => cancel}
        end
        nil
      end

      def disConnectWorkbookClose()
        @wbCloseEvent.disConnect() unless @wbCloseEvent.nil?
      end

    end
  end

end