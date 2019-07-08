#import "EasyImagePickerManager.h"

@interface EasyImagePickerManager ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIActionSheetDelegate>

///来源控制器
@property (nonatomic,strong) UIViewController *orginViewController;
/// 取出的图片
@property (nonatomic,strong) UIImage *tempImage;

@end

@implementation EasyImagePickerManager

- (UIImagePickerController *)imagePicker{
    if (!_imagePicker) {
        _imagePicker = [[UIImagePickerController alloc] init];
        _imagePicker.delegate = self;
        // 媒体类型
        _imagePicker.mediaTypes = @[(NSString *)kUTTypeImage];
    }
    return _imagePicker;
}


- (instancetype)initWithViewController:(UIViewController *)VC{
    self = [super init];
    if (self) {
        self.orginViewController = VC;
    }
    return self;
}

#pragma mark- 快速创建一个图片选择弹出窗
- (void)quickAlertSheetPickerImage{
    UIActionSheet *sheetView = [[UIActionSheet alloc] initWithTitle:@"选择图片" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"相册",@"拍照", nil];
    [sheetView showInView:self.orginViewController.view];
}

#pragma mark-<UIActionSheetDelegate>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        ///相册
        [self openPhoto];
    }else if (buttonIndex == 1){
        /// 拍照
        [self openCamera];
    }
}


#pragma mark- 打开相机
- (void)openCamera{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return ;
    }
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self.orginViewController presentViewController: self.imagePicker animated:YES completion:^{
        NSLog(@"相机");
    }];
}

#pragma mark- 打开相册
- (void)openPhoto{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        return ;
    }
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self.orginViewController presentViewController: self.imagePicker animated:YES completion:^{
        NSLog(@"相册");
    }];
}


#pragma mark- <UIImagePickerControllerDelegate>
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    UIImage *orginImage = info[UIImagePickerControllerOriginalImage];
    self.tempImage = [self fixOrientation: orginImage];
    
    /// 选择的图片
    if(self.didSelectImageBlock){
        self.didSelectImageBlock(info[UIImagePickerControllerImageURL]);
    }
    ///拍到的照片顺带保存到相册
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        [self saveImageToSystemPhotosAlbum];
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark- 拍的照片保存到系统相册
- (void)saveImageToSystemPhotosAlbum{
    UIImageWriteToSavedPhotosAlbum(self.tempImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
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
