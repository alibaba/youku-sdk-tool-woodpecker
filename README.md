<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/alibaba/youku-sdk-tool-woodpecker/master/woodpecker_logo.png" width="400">
</p>

啄幕鸟，即手机屏幕上的啄木鸟，专抓App里的Bug。啄幕鸟集合了UI检查、对象查看、方法监听等多种开发工具，通过拾取UI控件、查看对象属性、监听方法调用、App内抓包等，不依赖电脑联调，直接获取运行时数据，快速定位Bug，提高开发效率。啄幕鸟提供了插件化的工具平台，简便易用，零侵入、零依赖、易接入、易扩展。   
# 功能简介
1.UI检查：快速查看页面布局、UI控件间距、字体颜色、UI控件类名、对象属性/成员变量、图片URL等。   
2.JSON抓包：便捷JSON抓包工具，通过监听系统json解析抓包。    
3.方法监听：Bug听诊器，可监听App中任意OC方法的调用，输出调用参数、返回值等信息，可以通过屏幕日志输入监听、KVC取值等命令，支持后台配置命令。      
4.po命令：执行类似LLDB的po命令，在App运行时执行po命令，调用任意方法。      
5.系统信息：查看各种系统名称、版本、屏幕、UA等信息，支持外部添加信息。       
6.SandBox：查看沙盒文件，导出文件等。     
7.Bundle：查看、导出Bundle目录中的内容。   
8.Crash：查看Crash日志，需先打开一次Crash插件以开启Crash监控。   
9.Defaults：查看、新增、删除User Defaults。    
10.清除数据：清除所有沙盒数据、User Default。   
11.触点显示：显示手指触控。    
12.UI对比：支持将设计图导入到App中进行对比，并可画线、标注需修改的地方，方便UI走查。   
13.查看图片资源：查看、导出App中的资源图片。   
14.CPU：查看CPU占用。   
15.内存：查看内存占用。   
16.FPS：查看App帧率。   
17.网络流量：查看发送、接收网络流量。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_all_plugins.PNG" style="border:1px solid black" height="500">
<br>啄幕鸟插件
</p>

# 接入
## 版本要求
iOS 8.0及以上。

## Pod接入
> ```
>pod  'YKWoodpecker'   
> ```
推荐更新使用最新版本啄幕鸟，现最新版本：1.2.5。

## Get Started
##### 打开啄幕鸟
> #import "YKWoodpecker.h"
> ```
>    // 方法监听命令配置JSON地址 * 可选，如无单独配置，可使用 https://github.com/ZimWoodpecker/WoodpeckerCmdSource 上的配置
>    [YKWoodpeckerManager sharedInstance].cmdSourceUrl = @"https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerCmdSource/master/cmdSource/default/cmds_cn.json";
>    
>    // Release 下可开启安全模式，只支持打开安全插件 * 可选
>#ifndef DEBUG
>    [YKWoodpeckerManager sharedInstance].safePluginMode = YES;
>#endif
>
>    // 设置 parseDelegate，可通过 YKWCmdCoreCmdParseDelegate 协议实现自定义命令 * 可选
>    [YKWoodpeckerManager sharedInstance].cmdCore.parseDelegate = self;
>    
>    // 显示啄幕鸟
>    [[YKWoodpeckerManager sharedInstance] show];
>    
>    // 启动时可直接打开某一插件 * 可选
>//    [[YKWoodpeckerManager sharedInstance] openPluginNamed:@"xxx"];
>
> ```
更多参见Demo工程。

## 安全说明
啄幕鸟不依赖任何第三方库或数据。啄幕鸟代码中没有使用任何+load、+initialize等方法，啄幕鸟入口不显示则不会执行任何代码。如需线上使用啄幕鸟，应保护好开启入口，啄幕鸟支持安全模式，可在Release下开启安全模式，只支持打开安全插件，现有安全插件：UI检查、系统信息、触点显示。扩展插件注册时设置isSafePlugin=YES即可声明为安全插件，详见插件开发。    
> ```
>    // Release 下可开启安全模式，只支持打开安全插件 * 可选
>#ifndef DEBUG
>    [YKWoodpeckerManager sharedInstance].safePluginMode = YES;
>#endif
> ```

