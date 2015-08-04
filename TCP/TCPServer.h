//
//  TCPServer.h
//  SmartConfigDemoIos
//
//  Created by YeYe on 15/7/21.
//  Copyright © 2015年 YeYe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "ConnectionViewController.h"
#import "MsgViewController.h"
#import "GCDAsyncUdpSocket.h"

@interface TCPServer : UIViewController<GCDAsyncUdpSocketDelegate>{
    //UDP socket 实例
    GCDAsyncUdpSocket *sendUdpSocket;
    
    NSString* receivedIP;
    Boolean isConnected;
}

+ (TCPServer *)sharedSocketServe;

@property (nonatomic, strong) AsyncSocket* socket;       // socket
@property (nonatomic, retain) NSTimer* heartTimer;      // 心跳计时器
@property (nonatomic, strong) ConnectionViewController *connectionDelegate;      // Connection试图控制器的委托指针
@property (nonatomic, strong) MsgViewController *msgControllerDelegate;

//  socket连接
- (void)startConnectSocket;
- (void)cutOffSocket;
// 发送消息
- (void)sendMessage:(id)message;

- (void)startUDPListening;

- (Boolean)getIsTCPConnected;
- (BOOL)getIsConnectedBool;

@end
