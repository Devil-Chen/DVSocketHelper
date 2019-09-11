//
//  NSObject+QuickImagePicker.h
//  DVSocketHelper
//
//  Created by apple on 2019/9/11.
//  Copyright © 2019 devil. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SelectImageBlock) (UIImage *image);

@interface NSObject (QuickImagePicker)<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
//选择图片的回调block
@property (nonatomic,copy) SelectImageBlock selectImageBlock;

//相册选择器对象
@property (nonatomic,strong) UIImagePickerController *imagePicker;

#pragma mark- 快速创建一个图片选择弹出窗(block中使用weakSelf)
- (void)quickPickerImage:(UIViewController *)vct allowsEditing:(BOOL)allowsEditing imageCallBack:(SelectImageBlock)selectImageBlock;

#pragma mark- 打开相机
- (void)openCamera:(UIViewController *)vct allowsEditing:(BOOL)allowsEditing;

#pragma mark- 打开相册
- (void)openPhoto:(UIViewController *)vct allowsEditing:(BOOL)allowsEditing;

@end

NS_ASSUME_NONNULL_END
