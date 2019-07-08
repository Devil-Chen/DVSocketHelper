//
//  DVSocketManager.m
//  DVSocketHelper
//
//  Created by devil on 2019/6/24.
//  Copyright © 2019 devil. All rights reserved.
//

#import "DVSocketManager.h"
#import "GCDAsyncSocket.h"

#define QueueName "com.devil.concurrent"
//block为空判断，不为空则调用。
#define SafeBlockCall(block,...) ({!block?nil:block(__VA_ARGS__);})
//是否输出日志
#if DEBUG
#define DVLog(...) NSLog(__VA_ARGS__);
#else
#define DVLog(...)
#endif

@interface DVSocketManager()<GCDAsyncSocketDelegate>
//队列
@property (nonatomic,strong) dispatch_queue_t currentQueue;
//socket
@property (nonatomic,strong) GCDAsyncSocket *clientSocket;
//错误回调
@property (nonatomic,copy) DVErrorCallBack errorCallBack;
//非错误回调
@property (nonatomic,copy) DVActionCallBack actionCallBack;
//读取数据回调
@property (nonatomic,copy) DVReadDataCallBack readDataCallBack;
//写数据回调
@property (nonatomic,copy) DVWriteDataCallBack writeDataCallBack;
//连接地址
@property (nonatomic,strong) NSString *address;
//连接端口
@property (nonatomic,assign) uint16_t port;

//配置
@property (nonatomic,strong) DVSocketConfig *config;

//发送文件时，文件总长度
@property (nonatomic,assign) NSUInteger sendFileTotalLength;
//发送文件时，当前已经发送数据的长度
@property (nonatomic,assign) NSUInteger sendFileCurrentLength;
//当前发送数据的类型(DV_WriteFileData||DV_WriteOtherData)
@property (nonatomic,assign) DVActionCode sendDataType;
@end

@implementation DVSocketManager
static DVSocketManager *manager;
+(DVSocketManager *(^)(void)) instance
{
    return ^(){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (!manager) {
                manager = [[DVSocketManager alloc] init];
                manager.config = [DVSocketConfig defaultConfig];
                manager.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:manager delegateQueue:dispatch_get_main_queue()];
            }
        });
        return manager;
    };
}

//懒加载
-(dispatch_queue_t) currentQueue
{
    if (!_currentQueue) {
        _currentQueue = dispatch_queue_create(QueueName, DISPATCH_QUEUE_CONCURRENT);
    }
    return _currentQueue;
}

//当前ClientSocket
-(id (^)(void)) currentClientSocket
{
    return ^(){
        return self.clientSocket;
    };
}

//设置连接地址和端口
-(DVSocketManager *(^)(NSString *address)) setAddress
{
    return ^(NSString *address){
        self.address = address;
        return self;
    };
}
-(DVSocketManager *(^)(uint16_t port)) setPort
{
    return ^(uint16_t port){
        self.port = port;
        return self;
    };
}

//设置配置
-(DVSocketManager *(^)(DVSocketConfig *config)) setSocketConfig
{
    return ^(DVSocketConfig *config){
        self.config = config;
        return self;
    };
}

//编辑已有的配置
-(DVSocketManager *(^)(void(^editConfig)(DVSocketConfig *config))) editSocketConfig
{
    return ^(void(^editConfig)(DVSocketConfig *config)){
        editConfig(self.config);
        return self;
    };
}

//设置超时
-(DVSocketManager *(^)(NSTimeInterval timeout)) setConnectTimeout
{
    return ^(NSTimeInterval timeout){
        self.config.connectTimeout = timeout;
        return self;
    };
}
-(DVSocketManager *(^)(NSTimeInterval timeout)) setReadDataTimeout
{
    return ^(NSTimeInterval timeout){
        self.config.readDataTimeout = timeout;
        return self;
    };
}
-(DVSocketManager *(^)(NSTimeInterval timeout)) setWriteDataTimeout
{
    return ^(NSTimeInterval timeout){
        self.config.writeDataTimeout = timeout;
        return self;
    };
}

//设置错误回调
-(DVSocketManager *(^)(DVErrorCallBack errorCallBack)) setErrorCallBack
{
    return ^(DVErrorCallBack errorCallBack){
        self.errorCallBack = errorCallBack;
        return self;
    };
}
//设置非错误回调
-(DVSocketManager *(^)(DVActionCallBack actionCallBack)) setActionCallBack
{
    return ^(DVActionCallBack actionCallBack){
        self.actionCallBack = actionCallBack;
        return self;
    };
}
//设置读取数据回调
-(DVSocketManager *(^)(DVReadDataCallBack readDataCallBack)) setReadDataCallBack
{
    return ^(DVReadDataCallBack readDataCallBack){
        self.readDataCallBack = readDataCallBack;
        return self;
    };
}
//设置写数据回调
-(DVSocketManager *(^)(DVWriteDataCallBack writeDataCallBack)) setWriteDataCallBack
{
    return ^(DVWriteDataCallBack writeDataCallBack){
        self.writeDataCallBack = writeDataCallBack;
        return self;
    };
}

