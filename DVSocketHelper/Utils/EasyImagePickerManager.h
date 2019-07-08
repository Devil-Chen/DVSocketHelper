#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>


@interface EasyImagePickerManager : NSObject

/// 创建这样一个管理类对象
- (instancetype)initWithViewController:(UIViewController *)VC;

///选择图片的回调block
@property (nonatomic,copy) void(^didSelectImageBlock) (NSURL *image);

/// 相册选择器对象
@property (nonatomic,strong) UIImagePickerController *imagePicker;

#pragma mark- 快速创建一个图片选择弹出窗
- (void)quickAlertSheetPickerImage ;

#pragma mark- 打开相机
- (void)openCamera;

#pragma mark- 打开相册
- (void)openPhoto ;

@end
