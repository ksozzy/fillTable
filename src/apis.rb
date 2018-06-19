=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/12.
  #++Description:
=end
require 'sdk'
require 'json'
require 'Qt'
require_relative 'fileutils'

module AIOffice

  class Sample < KSO_SDK::JsBridge

    public
  
    def getFileName(line = false)
      if line
        result = __FILE__ + getLine().to_s
      else
        result = __FILE__
      end
      result
    end
  
    def openWord(filepath)
      if File.exist?(filepath)
        KSO_SDK.getApplication().Documents.Open(filepath)
        return true
      end
      return false
    end
	
  
    def openExcel(filepath)
      if File.exist?(filepath)
        KSO_SDK.getApplication().Workbooks.Open(filepath)
        return true
      end
      return false
    end
  
    def openPowerPoint(filepath)
      if File.exist?(filepath)
        KSO_SDK.getApplication().Presentations.Open(filepath)
        return true
      end
      return false
    end
  
    def callback(methodName)
      klog methodName
      json = {:params => "content"}.to_json()
      klog json
      callbackToJS(methodName, json)
    end
  
    def test(url)
      command = KSO_SDK::getCurrentMainWindow().commands().command("CT_Home");
      puts command.class
      cmd = KRbTabCommand.new(KSO_SDK::getCurrentMainWindow(), KSO_SDK::getCurrentMainWindow())
      cmd.setDrawText(url)
      KSO_SDK::getCurrentMainWindow().commands().addCommand("CT_MyuHome", cmd)
      "call test"
    end
  
    #选中单元格
    def selectCell(range)
      KSO_SDK::Application.ActiveSheet.Range(range).Select
    end
  
    #获取已使用多少列
    def getSheetColumns()
      klog count = KSO_SDK::Application.ActiveSheet.UsedRange.Columns.Count
      count
    end
  
    #获取单元格的内容
    def getSheetValue(range)
      klog val = KSO_SDK::Application.ActiveSheet.Range(range).Value
      val = val.to_json if val.kind_of?(Array)
      val
    end
  
    #插入空白行
    #row：第一行插入
    def insertRow(row)
      klog KSO_SDK::Application.ActiveSheet.Rows(row).Insert
    end
  
    #获取当前选中的单元格位置
    def getSelection()
      KSO_SDK::Application.Selection.Address
    end
  
    #保存Excel文档
    def saveExcel()
      KSO_SDK::Application.ActiveWorkbook.Save
    end
  
    #编辑单元格的内容
    def setSheetValue(range,value)
      KSO_SDK::Application.ActiveSheet.Range(range).Value = value
    end
  
    #打开选择文件弹框
    def openFileDialog(title="打开文件",path= "C:", desc = "files", suffix="*.*")
      Qt::FileDialog::getOpenFileName(KSO_SDK::getCurrentMainWindow(), title,
        path,
        "#{desc} (#{suffix})")
    end
  
    #添加Sheet
    def addSheet()
      sheet = KSO_SDK::Application.WorkSheets.Add
      sheet.Name
    end
  
    #隐藏Sheet
    def hideSheet(name)
      KSO_SDK::Application.WorkSheets(name).Visible = false
    end
  
    #为单元格设置自动填充的内容
    def autoFill(src, sheet, dst)
      # to-do
    end
  
    #以模板的形式打开Excel
    def openExcelTemp(filepath)
      KSO_SDK::Application.Workbooks.Add(filepath)
    end
  
    #以模板的形式打开Word
    def openWordTemp(filepath)
      KSO_SDK::Application.Documents.Add(filepath)
    end
  
    #弹出Excel选择单元格选择窗
    def showInputBox(prompt, title)
      KSO_SDK::Application.InputBox(:prompt => prompt, :title => title, :type => 8).Address
    end
  
    #Excel文档另存为
    def excelSaveAs()
      filename = KSO_SDK::Application.GetSaveAsFilename()
      KSO_SDK::Application.ActiveWorkbook.SaveAs(filename)
    end
  
    #Excel关闭当前文档
    def closeActiveWorkbook()
      KSO_SDK::Application.ActiveWorkbook.Close()
    end
    
    #获取已使用的区域
    def getUsedRangeAddress()
      KSO_SDK::Application.ActiveSheet.UsedRange.Address
    end
  
    # 显示MessageBox
    def showMessageBox(title, text)
      btnMask = Qt::MessageBox::question(KSO_SDK.getCurrentMainWindow(), 'Title', 'ContentMessage', Qt::MessageBox::Yes, Qt::MessageBox::No)
    end
  
    #为单元格设置下来选值
    def setRangeInCellDropdownValidation(address, array)
      #{"type":3,"value":true,"alertStyle":1,"operator":1,"inCellDropdown":true,"formula1":"123,321,abc","formula2":""} 
      KSO_SDK::Application.ActiveSheet.Range(address).Validation().Add(3, 1, 1, array)
    end
  
    #为单元格添加批注
    def setComment(address, comment)
      KSO_SDK::Application.ActiveSheet.Range(address).AddComment(comment)
      nil
    end
	
	#获取文件全路径
	def getFullName()
	  klog val = KSO_SDK::Application.ActiveWorkbook.FullName
	  val
	end
	
	#获取文件名
	def getWorkbookName()
	  klog val = KSO_SDK::Application.ActiveWorkbook.Name
	  val
	end
	
	#获取工资表名
	def getWorksheetName()
	  klog val = KSO_SDK::Application.ActiveSheet.Name
	  val
	end
	  
	#为单元格设置下来选值
	def setRangeValidation(address, array)
	  #{"type":3,"value":true,"alertStyle":1,"operator":1,"inCellDropdown":true,"formula1":"123,321,abc","formula2":""} 
	  KSO_SDK::Application.ActiveSheet.Range(address).Validation().Delete()
	  KSO_SDK::Application.ActiveSheet.Range(address).Validation().Add(3, 2, 1, array)
    end
	
    def activeSheet(name)
      KSO_SDK::Application.WorkSheets(name).Activate = false
    end
	
    # 显示alert
    def showAlert(text)
      btnMask = Qt::MessageBox::about(KSO_SDK.getCurrentMainWindow(), '提示', text)
    end
  
  
  
    #获取插件存储文件路径
    def getStorageDir()
      KSO_SDK.getStorageDir(context)
    end
	
	#
    def fileRename(source, target)
      File.rename(source, target)
    end
	
    def fileDelete(file)
      File.delete(file)
    end
	
    def fileCopy(source, target)
	  FileUtils.cp(source, target)
    end
	
	def appid()
		context.appId
	end
	
  
    private
  
    def getLine()
      __LINE__.to_s
    end
  
  end
  
end