# 插件功能介绍
## 1. UI检查插件
UI检查插件包含控件拾取和测距条两个工具，在屏幕上点一点即可获取布局、颜色、字体、圆角、图片URL等信息。  
<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_ui_check_demo.gif" style="border:1px solid black" height="500">
<br>UI检查插件
</p>

### 1.1 控件拾取
控件拾取根据手指在屏幕上的点击坐标，递归遍历View层级，获取包含触点坐标的最靠前的UI元素，在屏幕上直观显示相关信息，也可帮助了解UI布局、定位UI代码。  

#### 控件拾取功能   
◆ 单击拾取当前点击的view，双击可跳过当前view，以拾取下层view，以防止view被同级view挡住拾取不到。     
◆ 三个手指同时点击可切换拾取模式，只拾取响应链上的view，以防止屏幕上盖了一层view，影响拾取。     
◆ 拾取后用线条和标注显示被拾取view的大小、位置，或与之前选中view的间距，简单直观，无需计算。       
◆ 控件拾取信息区显示控件的类名、大小、透明度、圆角、hidden、文本、字体、颜色、图片尺寸、图片URL等信息，方便地获取运行时数据。   
◆ 信息区提供父层按钮，点击拾取superview，层层拾取，即可了解UI布局，并根据view类名快速定位代码。     
◆ 信息区根据选中元素的不同，提供文本、图片等按钮，以复制文本，查看、导出图片。      
◆ 单击信息区可打开分享面板导出信息。      
◆ 双击信息区可查看对象全部属性、成员变量。    

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_ui_check.png" style="border:1px solid black" height="500">
<br>UI检查-拾取控件
</p>

#### 控件拾取功能扩展
可以通过系统通知获得拾取到的控件并在信息区域显示自定义信息，格式如下：

> ```
>extern NSString *const YKWPluginSendMessageNotification;       /**< 插件发送信息通知 = @"YKWPluginSendMessageNotification" > */
>extern NSString *const YKWPluginReceiveMessageNotification;    /**< 插件接收信息通知 = @"YKWPluginReceiveMessageNotification" > */
>/*
> 控件拾取插件：
>    发送格式：
>    notification.object = @"ProbePluginNotification";
>    notification.userInfo[@"view"] = 拾取到的UIView;
>    接收格式：
>    notification.object = @"ProbePluginNotification";
>    notification.userInfo[@"msg"] = 需要显示的信息;
>*/
>
> ```

### 1.2 对象查看
App中所有的对象通过继承、代理、属性等关系，可以看作一个或多个连通图，从一个对象开始，可以查看到连通图里任一个对象的属性、成员变量，获取运行时数据，以定位问题。   

#### 对象查看功能
◆ 双击控件拾取的信息区即可打开对象查看，对象查看会显示拾取对象的属性、成员变量列表。   
◆ 一个对象的属性、成员变量一般声明在不同的类中，一个列表只显示对象在某一类中声明的属性、成员变量，点击superclass即可查看父类中的声明。   
◆ 在属性、成员变量列表中单击查看下一对象，双击打印对象description。   
◆ KVC取值：在日志控制台中输入 k key.path 格式即可对最右侧列表对象KVC取值，如输入 k layer.cornerRadius 即可读取圆角大小。   
◆ 点击“屏显控件”可将UIView及其子类对象在控件拾取中显示。   
◆ 可在对象查看中使用po命令，详见po命令介绍。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_object_check.png" style="border:1px solid black" height="500">
<br>查看对象全部属性
</p>

### 1.3 测距条
对于某些不能通过控件拾取查看的大小间距，如行间距等，啄幕鸟提供了测距条工具，在屏幕上添加大小、位置可控的View作为标尺测量间距。   

