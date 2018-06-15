# WPS Office Ruby SDK开发文档

## JS接口

### 1 引用sdk

```ruby
require 'sdk'
```

### 2 继承KSO_SDK::JsBridge,定义并实现公开方法

```ruby
require 'sdk'
require 'json'

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

  private

  def getLine()
    __LINE__.to_s
  end

end
```

### 3 创建WebView，并注册接口

编写入口文件main.rb

```ruby
require 'sdk'
require_relative 'apis'

@webview = KSO_SDK::View::WebViewPane.new(title: 'Sample',
  url: __dir__ + '\web\index.html',
  jsApi: [Sample.new()])
```

### 4 在JavaScript中测试

```javascript
document.querySelector('#openWord').addEventListener('click', function (e) {

    window.ksoJsAsynCall('openWord', {
      filepath: getFilepath()
    }, function (res) {
      console.log(res);
      document.querySelector('#methodCallback').innerHTML = '"openWord" result:' + res.result + ' of  ksoJsAsynCall is done!'
    });

  });

document.querySelector('#test').addEventListener('click', function (e) {

    window.ksoJsAsynCall('getFileName', {
        line: true
    }, function (res) {
        console.log(res);
        document.querySelector('#methodCallback').innerHTML = '"test" result:' + res.result
    })
  });

  document.querySelector('#callbackToJs').addEventListener('click', function (e) {

     window.ksoJsAsynCall('callback', {
       methodName: 'callJs'
     }, function (res) {
     });
  });
```
详情请参考example示例