//连接主机
-(DVSocketManager *(^)(void))connect
{
    return ^(){
        NSError *error;
        if (!self.address || [self.address isEqualToString:@""] || !self.port) {
            error = [NSError errorWithDomain:@"连接地址或端口不能为空" code:DV_InputError userInfo:nil];
            SafeBlockCall(self.errorCallBack,DV_ConnectError,[error localizedDescription]);
            return self;
        }
        if(self.isConnected()){
            SafeBlockCall(self.errorCallBack,DV_ConnectError,@"已经连接服务器，请先断开再连接。");
            return self;
        }
        //开始连接
        [self.clientSocket connectToHost:self.address onPort:self.port withTimeout:self.config.connectTimeout error:&error];
        if (error) {
            SafeBlockCall(self.errorCallBack,DV_ConnectError,[error localizedDescription]);
        }else if(self.actionCallBack){
        SafeBlockCall(self.actionCallBack,DV_StartConnect,self,@{@"action":@"startConnect",@"address":self.address,@"port":[NSNumber numberWithInt:self.port]});
        }
        return self;
    };
}

//读取数据
-(DVSocketManager *(^)(long tag)) readData
{
    return ^(long tag){
        if(!self.isConnected()){
            SafeBlockCall(self.errorCallBack,DV_ConnectError,@"请先连接服务器");
            return self;
        }
        [self.clientSocket readDataWithTimeout:self.config.readDataTimeout tag:tag];
        return self;
    };
}

//设置每一次发送数据之后都读取数据
-(DVSocketManager *(^)(BOOL mark)) setReadDataWithAnySendData
{
    return ^(BOOL mark){
        self.config.isAfterAnySendDataToReadData = mark;
        return self;
    };
}

