#
# form.rb
# Creator： laiw
# Created: time： 2018/1/1
# Description: 实现 ruby 的 win、webview 的 sdk 封装
#
# ===  1.      封装 Dialog 对话框
#              封装 FormWindow window 的 窗体
#              封装 WebFormWindow webview 的 窗体
#
# ===  2.      封装 标准控件 的声明
#              在窗体上，控件声明象下面的形式
#              class MyForm < SDK::FormWindow
#                   define_label :label1, :label2
#
#                   def initialize(parent = nil)
#                       super(parent)
#
#                       label1.setGeometry 8, 38, 161, 16
#                       label1.setText 'url'
#                   end
#              end 
#
#              已支持以下控件: 
#              define_label => Qt::Label
#              define_edit => Qt::LineEdit
#              define_rich_edit => Qt::TextEdit
#              define_date => Qt::DateEdit
#              define_button => Qt::PushButton
#              define_combobox => Qt::ComboBox
#              define_checkbox => Qt::CheckBox
#              define_tree_view => Qt::TreeWidget
#              define_grid_layout => :GridLayout, 
#              define_radio_button => Qt::RadioButton
#              define_menu_bar => Qt::MenuBar
#              define_menu => Qt::Menu
#              define_action => Qt::Action

# ===  3.       实现 控件 的标准事件封装
#               class MyForm < SDK::FormWindow
#                   define_label :label1, :label2
#                   define_button :button1
#
#                   def initialize(parent = nil)
#                       super(parent)
#
#                       button1.onClicked = :onClicked
#                   end
#
#                   def onClicked
#                       # todo somthing
#                   end
#               end
#
# ===  4.       封装通用的 SDK::Frame,支持组合控件
#               使用 define_sdk_frame 来声明一个SDK的 Frame
#               
#               define_sdk_frame :SampleFrame, :frame

#               class SampleFrame < Frame
#
#                   define_label :label
#                   define_edit :edit
#                   define_button :button
#                   ...
#               end
#
#                class WebDialog < SDK::Dialog
#
#                   define_sdk_frame :SampleFrame, :frame
#
#                   def initialize(parent = nil)
#                        super(parent)
#
#                        frame.setVisible(true)
#                        frame.setGeometry 0, 0, 300, 100
#                    end
#                end
#
#
# ===  5.       使用自定义的 Frame,支持组合控件
#               使用 define_frame 来声明一个自定义的 Frame
#
#               define_custom_frame :MyCustomFrame, :frame
#
#               class MyCustomFrame < SDK::Frame
#                   define_label :label1
#                   define_label :label2
#
#                   define_date :date1
#                   define_date :date2
#
#                    def initialize(parent = nil)
#                        super(parent)
# 
#                        label1.setText 'start time'
#                        label2.setText 'end   time'
#
#                        date1.onDateChanged = :dateDateChanged
#                        date2.onDateChanged = :dateDateChanged
#                    end
#
#                   include SDK::Event
#
#                   => 声明 MyCustomFrame 有个onDateChanged(QDate) 事件
#                   => slots   'dateChanged(QDate)'
#                   SDK::Event::define_event self, :dateChanged, 'QDate' 

#                    def dateDateChanged(date)
#                        doDateChanged(date) # => emit dateChanged date
#                    end
#                end
#
#                class CustomDialog < SDK::Dialog
#
#                   define_custom_frame :MyCustomFrame, :frame
#
#                   def initialize(parent = nil)
#                       super(parent)
#                       frame.setVisible(true)
#                       frame.setGeometry 0, 0, 300, 100

#                       frame.onDateChanged = :frameDateChanged
#                   end

#                   def frameDateChanged(date)
#                       self.setWindowTitle (date.toString("yyyy-MM-d"))
#                   end
#                end
#
# ===  6.      对自定义的 Frame\Form 定义事件
#              使用 define_frame 来声明一个自定义的 Frame
#
#              SDK::Event::define_event self, name, params_string
#              例：
#              SDK::Event::define_event self, :dateChanged, 'QDate'
#              <==>
#                 slots   'dateChanged(QDate)'
#                 connect(frame, SIGNAL("dateChanged(QDate)"), self, SLOT("frameDateChanged(QDate)"))
#
# ===  7.      样式
#              默认样式：
#                    Style::default
#              指定样式：
#                    Style::set name
#
# ===  8.     Widget 属性转方法
#             继承 Qt::Widget 对象的 属性设置转方法
#             object.setDeleteOnClose(true) <==>
#               object.setAttribute(Qt::WA_DeleteOnClose, true);
#


require 'Qt'
require_relative 'standard'

module KSO_SDK::View

    # :nodoc:all
    class Dialog < Qt::Dialog

        def initialize(parent = nil)
            super(parent)

            KSO_SDK::Style.addObject(self)
        end

        ComponentDefinition::defineAll self
        ComponentDefinition::defineFrame self
    end

    # :nodoc:all
    class FormWindow < Qt::Widget

        def initialize(parent = nil)
            super(parent)

            KSO_SDK::Style.addObject(self)
        end

        ComponentDefinition::defineAll self
        ComponentDefinition::defineFrame self
    end

    # :nodoc:all
    class Frame < Qt::Frame

        def initialize(parent = nil)
            super(parent)
        end

        # def mouseReleaseEvent(event)
        #     setFocus()
        # end

        ComponentDefinition::defineAll self
        ComponentDefinition::defineFrame self
    end

    # :nodoc:all
    class DocForm < Qt::DockWidget

        def initialize(parent = nil)
            super(parent)
        end

        ComponentDefinition::defineAll self
        ComponentDefinition::defineFrame self
    end

    # class WebFormWindow < Qt::WebView
    # end

    # :nodoc:all
    class Application < Qt::Application
        def initialize(parent = nil)
            super(parent)
            
        end
    end

end