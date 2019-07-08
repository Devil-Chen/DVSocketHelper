//
//  DVSocketConfig.m
//  DVSocketHelper
//
//  Created by devil on 2019/7/4.
//  Copyright © 2019 devil. All rights reserved.
//

#import "DVSocketConfig.h"

@implementation DVSocketConfig
+(instancetype) defaultConfig
{
    DVSocketConfig *config = [[DVSocketConfig alloc] init];
    [config initSetting];
    return config;
}

-(void) initSetting
{
    self.connectTimeout = -1;
    self.readDataTimeout = -1;
    self.writeDataTimeout = -1;
    self.isAfterAnySendDataToReadData = NO;
    self.sendDataFormat = @"%@";
    self.isOpenSendStringDataFormat = NO;
}

-(void) setSendDataFormat:(NSString *)sendDataFormat
{
    _sendStringDataFormat = sendDataFormat;
    if (sendDataFormat && ![sendDataFormat isEqualToString:@""]) {
        self.isOpenSendStringDataFormat = YES;
    }
}

@end
