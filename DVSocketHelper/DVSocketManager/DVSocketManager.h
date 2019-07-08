//
//  DVSocketManager.h
//  DVSocketHelper
//
//  Created by devil on 2019/6/24.
//  Copyright © 2019 devil. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVSocketConfig.h"

NS_ASSUME_NONNULL_BEGIN

//错误回调
typedef void(^DVErrorCallBack)(DVActionCode code,NSString *msg);
//非错误、读取数据、写数据之外的所有回调
typedef void(^DVActionCallBack)(DVActionCode code,id socketManager,_Nullable id result);
//读取数据回调
typedef void(^DVReadDataCallBack)(DVActionCode code,id socketManager,_Nullable id result,long tag);
//写数据回调
typedef void(^DVWriteDataCallBack)(DVActionCode code,id socketManager,_Nullable id result,long tag);

@interface DVSocketManager : NSObject

+(DVSocketManager *(^)(void)) instance;

//当前ClientSocket
-(id (^)(void)) currentClientSocket;

//设置连接地址和端口
-(DVSocketManager *(^)(NSString *address)) setAddress;
-(DVSocketManager *(^)(uint16_t port)) setPort;

//设置配置
-(DVSocketManager *(^)(DVSocketConfig *config)) setSocketConfig;
//编辑已有的配置
-(DVSocketManager *(^)(void(^editConfig)(DVSocketConfig *config))) editSocketConfig;

//设置错误回调
-(DVSocketManager *(^)(DVErrorCallBack errorCallBack)) setErrorCallBack;
//设置非错误回调
-(DVSocketManager *(^)(DVActionCallBack actionCallBack)) setActionCallBack;
//设置读取数据回调
-(DVSocketManager *(^)(DVReadDataCallBack readDataCallBack)) setReadDataCallBack;
//设置写数据回调
-(DVSocketManager *(^)(DVWriteDataCallBack writeDataCallBack)) setWriteDataCallBack;

//连接主机
-(DVSocketManager *(^)(void)) connect;

//读取数据(一次)
-(DVSocketManager *(^)(long tag)) readData;
//设置每一次成功发送完数据之后都读取数据
-(DVSocketManager *(^)(BOOL mark)) setReadDataWithAnySendData;

//写数据（content为NSData时默认为二进制流）
-(DVSocketManager *(^)(id content,long tag)) writeData;

//关闭连接
-(DVSocketManager *(^)(void)) closeConnection;

//是否已连接
-(BOOL (^)(void)) isConnected;

@end

NS_ASSUME_NONNULL_END