#### 测距条功能
◆ 点击“+”添加一个测距条，可添加任意多个测距条。   
◆ 双击一个测距条可以将其删除。   
◆ 单击一个测距条可将其选中，以改变其位置大小。   
◆ 可在输入框按宽高输入测距条大小。   
◆ 可通过按钮控制测距条的位置大小，按钮支持长按。   
◆ 点击“Dp”可改变控制精度为dp或像素。    

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_ruler.png" style="border:1px solid black" height="500">
<br>UI检查-测距条
</p>

## 2 JSON抓包插件
JSON抓包插件通过监听[NSJSONSerialization JSONObjectWithData:options:error:]方法抓取数据，对于不使用此方法解析的JSON则无法抓包。

#### JSON抓包功能
◆ 打开插件自动开始监听JSON解析，抓取数据。
◆ 可能会抓取多条数据，可通过数据长度区分。
◆ 单击可查看、检索抓取到的JSON数据。
◆ 长按数据可通过Airdrop等分享JSON数据。

<p align="center">
  <img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_json_grab.png" title="Woodpecker" height="600">
  <br>
</p>

## 3 方法监听插件
### 3.1 屏幕日志
为方便各插件在App内显示日志、接受用户输入，啄幕鸟中添加了屏幕日志模块。   

#### 屏幕日志功能
◆ 拖动空白处可调整屏幕日志位置，拖动“◢”按钮可调整界面大小。   
◆ 日志颜色可定制，以区分日志类型。   
◆ 屏幕日志支持正则表达式和目标字符串过滤不想要的日志，正则表达式过滤只会显示正则匹配到的日志，目标字符串会过滤掉不包含目标字符串的日志。   
◆ 屏幕日志支持日志搜索，点击ⓢ按钮可以打开/关闭日志搜索框，搜索支持正则表达式。   
◆ 日志可通过分享面板导出。   
◆ 屏幕日志支持界面扩展，可在屏幕日志下方添加自定义View，展示自定义功能，自定义View会跟随屏幕日志移动及改变宽度。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_sysinfo.png" style="border:1px solid black" height="500">
<br>系统信息插件中直接使用了屏幕日志显示信息
</p>

### 3.2 方法监听
方法监听利用OC的运行时机制，Hook被监听方法，输出方法调用参数、返回值、调用栈等信息，动态获取运行时数据，辅助Debug。监听网络方法即可实现App内抓包功能。  

#### 方法监听功能
◆ 使用命令行交互，扩展性强，功能多样。   
◆ 命令支持后台配置，方便快速输入命令。   
◆ 可监听实例方法、类方法，支持同时监听多个对象、多个方法。   
◆ 通过屏幕日志输出监听到的参数、返回值，JSON格式化显示。   
◆ 保存监听到的对象、返回值，可使用命令对其KVC取值。   
◆ 保存监听到方法的调用栈，可使用相关命令查看。    

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_listen_in_demo.gif" style="border:1px solid black" height="500">
<br>方法监听
</p>

### 3.3 方法监听命令
方法监听需要输入类名、方法名、keypath等参数，故使用命令行交互，扩展性好，配合命令配置，输入也较方便。   

#### 命令简介
◆ 命令使用同一格式，<命令名缩写><空格><命名参数><空格><命名参数>，如监听命令 L className methodName，KVC取值命令 k keyPath，调用栈查看命令k callStack。   
◆ 命令名缩写不区分大小写，方便输入。   
◆ 命令可通过后台配置，一键输入，多条命令以分号分隔。   
◆ 命令支持扩展。   

#### 命令说明
##### 查看输入历史 
命令格式： h/H     
输入h或H回车后会显示输入历史记录，输入记录前面的数字回车可实现快速输入命令，也可在任意状态输入1回车，快速输入上次输入的命令。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_history.png" style="border:1px solid black" height="500">
<br>输入历史命令
</p>

