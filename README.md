# Swift2.0-TCP-UDP-Helper
TCP/UDP helper based on AsyncSocket which can be called by Swift language. And singleton.

基于AsyncSocket做的Swift2.0封装，通过SmartConfigDemoIos-Bridging-Header桥接到AsyncSocket，Swift编写的controller用单例模式实现AsyncSocket的异步同步。

项目需要用swift编写一个iOS的LED控制程序，连接的微型wifi模块工作在STA模式后会间隔往指定的端口发送UDP消息，同时建立一个TCP服务器，所以需要使用TCP和UDP连接。
AsyncSocket挺火，但是是OC的，所以在写完一个TCPServer.m后用SmartConfigDemoIos-Bridging-Header混编到Swift，接收消息在TCP是异步，所以把用Swift编写的ViewController改成单例。
希望对在Swift2.0（或以下）使用TCP和UDP的童鞋有所帮助，可以快速的把AsyncSocket应用在你的Swift项目中。
