//
//  DVSocketConfig.h
//  DVSocketHelper
//
//  Created by devil on 2019/7/4.
//  Copyright © 2019 devil. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//事件码
typedef NS_ENUM(NSUInteger, DVActionCode) {
    //DVErrorCallBack中回调
    DV_OtherError  = 0,//其它错误
    DV_ConnectTimeoutError = 1 << 0,//连接超时
    DV_ConnectError = 1 << 1,//连接错误或者断开有错误
    DV_InputError = 1 << 2,//输入数据错误
    DV_WriteDataError = 1 << 3,//写数据时发生错误
    
    //DVActionCallBack中回调
    DV_Disconnect = 1 << 4,//正常手动断开连接
    DV_ConnectSuccess = 1 << 5,//连接成功
    DV_StartConnect = 1 << 6,//开始连接
    DV_DidReceiveTrust = 1 << 7,
    DV_DocketDidSecure = 1 << 8,
    DV_SocketDidCloseReadStream = 1 << 9,
    DV_DidAcceptNewSocket = 1 << 10,
    
    //DVWriteDataCallBack中回调
    DV_WriteFileData = 1 << 11,//写文件数据
    DV_WriteFileDataSuccess = 1 << 12,//写文件数据成功
    DV_WriteOtherData = 1 << 13,//写其它数据（字符串）
    DV_WriteOtherDataSuccess = 1 << 14,//写数据成功
    
    //DVReadDataCallBack中回调
    DV_ReadData = 1 << 15,//读取数据
    DV_ReadDataSuccess = 1 << 16//读取数据成功
    
};

@interface DVSocketConfig : NSObject
//连接超时时间(默认不限时-1)
@property (nonatomic,assign) NSTimeInterval connectTimeout;
//读取数据超时时间(默认不限时-1)
@property (nonatomic,assign) NSTimeInterval readDataTimeout;
//写数据超时时间(默认不限时-1)
@property (nonatomic,assign) NSTimeInterval writeDataTimeout;
//是否每次发送完数据之后都读取数据(默认NO)
@property (nonatomic,assign) BOOL isAfterAnySendDataToReadData;

//发送字符串数据的格式（每次发送都按照这个格式,只能包含一个%@，例如 @"||%@||"，赋值时自动设置isOpenSendDataFormat为YES）
@property (nonatomic,copy) NSString *sendStringDataFormat;
//是否开启发送数据使用特定格式（默认不开启）
@property (nonatomic,assign) BOOL isOpenSendStringDataFormat;

+(instancetype) defaultConfig;

@end

NS_ASSUME_NONNULL_END