##### 方法监听
添加实例方法监听命令格式： l/L ClassName Method:Name:     
按上述格式输入回车后会Hook相应类的类方法或实例方法，并显示监听成功，下次对应方法被调用时会按OC语法格式显示方法调用时传入的参数及返回值的description。     
注意方法监听可能会产生风险，例如同时监听子类和父类的同名方法会导致崩溃，监听基础类的常用方法也可能会导致崩溃，如监听UIView的setFrame:方法时，由于显示日志也需要调用setFrame:方法，会导致循环调用；监听调用频繁的方法需要显示大量日志，可能造成程序卡死等。暂未对方法监听做限制，此功能可能会使App变得不稳定，应谨慎使用方法监听功能。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_listen_in.png" style="border:1px solid black" height="500">
<br>点击AF请求按钮后，监听到NSJSONSerialization方法被调用，显示日志
</p>

查看正在监听的方法列表命令： l/L     
可同时添加多个方法监听，输入l或L可显示所有正在监听的类及方法名。   

清除所有监听命令格式： l/L clr     
按上述格式输入会移除所有方法监听。（clr: clear的缩写）   

##### 查看监听到的对象
查看监听到的对象命令格式： k/K     
方法监听命令会将监听到的对象参数保存在一个数组中（非对象参数不保存），每次监听到某个方法调用都会更新数组，输入k或K回车可查看数组内容。数组中第一个对象为self，即被监听类的实例，之后按参数传递顺序排列，如有返回对象则保存在最后。     
输入k callStack可以查看监听到的调用栈。   

对监听到的第N个对象KeyPath取值： k/K N Key.Path     
可以对监听到的对象进行KeyPath取值，例如监听到UIView addSubview:方法后（当然不建议监听这个方法），监听数组中会存放对应的(superview，subview)，输入k 2 layer.cornerRadius可读取subview的圆角大小。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_k_cmd.png" style="border:1px solid black" height="500">
<br>监听到AFJSONResponseSerializer相关方法后，输入"k 2 URL"读取参数列表第二个对象的URL属性，获取URL。输入"k"即可查看监听到的参数、返回值列表。
</p>

##### 添加监听后命令
添加监听后命令格式：p/P   
监听后命令会在监听到任意方法调用之后执行，现仅支持k命令，例如输入"p k"添加监听后命令k之后，每次监听到方法调用后会执行k命令输出监听到的参数和返回值。   

##### 目标字符串日志过滤
添加目标字符串命令格式： f/F ToFindString     
目标字符串：可以在日志控制台添加目标字符串，添加后，只会输出包含目标字符串的日志，其他日志会显示<日志不包含目标字符串>，用以过滤日志（基本信息输出不过滤）。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_listen_in.png" style="border:1px solid black" height="500">
<br>执行"f {"命令，添加"{"为目标字符串，由于只有返回值包含目标字符串"{"，故只显示了返回值的日志，其他日志被过滤。
</p>

查看目标字符串列表： f/F      
可添加多条目标字符串，一条日志必须包含列表中所有目标字符串才会被显示，输入f或F可查看当前目标字符串列表。   

清空目标字符串列表： f/F clr   

##### 正则表达式日志过滤
添加过滤正则表达式： r/R RegExpression      
正则表达式过滤：添加过滤正则后，只会输出正则匹配到的字符串，其他日志会显示<日志不匹配正则>，用以过滤日志（基本信息输出不过滤）。    

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_filter.png" style="border:1px solid black" height="500">
<br>执行"r ("cmdName" : ".+")"命令，添加"("cmdName" : ".+")"为过滤正则，则只会显示正则匹配出的日志。
</p>

查看正则列表： r/R     
可添加多个正则表达式，每一个匹配都会输出，输入r或R可查看当前正则列表。   

清空过滤正则列表： r/R clr

