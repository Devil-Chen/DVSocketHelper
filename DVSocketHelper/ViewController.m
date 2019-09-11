//
//  ViewController.m
//  SocketFunc
//
//  Created by apple on 2019/6/24.
//  Copyright © 2019 devil. All rights reserved.
//

#import "ViewController.h"
#import "DVSocketManager.h"
#import "DVSocketConfig.h"
#import "QuickImagePickerManager.h"
#import "YYModel.h"
#import "NSObject+QuickImagePicker.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *txt_content;
@property (weak, nonatomic) IBOutlet UIButton *btn_sure;
@property (weak, nonatomic) IBOutlet UITextView *txt_readContent;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self startConnect];
}

-(void) startConnect
{
    DVSocketManager.instance()
    .setAddress(@"127.0.0.1")
    .setPort(9999)
    .setReadDataWithAnySendData(YES)
    .editSocketConfig(^(DVSocketConfig *config){
        config.sendStringDataFormat = @"||%@||";
    })
    .setErrorCallBack(^(DVActionCode code,NSString *msg){
        NSLog(@"错误-->code:%ld\tmsg:%@",(long)code,msg);
        [self showMessage:msg];
    })
    .setActionCallBack(^(DVActionCode code,id socketManager,_Nullable id result){
        NSLog(@"action-->%@",result);        
        if (code & DV_Disconnect) {
            [self showMessage:@"断开连接成功"];
        }else if (code & DV_ConnectSuccess){
            [self showMessage:@"连接成功"];
        }
    })
    .setReadDataCallBack(^(DVActionCode code,id socketManager,NSUInteger partialLength,_Nullable id result,long tag){
        if (code & DV_ReadDataSuccess) {
            NSString *read = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
            NSLog(@"read-->%@",read);
            self.txt_readContent.text = [NSString stringWithFormat:@"%@\n服务器：%@",self.txt_readContent.text,read];
        }
    })
    .setWriteDataCallBack(^(DVActionCode code,id socketManager,NSUInteger partialLength,NSUInteger totalLength,long tag){
        
        if (code & DV_WriteFileData) {
            NSLog(@"文件发送进度-->%.2f",partialLength*1.0/totalLength);
        }else if(code & DV_WriteFileDataSuccess){
            NSLog(@"文件发送成功");
        }else  if(code & DV_WriteOtherDataSuccess){
            NSLog(@"write-->code:%ld\tresult:%lu",(long)code,(unsigned long)totalLength);
            NSString *text = self.txt_content.text;
            self.txt_readContent.text = [NSString stringWithFormat:@"%@\n我：%@",self.txt_readContent.text,text];
            self.txt_content.text = @"";
        }
    }).connect();
}

//显示提示信息
-(void) showMessage:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (IBAction)click:(id)sender {
    NSString *text = self.txt_content.text;
    [self.txt_content resignFirstResponder];
    DVSocketManager.instance().writeData(text,123);
    
}
- (IBAction)sendImageData:(id)sender {
    QuickImagePickerManager.instance().quickPickerImage(self,NO,^(UIImage * _Nonnull image){
        NSData *data = UIImageJPEGRepresentation(image,1);
        DVSocketManager.instance().writeData(data,123);
    });
//    [self quickPickerImage:self allowsEditing:NO imageCallBack:^(UIImage * _Nonnull image) {
//        NSData *data = UIImageJPEGRepresentation(image,1);
//        DVSocketManager.instance().writeData(data,123);
//    }];
    
}

- (IBAction)closeConnect:(id)sender {
    DVSocketManager.instance().closeConnection();
}
- (IBAction)reConnect:(id)sender {
    DVSocketManager.instance().connect();
}

@end
