=begin
  #--Created by caidong<caidong@wps.cn> on 2018/4/16.
  #++Description:原生控件开发示例
=end
require 'sdk'
require 'Qt'

module Demo
  
  class DemoFrame < KSO_SDK::View::Frame

    define_button :btn
    define_label :label
    define_rich_edit :rich
    define_date :date
    define_tool_button :toolBtn
    define_combobox :cob
    define_checkbox :ckb
    define_radio_button :rb
    define_menu_bar :mb
    define_menu :menu
    define_action :action
    
    def initialize()
      super(nil)
      btn.setText('Button')
      label.setText('Label')
      rich.insertHtml('<h1>Rich<font color="red">Text</font></h1>')
      rich.setMaximumHeight(100)
      toolBtn.setMenu(menu)
      menu.addAction(action)
      action.setText('Action1')
  
      3.times do |i|
        cob.addItem("ComboBox_Item#{i}")
      end
  
      ckb.setText('CheckBox')
      rb.setText('RadioButton')
      
      3.times do |i|
        mb.addAction("MenuAction#{i}")
      end
  
      self.layout = Qt::VBoxLayout.new do |l|
        l.addWidget(btn)
        l.addWidget(label)
        l.addWidget(rich)
        l.addWidget(date)
        l.addWidget(toolBtn)
        l.addWidget(cob)
        l.addWidget(ckb)
        l.addWidget(rb)
        l.addWidget(mb)
      end
    end
  
  end
  
end