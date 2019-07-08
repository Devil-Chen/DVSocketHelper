//
//  DVDataProgressInfo.h
//  DVSocketHelper
//
//  Created by apple on 2019/7/5.
//  Copyright © 2019 devil. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVDataProgressInfo : NSObject
@property (nonatomic,copy) NSString *action;
@property (nonatomic,assign) NSUInteger fileTotalLength;
@property (nonatomic,assign) NSUInteger fileCurrentLength;
@end

NS_ASSUME_NONNULL_END
