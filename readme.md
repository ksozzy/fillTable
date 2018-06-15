## 技术方案

- React.js：Web界面框架
- TypeScript：开发语言

## 全局依赖（只需配置一次）

- VS Code：https://code.visualstudio.com/
- Node.js，https://npm.taobao.org/mirrors/node/latest-v9.x/node-v9.11.1-x64.msi
- TypeScript，执行如下命令安装
  ```
  npm i typescript -g
  ```
- webpack，执行如下命令安装
  ```
  npm i webpack -g
  ```

## 目录结构

- dist：完整的构建版本输出目录
- lib：wps sdk目录
- node_modules：JavaScript依赖目录
- src：前端源代码目录
- web：开发过程中web编译之后的文件输出目录
- apis.rb：API定义脚本
- main.rb：插件入口文件
- package.json：工程描述文件
- tsconfig.json：TypeScriptp编译配置文件

## 开发说明

- 首次开发之前需要先安装工程依赖，在工程根目录执行如下命令
  ```
  npm i
  ```
- 该工程对默认的SDK和demo代码结构做了一些修改，以适应基于TypeScript的模块化开发方式
- 使用VS Code打开该目录进行开发
- js调用wps api的写法，可以参考 src/demo.tsx、src/libs/sheet.ts
- src下面的源代码使用TypeScript开发，需要经过编译之后才能被浏览器执行
- 开发过程中可以在工程根目录执行如下命令进行编译
  ```
  npm start
  ```
  - 该命令会监控src下面代码文件的变化，自动编译，编译之后的文件输出到web目录下（__请勿直接修该目录下的文件__）
  - 该命令执行之后控制台会处于监控状态，不需要重复执行，如果遇到控制台阻塞，没有及时响应变化，可尝试按回车键或Ctrl+C，或者退出重新执行命令
  - 可以使用wps加载根目录下的 main.rb 文件来测试，指向的是Web目录下的index.html文件
- 如果要构建一个完整的release版本，可以在根目录执行如下命令
  ```
  npm run build
  ```
  该命令会去除Web的调试信息，压缩输出的代码，并将编译之后的文件以及所需的sdk文件拷贝到dist目录，该目录是一个完整可执行的插件，可以使用wps加载 dist/main.rb 文件来测试