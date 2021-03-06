# 如何通过Safari检测第三方app的某个页面是WKWebview还是UIWebview

## 使用方法:
1. 使用这里的[传送门][aUtoReSiGn]脚本对app进行重签名.
  - PS:要选择Development的配置来进行重签名
2. 重签名后将app安装到手机并使用闪电转USB连接线连接Mac电脑
3. 打开app到你想要验证的页面
4. 打开Mac电脑上的Safari浏览器
4. 打开Safari菜单栏上的`开发`选项.如果没找到开发选项，请依次点击`Safari浏览器`->`偏好设置`->`高级`->`在菜单栏中显示“开发”菜单`将勾勾选中.
  - PS:实在不明白请百度：Safari打开开发者选项
5. 然后按如下图操作:
  - 点击`Develop`.(PS:中文里面是叫做`开发`)
  - 选择`devmatocloud的iPhone`, 这时会有个`WSPXDemo`下面会显示app内webview加载的网址.(PS:如果没有网址出现在里面，那么该页面并不是webview做的)
    - `devmatocloud的iPhone`对应你的手机;`WSPXDemo`对应你app的名字
  - 选择其中一个网址，会弹出对应的`Web Inspector`.(PS:中文应该叫web检查器)
  - 然后在`Console`中输入`window.statusbar.visible`并按回车键,如果输出`true`那么就是`wkwebview`，相反则为`uiwebview`.

![传说中的下图][iswkoui]

# Trick
 - 一般使用`WKWebview`都会在native这边通过`- (void)addScriptMessageHandler:(id <WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name;`添加一个script消息的handler，那么就可以通过在`Web Inspector`中输入`window.webkit.messageHandlers`查看是否有输出对应的输出来判断是哪个`webview`
  - `UIWebview`中的输出为:`TypeError: undefined is not an object (evaluating 'window.webkit.messageHandlers')`
  - `WKWebview`中的输出为:`UserMessageHandlersNamespace {}`

# TODO:
 - 弄个网址直接弹窗显示检测结果

### 在使用过程中如果有任何问题或者改良的方案欢迎提issue和pr.

[iswkoui]:https://github.com/MrChens/iOS_Tools/blob/master/isWKoUI/iswkoui.png
[aUtoReSiGn]:https://github.com/MrChens/iOS_Tools/tree/master/autoResign
