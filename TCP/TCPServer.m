//
//  TCPServer.m
//  SmartConfigDemoIos
//
//  Created by YeYe on 15/7/21.
//  Copyright © 2015年 YeYe. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "TCPServer.h"
#import "SmartEncoder.h"
#import "SmartConfigDemoIos-swift.h"

// 单例模式的TCP长连接

@implementation TCPServer

static TCPServer *socketServe = nil;

#pragma mark public static methods

// IP和端口
#define HOST @"192.168.1.10"
#define PORT 6002
// 设置连接超时
#define TIME_OUT 20
// 单次最大接收字节数
#define MAX_BUFFER 1024

LEDControllerSingletonHelper *objLEDHelper;

+ (TCPServer *)sharedSocketServe {
    objLEDHelper = [[LEDControllerSingletonHelper alloc]init];
    @synchronized(self) {
        if(socketServe == nil) {
            socketServe = [[[self class] alloc] init];
        }
    }
    return socketServe;
}


+(id)allocWithZone:(NSZone *)zone
{
    @synchronized(self)
    {
        if (socketServe == nil)
        {
            socketServe = [super allocWithZone:zone];
            return socketServe;
        }
    }
    return nil;
}

/**************************
 * UDP接收广播方法
 ****************/
// 创建UDP套接字
-(void)startUDPListening{
    // 重置接收IP
    receivedIP=@"";
    isConnected=false;
    
    dispatch_queue_t dQueue = dispatch_queue_create("client udp socket", NULL);
    
    //1.创建一个 udp socket用来和服务器端进行通讯
    sendUdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dQueue socketQueue:nil];
    
    //2.banding一个端口(可选),如果不绑定端口, 那么就会随机产生一个随机的电脑唯一的端口
    //端口数字范围(1024,2^16-1)
    [sendUdpSocket bindToPort:6000 error:nil];
    
    //3.等待接收对方的消息
    [sendUdpSocket receiveOnce:nil];
    
    NSError *error;
    [sendUdpSocket enableBroadcast:YES error:&error];
    
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    SmartEncoder* encoder = [[SmartEncoder alloc]init];
    NSString *ip = [GCDAsyncUdpSocket hostFromAddress:address];
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // 继续来等待接收下一次消息
    NSLog(@"收到服务端的响应 [%@:%d] %@", ip, port, s);
    if(1){
        receivedIP = [encoder getIPFromBroadcast:s];
        if([receivedIP length]!=0){
            NSLog(@"接收到IP地址:%@",receivedIP);
        }
    }
    
    [sock receiveOnce:nil];
}

/**************************
 * TCP方法
 ****************/
- (void)startConnectSocket
{
    self.socket = [[AsyncSocket alloc] initWithDelegate:self];
    [self.socket setRunLoopModes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    if ( ![self SocketOpen:receivedIP port:PORT] )
    {
        
    }
    
}

- (NSInteger)SocketOpen:(NSString*)addr port:(NSInteger)port
{
    
    if (![self.socket isConnected])
    {
        NSError *error = nil;
        [self.socket connectToHost:addr onPort:port withTimeout:TIME_OUT error:&error];
    }
    
    return 0;
}

/**
 * 连接成功后的回调
 */
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    isConnected=true;
    //这是异步返回的连接成功，
    NSLog(@"didConnectToHost");
    [_connectionDelegate TCPConnected];
    //通过定时器不断发送消息，来检测长连接
    //self.heartTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(checkLongConnectByServe) userInfo:nil repeats:YES];
    //[self.heartTimer fire];
    //读取消息
    [self.socket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:MAX_BUFFER tag:0];
}

// 心跳连接
-(void)checkLongConnectByServe{
    
    // 向服务器发送固定可是的消息，来检测长连接
    NSString *longConnect = @"connect is here";
    NSData   *data  = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:1 tag:1];
}

/**
 * 断开连接
 */
-(void)cutOffSocket
{
    [self.socket disconnect];
}

/**
 * 断开回调
 */
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    isConnected=false;
    NSLog(@"7878 sorry the connect is failure %ld",sock.userData);
    [self.connectionDelegate TCPDisconnected];
}

//设置写入超时 -1 表示不会使用超时
#define WRITE_TIME_OUT -1

- (void)sendMessage:(id)message
{
    //像服务器发送数据
    NSData *cmdData = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:cmdData withTimeout:WRITE_TIME_OUT tag:1];
}

//发送消息成功之后回调
- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    
}

//接受消息成功之后回调
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    //服务端返回消息数据量比较大时，可能分多次返回。所以在读取消息的时候，设置MAX_BUFFER表示每次最多读取多少，当data.length < MAX_BUFFER我们认为有可能是接受完一个完整的消息，然后才解析
    if( data.length < MAX_BUFFER )
    {
        //收到结果解析...
        //NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        NSString *aString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"读取到消息%@",aString);
        //解析出来的消息，可以通过通知、代理、block等传出去
        [self.socket readDataWithTimeout:-1 buffer:nil bufferOffset:0 maxLength:MAX_BUFFER tag:0];
        if(_msgControllerDelegate!=nil){
            [_msgControllerDelegate msgReceived:aString];
        }
        // 传递给LED面板
        dispatch_async(dispatch_get_main_queue(), ^{
            [objLEDHelper sendTCPMsgToSingleton:aString];
        });
    }
}

- (Boolean)getIsTCPConnected{
    return isConnected;
}

- (BOOL)getIsConnectedBool{
    if(isConnected)
        return true;
    else
        return false;
}

@end