//写数据
-(DVSocketManager *(^)(id content,long tag)) writeData
{
    return ^(NSData *content,long tag){
        if(!self.isConnected()){
            if (self.errorCallBack) {
               SafeBlockCall(self.errorCallBack,DV_ConnectError,@"请先连接服务器");
            }
            return self;
        }else if ([content length] == 0) {
            SafeBlockCall(self.errorCallBack,DV_InputError,@"输入的数据为空");
            return self;
        }
        if ([content isKindOfClass:[NSData class]]) {
            self.sendFileTotalLength = [content length];
            self.sendFileCurrentLength = 0;
            self.sendDataType = DV_WriteFileData;
            [self.clientSocket writeData:content withTimeout:self.config.writeDataTimeout tag:tag];
        }else if([content isKindOfClass:[NSString class]]){
            self.sendDataType = DV_WriteOtherData;
            [self.clientSocket writeData:[(NSString *)[self getFormatWriteData:content] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:self.config.writeDataTimeout tag:tag];
        }else if([content isKindOfClass:[NSNumber class]]){
            self.sendDataType = DV_WriteOtherData;
            [self.clientSocket writeData:[(NSString *)[self getFormatWriteData:content] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:self.config.writeDataTimeout tag:tag];
        }else{
            return self;
        }
        
        return self;
    };
}

//获取按照给定的格式组装写出的数据
-(id) getFormatWriteData:(id)content
{
    
    if (!self.config.sendStringDataFormat || [self.config.sendStringDataFormat isEqualToString:@""]) {
        return content;
    }else{
        NSInteger count = [[self.config.sendStringDataFormat mutableCopy] replaceOccurrencesOfString:@"%@"
                                                                                    withString:@"%@"
                                                                                       options:NSLiteralSearch
                                                                                         range:NSMakeRange(0, [self.config.sendStringDataFormat length])];
        if (count != 1) {
            return content;
        }
    }
    if ([content isKindOfClass:[NSData class]]) {
        NSString *contentStr = [[NSString alloc] initWithData:content encoding:NSUTF8StringEncoding];
        NSString *finalStr = [NSString stringWithFormat:self.config.sendStringDataFormat,contentStr];
        return [finalStr dataUsingEncoding:NSUTF8StringEncoding];
    }else if([content isKindOfClass:[NSString class]]){
        NSString *finalStr = [NSString stringWithFormat:self.config.sendStringDataFormat,content];
        return finalStr;
    }else if([content isKindOfClass:[NSNumber class]]){
        NSString *contentStr = [(NSNumber *)content stringValue];
        NSString *finalStr = [NSString stringWithFormat:self.config.sendStringDataFormat,contentStr];
        return finalStr;
    }else{
        return content;
    }
}

//关闭连接
-(DVSocketManager *(^)(void)) closeConnection
{
    return ^(){
        if (![self.clientSocket isConnected]) {
            SafeBlockCall(self.errorCallBack,DV_ConnectError,@"请先连接服务器");
        }
        [self.clientSocket disconnect];
        return self;
    };
}

//是否已连接
-(BOOL (^)(void)) isConnected
{
    return ^(){
        return [self.clientSocket isConnected];
    };
}


#pragma mark -- GCDAsyncSocketDelegate
/**
 * This method is called immediately prior to socket:didAcceptNewSocket:.
 * It optionally allows a listening socket to specify the socketQueue for a new accepted socket.
 * If this method is not implemented, or returns NULL, the new accepted socket will create its own default queue.
 *
 * Since you cannot autorelease a dispatch_queue,
 * this method uses the "new" prefix in its name to specify that the returned queue has been retained.
 *
 * Thus you could do something like this in the implementation:
 * return dispatch_queue_create("MyQueue", NULL);
 *
 * If you are placing multiple sockets on the same queue,
 * then care should be taken to increment the retain count each time this method is invoked.
 *
 * For example, your implementation might look something like this:
 * dispatch_retain(myExistingQueue);
 * return myExistingQueue;
 **/
- (nullable dispatch_queue_t)newSocketQueueForConnectionFromAddress:(NSData *)address onSocket:(GCDAsyncSocket *)sock
{
    return self.currentQueue;
}

/**
 * Called when a socket accepts a connection.
 * Another socket is automatically spawned to handle it.
 *
 * You must retain the newSocket if you wish to handle the connection.
 * Otherwise the newSocket instance will be released and the spawned connection will be closed.
 *
 * By default the new socket will have the same delegate and delegateQueue.
 * You may, of course, change this at any time.
 **/
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    DVLog(@"didAcceptNewSocket");
SafeBlockCall(self.actionCallBack,DV_DidAcceptNewSocket,self,@{@"action":@"didAcceptNewSocket",@"newSocket":newSocket});
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    DVLog(@"didConnectToHost");
SafeBlockCall(self.actionCallBack,DV_ConnectSuccess,self,@{@"action":@"didConnectToHost",@"address":host,@"port":[NSNumber numberWithInt:port]});
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)socket:(GCDAsyncSocket *)sock didConnectToUrl:(NSURL *)url
{
    DVLog(@"didConnectToUrl");
    SafeBlockCall(self.actionCallBack,DV_ConnectSuccess,self,@{@"action":@"didConnectToUrl",@"url":url});
}


/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    DVLog(@"客户端收到-->%@",content);
    SafeBlockCall(self.readDataCallBack,DV_ReadDataSuccess,self,@{@"data":data},tag);
}

/**
 * Called when a socket has read in data, but has not yet completed the read.
 * This would occur if using readToData: or readToLength: methods.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    DVLog(@"didReadPartialDataOfLength");
    SafeBlockCall(self.readDataCallBack,DV_DidReadPartialDataOfLength,self,@{@"partialLength":[NSNumber numberWithUnsignedInteger:partialLength]},tag);
}

/**
 * Called when a socket has completed writing the requested data. Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    DVLog(@"didWriteDataWithTag");
    //是否需要在每次写数据后读取数据
    if (self.config.isAfterAnySendDataToReadData) {
        [self.clientSocket readDataWithTimeout:self.config.readDataTimeout tag:tag];
    }
    //数据写出成功回调
    SafeBlockCall(self.writeDataCallBack,DV_WriteDataSuccess | self.sendDataType, self,nil, tag);
    //如果是发送文件完成，重置文件总长度
    if (self.sendFileTotalLength) {
        self.sendFileTotalLength = 0;
    }
    if (self.sendFileCurrentLength) {
        self.sendFileCurrentLength = 0;
    }
}

/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 **/
- (void)socket:(GCDAsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
    DVLog(@"didWritePartialDataOfLength");
    self.sendFileCurrentLength += partialLength;
    SafeBlockCall(self.writeDataCallBack,DV_DidWritePartialDataOfLength | self.sendDataType,self,@{@"fileTotalLength":[NSNumber numberWithUnsignedInteger:self.sendFileTotalLength],@"fileCurrentLength":[NSNumber numberWithUnsignedInteger:self.sendFileCurrentLength]},tag);
}

