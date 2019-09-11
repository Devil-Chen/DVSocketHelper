//
//  QuickImagePickerManager.h
//  DVSocketHelper
//
//  Created by apple on 2019/9/11.
//  Copyright © 2019 devil. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SelectImageBlock) (UIImage *image);

@interface QuickImagePickerManager : NSObject

//单例
+(QuickImagePickerManager *(^)(void))instance;

/**
 * 快速创建一个图片选择弹出窗
 */
-(QuickImagePickerManager *(^)(UIViewController *vct,BOOL allowsEditing,SelectImageBlock selectImageBlock))quickPickerImage;

/**
 * 打开相机拍照
 */
-(QuickImagePickerManager *(^)(UIViewController *vct,BOOL allowsEditing))openCamera;

/**
 * 打开相册选择
 */
-(QuickImagePickerManager *(^)(UIViewController *vct,BOOL allowsEditing))openPhoto;

@end

NS_ASSUME_NONNULL_END
