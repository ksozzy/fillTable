=begin
  #--Created by caidong<caidong@wps.cn> on 2018/2/26.
  #--Description:根据文件引用库
=end

def dir_require(dir) # :nodoc:
  Dir[File.dirname(__FILE__) + "#{dir}/*.rb"].each { | file | klog file;require file }
end