### 3.4 自定义命令
方法监听支持命令扩展，通过 YKWCmdCoreCmdParseDelegate 协议可以获取命令并解析执行自定义操作。   
>#import "YKWoodpecker.h"
>```
>// 设置命令解析代理
>[YKWoodpeckerManager sharedInstance].cmdCore.parseDelegate = self;
> ```
>#pragma mark - YKWCmdCoreCmdParseDelegate
>// 实现命令解析协议，
>- (BOOL)cmdCore:(YKWCmdCore *)core shouldParseCmd:(NSString *)cmdStr {
>    // 判断是否为自定义命令
>    if ([cmdStr hasPrefix:@"MyCmd"]) {
>        // 处理自定义命令
>        // -----------
>        // 显示日志
>        [[YKWoodpeckerManager sharedInstance].screenLog log:@"Calling my cmd"];
>        return NO;
>    }
>    return YES;
>}
> ```
> 

### 3.5 后台命令配置
后台命令配置会显示在屏幕日志下方，方便命令输入，使用如下格式的JSON提供命令配置。   
<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_cmds.png" height="200">
<br>命令配置JSON格式
</p>

可在啄幕鸟初始化时指定配置JSON的获取地址，否则使用默认配置。推荐在 https://github.com/ZimWoodpecker/WoodpeckerCmdSource 工程中建立配置，方便命令共享。   

## 4 po命令插件
po命令是iOS开发中最常用Debug命令，啄幕鸟让你在App运行时也可以随时随地执行po命令，随时随地Debug。

#### po命令功能
◆ 输入h可查看输入历史记录。   
◆ 其他几乎和LLDB po命令一样。     
◆ 输入po [N ...]即可对列表中第N个对象执行po命令。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_po_cmd.png" style="border:1px solid black" height="500">
<br>po命令
</p>

⚠ 当前po命令仅支持入参为int、long、BOOL、float、double、NSString、NSNumber，返回值为空、int、long、BOOL、float、double、id类型的方法，且参数不超过3个，嵌套不超过两层调用，po命令还在进一步优化中，欢迎共建，敬请期待。

## 5 系统信息插件
系统信息插件可以方便的查看系统、版本、UA等信息。   
<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_sysinfo.png" style="border:1px solid black" height="500">
<br>系统信息插件
</p>

### 系统信息插件功能扩展
可以通过通知添加自定义信息显示，格式如下：

> ```
>extern NSString *const YKWPluginSendMessageNotification;       /**< 插件发送信息通知 = @"YKWPluginSendMessageNotification" > */
>extern NSString *const YKWPluginReceiveMessageNotification;    /**< 插件接收信息通知 = @"YKWPluginReceiveMessageNotification" > */
>/*
> 系统信息插件：
>    发送格式：
>    notification.object = @"SysInfoNotification";
>    接收格式：
>    notification.object = @"SysInfoNotification";
>    notification.userInfo[@"msg"] = 需要显示的信息;
>*/
>
> ```

## 6 SandBox插件、Bundle插件
SandBox插件用以查看App沙盒文件，Bundle插件用以查看Bundle目录，支持打开文本、图片类文件，或通过AirDrop等方式导出文件。

## 7 Crash插件
查看crash日志需要预先打开一次crash插件以开启crash监控，在crash发生后即可再次打开查看crash日志，可以通过AirDrop等方式分享日志。

## 8 Defaults插件
Defaults插件支持搜索、查看、删除User Defaults，新增、修改字符串类型或数字类型的User Defaults，

## 9 清除数据插件
清除数据插件会将App沙盒目录下各文件夹清空，清除所有相关数据以及user defaults。

## 10 触点显示插件
打开触点插件会交换UIWindow的sendEvent:方法，在每个点击处显示水波动画，方便录屏等场景显示触点。

## 11 UI对比插件
UI对比可以从系统相册中导入设计图片以与App对比设计还原度。

### UI对比功能
◆ 点击“+”按钮导入图片，支持多张图片，图片可移动，如果图片大小与屏幕大小相同则图片不能移动。   
◆ 点击图片可以选中，滑动控制条可以调整图片透明度。   
◆ 点击“-”按钮删除图片。   
◆ 点击“✎”按钮打开/关闭画线功能。   
◆ 点击“↺”按钮回退一次画线。   

<p align="center" style="font-size:11px;">
<img src="https://raw.githubusercontent.com/ZimWoodpecker/WoodpeckerResources/master/woodpecker_demo_ui_compare.png" style="border:1px solid black" height="600">
<br>UI对比插件
</p>

## 12 查看图片资源插件
查看App中所有自带图片，Assets图片被加密压缩，暂不支持查看。   

## 13 性能插件
性能插件主要有CPU、内存、FPS、网络流量插件，可以实时查看App的相关性能。

# 插件开发
## 插件协议
啄幕鸟使用插件式开发，所有插件须符合YKWPluginProtocol协议，实现runWithParameters: 方法，在点击插件时会执行此方法以开启插件。不会强制检查是否遵守YKWPluginProtocol，实现协议方法即可。

>#import "YKWPluginProtocol.h"
> ```
>@protocol YKWPluginProtocol <NSObject>
>
>- (void)runWithParameters:(NSDictionary *)paraDic;
>
>@end
> ```

## 内部插件
内部插件会随啄幕鸟开源，新插件需实现YKWPluginProtocol协议中的方法，并在插件列表plist中添加相关插件信息，测试无bug后即可提交pull request合并到项目中。

## 外部插件
可以注册任意符合插件协议的第三方类为插件在啄幕鸟中打开，使用如下方法注册插件：

>  #import "YKWoodpecker.h"
> ```
> /**
> 注册插件
>
> @param parasDic 格式参见 YKWPluginModel
> @{
> @"isSafePlugin" : @(NO),
> @"pluginName" : @"",
> @"pluginIconName" : @"",
> @"pluginCharIconText" : @"",
> @"pluginCharIconColorHex" : @"",
> @"pluginCategoryName" : @"",
> @"pluginClassName" : @"",
> @"pluginParameters" : @{}
> }
> @param position 插件显示位置，0...N-1, -1显示在最后
>
> */
>- (void)registerPluginWithParameters:(NSDictionary *)parasDic atIndex:(NSInteger)position;
>- (void)registerPluginWithParameters:(NSDictionary *)parasDic;
>- (void)registerPluginCategory:(NSString *)pluginCategoryName atIndex:(NSInteger)index;
>
> ```

推荐使用pluginCharIconText指定一个字符作为插件图标，以节省包大小。

> ```
>// Demo for registering a plugin
>[[YKWoodpeckerManager sharedInstance] registerPluginWithParameters:@{@"pluginName" : @"XXX",
>                                                                     @"isSafePlugin" : @(NO),
>                                                                     @"pluginInfo" : @"by user_XX",
>                                                                     @"pluginCharIconText" : @"x",
>                                                                     @"pluginCategoryName" : @"自定义",
>                                                                     @"pluginClassName" : @"ClassName"}];
>
> ```

可以使用registerPluginCategory:atIndex:方法添加一个工具类别，并定制显示位置。
  
> ```
>  /**
> Register a plugin category or change the position of a plugin category.
>
> @param pluginCategoryName Plugin category name.
> @param index Position to show the category, 0...N-1, or -1 for the last.
> */
>- (void)registerPluginCategory:(NSString *)pluginCategoryName atIndex:(NSInteger)index;
> ```

## 安全插件
在安全模式下只能打开安全插件，注册安全插件时需设置isSafePlugin=YES。

# Author
- [Zim](https://github.com/ZimWoodpecker)

# Collaborators
- [Betterjbp](https://github.com/betterjbp)
- [CrossPQW](https://github.com/crossPQW)
- [Dylanlai](https://github.com/dylanlai)

- Special thanks to Mining for the UI design.

# Licenses

All source code is licensed under the [MIT License](https://github.com/alibaba/youku-sdk-tool-woodpecker/blob/master/LICENSE).

# Architecture

<p align="center" style="font-size:11px;">
<img src="https://github.com/ZimWoodpecker/WoodpeckerResources/blob/master/woodpecker_arch.png" style="border:1px solid black" height="500">
</p>