/**
 * Called if a read operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the read's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the read will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been read so far for the read operation.
 *
 * Note that this method may be called multiple times for a single read if you return positive numbers.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    //超时未读取，则直接超时，不延长
    return -1;
}

/**
 * Called if a write operation has reached its timeout without completing.
 * This method allows you to optionally extend the timeout.
 * If you return a positive time interval (> 0) the write's timeout will be extended by the given amount.
 * If you don't implement this method, or return a non-positive time interval (<= 0) the write will timeout as usual.
 *
 * The elapsed parameter is the sum of the original timeout, plus any additions previously added via this method.
 * The length parameter is the number of bytes that have been written so far for the write operation.
 *
 * Note that this method may be called multiple times for a single write if you return positive numbers.
 **/
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    //超时未写出，则直接超时，不延长
    return -1;
}

/**
 * Conditionally called if the read stream closes, but the write stream may still be writeable.
 *
 * This delegate method is only called if autoDisconnectOnClosedReadStream has been set to NO.
 * See the discussion on the autoDisconnectOnClosedReadStream method for more information.
 **/
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock
{
    DVLog(@"socketDidCloseReadStream");
    SafeBlockCall(self.actionCallBack,DV_SocketDidCloseReadStream,self,@{@"action":@"socketDidCloseReadStream"});
}

/**
 * Called when a socket disconnects with or without error.
 *
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * then an invocation of this delegate method will be enqueued on the delegateQueue
 * before the disconnect method returns.
 *
 * Note: If the GCDAsyncSocket instance is deallocated while it is still connected,
 * and the delegate is not also deallocated, then this method will be invoked,
 * but the sock parameter will be nil. (It must necessarily be nil since it is no longer available.)
 * This is a generally rare, but is possible if one writes code like this:
 *
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * In this case it may preferrable to nil the delegate beforehand, like this:
 *
 * asyncSocket.delegate = nil; // Don't invoke my delegate method
 * asyncSocket = nil; // I'm implicitly disconnecting the socket
 *
 * Of course, this depends on how your state machine is configured.
 **/
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(nullable NSError *)err
{
    DVLog(@"socketDidDisconnect-->%@",err);
    if (err) {
        SafeBlockCall(self.errorCallBack,DV_ConnectError,[err localizedDescription]);
    }else{
        SafeBlockCall(self.actionCallBack,DV_Disconnect,self,@{@"action":@"socketDidDisconnect"});
    }
}

/**
 * Called after the socket has successfully completed SSL/TLS negotiation.
 * This method is not called unless you use the provided startTLS method.
 *
 * If a SSL/TLS negotiation fails (invalid certificate, etc) then the socket will immediately close,
 * and the socketDidDisconnect:withError: delegate method will be called with the specific SSL error code.
 **/
- (void)socketDidSecure:(GCDAsyncSocket *)sock
{
    DVLog(@"socketDidSecure");
    SafeBlockCall(self.actionCallBack,DV_DocketDidSecure,self,@{@"action":@"socketDidSecure"});
}

/**
 * Allows a socket delegate to hook into the TLS handshake and manually validate the peer it's connecting to.
 *
 * This is only called if startTLS is invoked with options that include:
 * - GCDAsyncSocketManuallyEvaluateTrust == YES
 *
 * Typically the delegate will use SecTrustEvaluate (and related functions) to properly validate the peer.
 *
 * Note from Apple's documentation:
 *   Because [SecTrustEvaluate] might look on the network for certificates in the certificate chain,
 *   [it] might block while attempting network access. You should never call it from your main thread;
 *   call it only from within a function running on a dispatch queue or on a separate thread.
 *
 * Thus this method uses a completionHandler block rather than a normal return value.
 * The completionHandler block is thread-safe, and may be invoked from a background queue/thread.
 * It is safe to invoke the completionHandler block even if the socket has been closed.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust
completionHandler:(void (^)(BOOL shouldTrustPeer))completionHandler
{
    DVLog(@"didReceiveTrust");
    if (self.actionCallBack) {
        // trust to NSData
        NSData *trustData = [NSData dataWithBytes:&trust length:sizeof(trust)];
        // NSData to trust
//        [trustData getBytes:&trust length:sizeof(trust)];
self.actionCallBack(DV_DidReceiveTrust,self,@{@"action":@"didReceiveTrust",@"trust":trustData,@"completionHandler":completionHandler});
    }
}

@end
