//
//  QuickImagePickerManager.m
//  DVSocketHelper
//
//  Created by apple on 2019/9/11.
//  Copyright © 2019 devil. All rights reserved.
//

#import "QuickImagePickerManager.h"


@interface QuickImagePickerManager ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
//选择图片的回调block
@property (nonatomic,copy) SelectImageBlock selectImageBlock;
//相册选择器对象
@property (nonatomic,strong) UIImagePickerController *imagePicker;
@end


@implementation QuickImagePickerManager
static QuickImagePickerManager *manager;
+(QuickImagePickerManager *(^)(void)) instance
{
    return ^(){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (!manager) {
                manager = [[QuickImagePickerManager alloc] init];
                manager.imagePicker = [[UIImagePickerController alloc] init];
                manager.imagePicker.delegate = manager;
            }
        });
        return manager;
    };
}

/**
 * 快速创建一个图片选择弹出窗(block中使用weakSelf)
 */
-(QuickImagePickerManager *(^)(UIViewController *vct,BOOL allowsEditing,SelectImageBlock selectImageBlock))quickPickerImage
{
    return ^(UIViewController *vct,BOOL allowsEditing,SelectImageBlock selectImageBlock){
        if (!vct) {
            return self;
        }
        [self setSelectImageBlock:selectImageBlock];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"图片选择" message:@"选择获取图片的方式" preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.openPhoto(vct,allowsEditing);
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.openCamera(vct,allowsEditing);
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alert addAction:action];
        [alert addAction:action2];
        [alert addAction:cancel];
        [vct presentViewController:alert animated:YES completion:nil];
        return self;
    };
}

/**
 * 打开相机
 */
-(QuickImagePickerManager *(^)(UIViewController *vct,BOOL allowsEditing))openCamera
{
    return ^(UIViewController *vct,BOOL allowsEditing){
        if (!vct || ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            return self;
        }
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePicker.allowsEditing = allowsEditing;
        [vct presentViewController: self.imagePicker animated:YES completion:^{
            NSLog(@"相机");
        }];
        return self;
    };
}

/**
 * 打开相册选择
 */
-(QuickImagePickerManager *(^)(UIViewController *vct,BOOL allowsEditing))openPhoto
{
    return ^(UIViewController *vct,BOOL allowsEditing){
        if (!vct || ![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            return self;
        }
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePicker.allowsEditing = allowsEditing;
        [vct presentViewController: self.imagePicker animated:YES completion:^{
            NSLog(@"相册");
        }];
        return self;
    };
}

#pragma mark- <UIImagePickerControllerDelegate>
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *orginImage;
    if (picker.allowsEditing) {
        orginImage = info[UIImagePickerControllerEditedImage];
    }else{
        orginImage = info[UIImagePickerControllerOriginalImage];
    }
    
    UIImage *fixImage = [self fixOrientation: orginImage];
    
    /// 选择的图片
    if(self.selectImageBlock){
        self.selectImageBlock(fixImage);
    }
    ///拍到的照片顺带保存到相册
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(fixImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

/// 系统指定的回调方法
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    NSString *msg = nil ;
    if(error != NULL){
        msg = @"保存图片失败" ;
    }else{
        msg = @"保存图片成功" ;
    }
    NSLog(@"%@",msg);
}


///矫正图片方向
- (UIImage*)fixOrientation:(UIImage*)aImage
{
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, aImage.size.height, aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, aImage.size.width, aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage* img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

@end
