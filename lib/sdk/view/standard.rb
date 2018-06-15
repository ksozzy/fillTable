#
# form.rb
# Creator： laiw
# Created: time： 2018/1/1
# Description: 实现ruby 标准可视控件的 sdk 封装
#
#

require 'Qt'

module KSO_SDK::View

    # :nodoc:all
    module ComponentDefinition

        def self.defineAll(class_name)
            COMPONENT_DEFINITION.each do |object_name, component_name|
                define class_name, component_name, object_name
            end
        end

        def self.defineFrame(class_name)
            class_name.class_eval ("
                def self.defineSdkFrame(frame_name, object_name)
                    KSO_SDK::View::ComponentDefinition::defineSdkComponent self, frame_name, object_name
                end
                
                def self.defineCustomFrame(frame_name, object_name)
                    KSO_SDK::View::ComponentDefinition::defineComponent self, frame_name, object_name
                end"
            )
        end

        def self.define(class_name, component_name, object_name)
            class_name.class_eval ("
                def self.define_#{object_name}(*arg)
                arg.each do |name|
                    KSO_SDK::View::ComponentDefinition::defineComponent(#{class_name}, :#{component_name}, name)
                end
            end"
            )
        end

        def self.defineComponent(class_name, component_name, object_name)
            class_name.class_eval("
                def #{object_name};
                if @#{object_name}.nil?
                    @#{object_name} = #{component_name}.new(self)
                    @#{object_name}.setObjectName('#{object_name}')
                  end
                  @#{object_name};
                end"
                ) 
        end

        def self.defineSdkComponent(class_name, component_name, object_name)
            class_name.class_eval("
                def #{object_name};
                if @#{object_name}.nil?
                    @#{object_name} = SDK::#{component_name}.new(self)
                  end
                  @#{object_name};
                end"
                ) 
        end
    end

    # :nodoc:all
    module Event
        def self.define(name)
            defineByParameter(name)
        end

        def self.defineString(name)
            defineByParameter(name, 'const QString &')
        end

        def self.defineInt(name)
            defineByParameter(name, 'int')
        end

        def self.defineDate(name)
            defineByParameter(name, 'QDate')
        end

        def self.defineTreeItemClicked(name)
            defineByParameter(name, 'QTreeWidgetItem *, int')
        end

        def self.defineByParameter(name, parameter_statement = "")
            event_name = name.to_s.gsub(/\b\w/) { $&.upcase }
            self.class_eval(
                "def on#{event_name}=(slot);
                   if !parent.nil?
                        parent.class.class_eval(\" slots   '\#{slot}(#{parameter_statement})'\")
                        connect(self, SIGNAL('#{name}(#{parameter_statement})'), parent, SLOT(\"\#{slot}(#{parameter_statement})\"))
                    end;
                end"
                ) 
        end

        def self.defineEvent(class_name, event_name, parameter_statement = "")
            class_name.class_eval ("
                signals '#{event_name}(#{parameter_statement})'
                "
            )
            upcase_name = event_name.to_s.gsub(/\b\w/) { $&.upcase }
            if parameter_statement == ""
                class_name.class_eval ("
                    def do#{upcase_name}
                        emit #{event_name}
                    end"
                )
            else
                array = parameter_statement.split(/\,/)
                params = ""
                (1..array.size).each do |i|
                    if !params.empty?
                        params << ", "
                    end
                    params << "p" << i.to_s
                end                                
                class_name.class_eval ("
                    def do#{upcase_name}(#{params})
                        emit #{event_name} #{params}
                    end"
                )
            end
          
            self.defineByParameter event_name, parameter_statement
        end
    end

    # :nodoc:all
    class Button < Qt::PushButton
        
        include Event

        Event::define :clicked

    end

    # :nodoc:all
    class ToolButton < Qt::ToolButton
        
        include Event

        Event::define :clicked

    end

    # :nodoc:all
    class Label < Qt::Label

        include Event

    end

    # :nodoc:all
    class Edit < Qt::LineEdit

        include Event
        
        Event::defineString :textChanged
        Event::define :returnPressed

    end

    # :nodoc:all
    class Date < Qt::DateEdit
     
        include Event
        
        Event::defineDate :dateChanged

        def initialize(parent = nil)
            super(parent)
            
            setCalendarPopup(true)
        end
    end

    # :nodoc:all
    class RichEdit < Qt::TextEdit

        include Event
        
        Event::define :textChanged

    end

    # :nodoc:all
    class RadioButton < Qt::RadioButton

        include Event
        
        Event::define :clicked
    end

    # :nodoc:all
    class ComboBox < Qt::ComboBox

        include Event
        
        Event::defineString :currentIndexChanged
    end

    # :nodoc:all
    class CheckBox < Qt::CheckBox

        include Event
       
        Event::defineInt :stateChanged
    end

    # :nodoc:all
    class TreeView < Qt::TreeWidget

        include Event

        Event::defineTreeItemClicked :itemClicked
    end

    # :nodoc:all
    class Image < Qt::Image

        include Event

    end

    # :nodoc:all
    class Action < Qt::Action

        include Event
        
        Event::define :triggered
    end

    # :nodoc:all
    class MenuBar < Qt::MenuBar

        include Event
        
    end

    # :nodoc:all
    class Menu < Qt::Menu

        include Event
        
    end

    # :nodoc:all
    class GridLayout < Qt::GridLayout

        include Event
        
        def add(object, x, y)
            addWidget(object, x, y)
        end
    end

    COMPONENT_DEFINITION = {
        :label => :Label,                # define_label :label1
        :edit => :Edit,                  # define_edit :edit1
        :rich_edit => :RichEdit,
        :date => :Date,
        :button => :Button,
        :tool_button => :ToolButton,
        :combobox => :ComboBox, 
        :checkbox => :CheckBox, 
        :tree_view => :TreeView,
        :grid_layout => :GridLayout, 
        :radio_button => :RadioButton, 
        :menu_bar => :MenuBar, 
        :menu => :Menu, 
        :action => :Action
        }
        
    WidgetAttribute = [
        :Disabled,                        #WA_Disabled
        :UnderMouse,                      #WA_UnderMouse
        :MouseTracking,                   #WA_MouseTracking
        :ContentsPropagated,              #WA_ContentsPropagated
        :OpaquePaintEvent,                #WA_OpaquePaintEvent
        :NoBackground,                    #WA_NoBackground
        :StaticContents,                  #WA_StaticContents
        :LaidOut,                         #WA_LaidOut
        :PaintOnScreen,                   #WA_PaintOnScreen
        :NoSystemBackground,              #WA_NoSystemBackground
        :UpdatesDisabled,                 #WA_UpdatesDisabled
        :Mapped,                          #WA_Mapped
        :MacNoClickThrough,               #WA_MacNoClickThrough
        :PaintOutsidePaintEvent,          #WA_PaintOutsidePaintEvent
        :InputMethodEnabled,              #WA_InputMethodEnabled
        :WState_Visible,                  #WA_WState_Visible
        :WState_Hidden,                   #WA_WState_Hidden
        :ForceDisabled,                   #WA_ForceDisabled
        :KeyCompression,                  #WA_KeyCompression
        :PendingMoveEvent,                #WA_PendingMoveEvent
        :PendingResizeEvent,              #WA_PendingResizeEvent
        :SetPalette,                      #WA_SetPalette
        :SetFont,                         #WA_SetFont
        :SetCursor,                       #WA_SetCursor
        :NoChildEventsFromChildren,       #WA_NoChildEventsFromChildren
        :WindowModified,                  #WA_WindowModified
        :Resized,                         #WA_Resized
        :Moved,                           #WA_Moved
        :PendingUpdate,                   #WA_PendingUpdate
        :InvalidSize,                     #WA_InvalidSize
        :MacBrushedMetal,                 #WA_MacBrushedMetal
        :MacMetalStyle,                   #WA_MacMetalStyle
        :CustomWhatsThis,                 #WA_CustomWhatsThis
        :LayoutOnEntireRect,              #WA_LayoutOnEntireRect
        :OutsideWSRange,                  #WA_OutsideWSRange
        :GrabbedShortcut,                 #WA_GrabbedShortcut
        :TransparentForMouseEvents,       #WA_TransparentForMouseEvents
        :PaintUnclipped,                  #WA_PaintUnclipped
        :SetWindowIcon,                   #WA_SetWindowIcon
        :NoMouseReplay,                   #WA_NoMouseReplay
        :DeleteOnClose,                   #WA_DeleteOnClose
        :RightToLeft,                     #WA_RightToLeft
        :SetLayoutDirection,              #WA_SetLayoutDirection
        :NoChildEventsForParent,          #WA_NoChildEventsForParent
        :ForceUpdatesDisabled,            #WA_ForceUpdatesDisabled
        :WState_Created,                  #WA_WState_Created
        :WState_CompressKeys,             #WA_WState_CompressKeys
        :WState_InPaintEvent,             #WA_WState_InPaintEvent
        :WState_Reparented,               #WA_WState_Reparented
        :WState_ConfigPending,            #WA_WState_ConfigPending
        :WState_Polished,                 #WA_WState_Polished
        :WState_DND,                      #WA_WState_DND
        :WState_OwnSizePolicy,            #WA_WState_OwnSizePolicy
        :WState_ExplicitShowHide,         #WA_WState_ExplicitShowHide
        :ShowModal,                       #WA_ShowModal
        :MouseNoMask,                     #WA_MouseNoMask
        :GroupLeader,                     #WA_GroupLeader
        :NoMousePropagation,              #WA_NoMousePropagation
        :Hover,                           #WA_Hover
        :InputMethodTransparent,          #WA_InputMethodTransparent
        :QuitOnClose,                     #WA_QuitOnClose
        :KeyboardFocusChange,             #WA_KeyboardFocusChange
        :AcceptDrops,                     #WA_AcceptDrops
        :DropSiteRegistered,              #WA_DropSiteRegistered
        :ForceAcceptDrops,                #WA_ForceAcceptDrops
        :WindowPropagation,               #WA_WindowPropagation
        :NoX11EventCompression,           #WA_NoX11EventCompression
        :TintedBackground,                #WA_TintedBackground
        :X11OpenGLOverlay,                #WA_X11OpenGLOverlay
        :AlwaysShowToolTips,              #WA_AlwaysShowToolTips
        :MacOpaqueSizeGrip,               #WA_MacOpaqueSizeGrip
        :SetStyle,                        #WA_SetStyle
        :SetLocale,                       #WA_SetLocale
        :MacShowFocusRect,                #WA_MacShowFocusRect
        :MacNormalSize,                   #WA_MacNormalSize
        :MacSmallSize,                    #WA_MacSmallSize
        :MacMiniSize,                     #WA_MacMiniSize
        :LayoutUsesWidgetRect,            #WA_LayoutUsesWidgetRect
        :StyledBackground,                #WA_StyledBackground
        :MSWindowsUseDirect3D,            #WA_MSWindowsUseDirect3D
        :CanHostQMdiSubWindowTitleBar,    #WA_CanHostQMdiSubWindowTitleBar
        :MacAlwaysShowToolWindow,         #WA_MacAlwaysShowToolWindow
        # :StyleSheet,                      #WA_StyleSheet Qt::Widget 已有 setStyleSheet
        :ShowWithoutActivating,           #WA_ShowWithoutActivating
        :X11BypassTransientForHint,       #WA_X11BypassTransientForHint
        :NativeWindow,                    #WA_NativeWindow
        :DontCreateNativeAncestors,       #WA_DontCreateNativeAncestors
        :MacVariableSize,                 #WA_MacVariableSize
        :DontShowOnScreen,                #WA_DontShowOnScreen
        :X11NetWmWindowTypeDesktop,       #WA_X11NetWmWindowTypeDesktop
        :X11NetWmWindowTypeDock,          #WA_X11NetWmWindowTypeDock
        :X11NetWmWindowTypeToolBar,       #WA_X11NetWmWindowTypeToolBar
        :X11NetWmWindowTypeMenu,          #WA_X11NetWmWindowTypeMenu
        :X11NetWmWindowTypeUtility,       #WA_X11NetWmWindowTypeUtility
        :X11NetWmWindowTypeSplash,        #WA_X11NetWmWindowTypeSplash
        :X11NetWmWindowTypeDialog,        #WA_X11NetWmWindowTypeDialog
        :X11NetWmWindowTypeDropDownMenu,  #WA_X11NetWmWindowTypeDropDownMenu
        :X11NetWmWindowTypePopupMenu,     #WA_X11NetWmWindowTypePopupMenu
        :X11NetWmWindowTypeToolTip,       #WA_X11NetWmWindowTypeToolTip
        :X11NetWmWindowTypeNotification,  #WA_X11NetWmWindowTypeNotification
        :X11NetWmWindowTypeCombo,         #WA_X11NetWmWindowTypeCombo
        :X11NetWmWindowTypeDND,           #WA_X11NetWmWindowTypeDND
        :MacFrameworkScaled,              #WA_MacFrameworkScaled
        :SetWindowModality,               #WA_SetWindowModality
        :WState_WindowOpacitySet,         #WA_WState_WindowOpacitySet
        :TranslucentBackground,           #WA_TranslucentBackground
        :AcceptTouchEvents,               #WA_AcceptTouchEvents
        :WState_AcceptedTouchBeginEvent,  #WA_WState_AcceptedTouchBeginEvent
        :TouchPadAcceptSingleTouchEvents, #WA_TouchPadAcceptSingleTouchEvents
        :MergeSoftkeys,                   #WA_MergeSoftkeys
        :MergeSoftkeysRecursively,        #WA_MergeSoftkeysRecursively
        :Maemo5NonComposited,             #WA_Maemo5NonComposited
        :Maemo5StackedWindow,             #WA_Maemo5StackedWindow
        :LockPortraitOrientation,         #WA_LockPortraitOrientation
        :LockLandscapeOrientation,        #WA_LockLandscapeOrientation
        :AutoOrientation,                 #WA_AutoOrientation
        :Maemo5PortraitOrientation,       #WA_Maemo5PortraitOrientation
        :Maemo5LandscapeOrientation,      #WA_Maemo5LandscapeOrientation
        :Maemo5AutoOrientation,           #WA_Maemo5AutoOrientation
        :Maemo5ShowProgressIndicator,     #WA_Maemo5ShowProgressIndicator
        :X11DoNotAcceptFocus,             #WA_X11DoNotAcceptFocus
        :SymbianNoSystemRotation,         #WA_SymbianNoSystemRotation
        :MSCustomFrameStruct              #WA_MSCustomFrameStruct
        ]

    # :nodoc:all
    class Cracker < Qt::Widget
        def self.attributeToMethod
            WidgetAttribute.each do |attribute|
                self.superclass.class_eval ("
                def set#{attribute}(value)
                    setAttribute(Qt::WA_#{attribute}, value);
                end"
                )
            end
        end
    end

    # :nodoc:all
    Cracker.attributeToMethod
end
