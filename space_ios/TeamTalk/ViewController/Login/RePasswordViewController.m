//
//  RePasswordViewController.m
//  TeamTalk
//
//  Created by mac on 16/12/17.
//  Copyright © 2016年 MoguIM. All rights reserved.
//

#import "RePasswordViewController.h"
#import "AFNetworking.h"
#import "Utility.h"
#import "MyMD5.h"
#import "MBProgressHUD.h"
#import "NSDictionary+JSON.h"
@interface RePasswordViewController ()<UITextFieldDelegate, MBProgressHUDDelegate>
@property (nonatomic, strong) UITextField *passwordTF;

@property (nonatomic, strong) UITextField *confirmPasswordTF;

@property (nonatomic, strong) UITextField *phoneTF;

@property (nonatomic, strong) UITextField *codeTF;
@property (nonatomic, strong) UIButton *registerButton;
@end

@implementation RePasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"找回密码";
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupMainUI];
    // Do any additional setup after loading the view.
}
- (void)setupMainUI
{
    //昵称
    //    self.nickNameTF = [self createUserInputTextFieldWithFrame:CGRectMake(30, 180, SCREEN_WIDTH - 30*2, 44)
    //                                                  placeholder:@"输入昵称"
    //                                              secureTextEntry:NO
    //                                                 keyboardType:UIKeyboardTypeDefault];
    //
    //
    //    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(_nickNameTF.frame), CGRectGetMaxY(_nickNameTF.frame), _nickNameTF.bounds.size.width, 1)];
    //    line.backgroundColor = [UIColor groupTableViewBackgroundColor];
    //    [self.view addSubview:line];
    
    
    // 手机号
    //    self.phoneTF = [self createUserInputTextFieldWithFrame:CGRectMake(30, 180, SCREEN_WIDTH - 30*2, 44)
    //                                              placeholder:@"输入手机号码"
    //                                          secureTextEntry:NO
    //                                             keyboardType:UIKeyboardTypeNumberPad];
    
    
    //    UIView *line2 = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.phoneTF.frame), CGRectGetMaxY(_phoneTF.frame) + 1, 1, _phoneTF.frame.size.height - 2)];
    //    line2.backgroundColor = [UIColor groupTableViewBackgroundColor];
    //    [self.view addSubview:line2];
    
    //    UIView *line1 = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(_phoneTF.frame), CGRectGetMaxY(_phoneTF.frame), _phoneTF.bounds.size.width, 1)];
    //    line1.backgroundColor = [UIColor groupTableViewBackgroundColor];
    //    [self.view addSubview:line1];
    
    
    
    // 验证码
    self.codeTF = [self createUserInputTextFieldWithFrame:CGRectMake(30, 180, SCREEN_WIDTH - 30 *2, 44)
                                              placeholder:@"请输入验证码"
                                          secureTextEntry:NO
                                             keyboardType:UIKeyboardTypeNumberPad];
    UIView *line3 = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(_codeTF.frame), CGRectGetMaxY(_codeTF.frame), _codeTF.bounds.size.width, 1)];
    line3.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.view addSubview:line3];
    
    // 获取验证码
    //[self setupVerificationButton];
    
    // 密码
    self.passwordTF = [self createUserInputTextFieldWithFrame:CGRectMake(30, CGRectGetMaxY(self.codeTF.frame), SCREEN_WIDTH - 60, 45)
                                                  placeholder:@"请输入密码"
                                              secureTextEntry:YES
                                                 keyboardType:UIKeyboardTypeNamePhonePad];
    
    UIView *line4 = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(_passwordTF.frame), CGRectGetMaxY(_passwordTF.frame), _passwordTF.bounds.size.width, 1)];
    line4.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.view addSubview:line4];
    // 确认密码
    self.confirmPasswordTF = [self createUserInputTextFieldWithFrame:CGRectMake(30, CGRectGetMaxY(self.passwordTF.frame), SCREEN_WIDTH - 60, 45)
                                                         placeholder:@"请确认密码"
                                                     secureTextEntry:YES
                                                        keyboardType:UIKeyboardTypeNamePhonePad];
    
    UIView *line5 = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMinX(_confirmPasswordTF.frame), CGRectGetMaxY(_confirmPasswordTF.frame), _confirmPasswordTF.bounds.size.width, 1)];
    line5.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [self.view addSubview:line5];
    
    
       
    [self setupRegisterButton];
}

- (void)setupRegisterButton
{
    self.registerButton = [[UIButton alloc] initWithFrame:CGRectMake(30, 430, SCREEN_WIDTH - 60, 50)];
    _registerButton.backgroundColor = RGBA(28, 216, 27, 1);
    
    [_registerButton setTitle:@"确定" forState:UIControlStateNormal];
    _registerButton.layer.cornerRadius = 4;
    [_registerButton addTarget:self action:@selector(didClickRegisterButtons:)
              forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_registerButton];
}

- (void)didClickRegisterButtons:(UIButton *)sender
{
    [self resignFirstResponderForAllTextField];
    //    if (_nickNameTF.text.length == 0) {
    //        [self showErrorInfoWithMessage:@"用户名不能为空" hideAfterDelay:1.0f];
    //        return;
    //    }
    //    if (_nickNameTF.text.length > 16 || _nickNameTF.text.length <= 2) {
    //        [self showErrorInfoWithMessage:@"用户名长度应在4-16位之间" hideAfterDelay:1.0f];
    //        return;
    //    }
    if (_passwordTF.text.length < 6 || _passwordTF.text.length > 20) {
        [self showErrorInfoWithMessage:@"密码长度必须6~20位" hideAfterDelay:1.0f];
        return;
    }
    if (![_confirmPasswordTF.text isEqualToString:_passwordTF.text]) {
        [self showErrorInfoWithMessage:@"两次密码不一致" hideAfterDelay:1.0f];
        return;
    }
    [self rePasswordRequest];
}

-(void)rePasswordRequest
{

    // 正在注册提示
    MBProgressHUD *HUD = [self showNoticeWithMessage:@"正在注册..." modeOfHUD:MBProgressHUDModeIndeterminate];
    


    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:self.phoneString forKey:@"phone"];
    [dic setIntValue:[_codeTF.text intValue] forKey:@"valid_code"];
    [dic setObject:[MyMD5 md5:_passwordTF.text] forKey:@"passwd"];
    
    
    //[dic setObject:_nickNameTF.text forKey:@"nick"];
    
    
    NSString *landu_arg = [dic jsonString];
    NSDictionary *postDic = @{@"arg":landu_arg};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    [manager POST:RE_PASSWORD parameters:postDic success:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         [HUD hide:NO];
         if (!responseObject) {
             DDLog(@"服务器返回数据为空!!!");
             return;
         }
         NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
         DDLog(@"----responseDic == %@",responseDictionary);
         
         NSString *error_code = [NSString stringWithFormat:@"%@",[responseDictionary objectForKey:@"error_code"]];
         NSString *error_message = [NSString stringWithFormat:@"%@",[responseDictionary objectForKey:@"error_message"]];
         
         if([error_code isEqualToString:@"0"]) {
             
             [self showErrorInfoWithMessage:@"重置密码成功" hideAfterDelay:1.0f];
             [self performSelector:@selector(delayMethod) withObject:nil afterDelay:1.0f];
             
         }
         
         else if([error_code isEqualToString:@"3"])
         {
             
             [self showErrorInfoWithMessage:error_message hideAfterDelay:1.5f];
             
             
         }

                 else {
             [self showErrorInfoWithMessage:error_message hideAfterDelay:1.5f];
             [self performSelector:@selector(delayMethod) withObject:nil afterDelay:1.0f];
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
         [HUD removeFromSuperview];
         [self showErrorInfoWithMessage:[NSString stringWithFormat:@"%@",error] hideAfterDelay:1.5f];
     } ];







}


-(void)delayMethod
{
    
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (UITextField *)createUserInputTextFieldWithFrame:(CGRect)frame placeholder:(NSString *)placeholder secureTextEntry:(BOOL)needSecure keyboardType:(UIKeyboardType)keyboardType
{
    UITextField *textField = [[UITextField alloc] initWithFrame:frame];
    //UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 18, 22.5)];
    textField.placeholder = placeholder;
    //textField.leftView = leftView;
    textField.secureTextEntry = needSecure;
    textField.keyboardType = keyboardType;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    //textField.leftViewMode = UITextFieldViewModeAlways;
    textField.font = [UIFont systemFontOfSize:15];
    textField.delegate = self;
    
    //    [textField.layer setBorderColor:RGB(211, 211, 211).CGColor];
    //    [textField.layer setBorderWidth:0.5];
    //    [textField.layer setCornerRadius:4];
    
    [self.view addSubview:textField];
    
    return textField;
}

- (void)resignFirstResponderForAllTextField {
    [_phoneTF resignFirstResponder];
    [_passwordTF resignFirstResponder];
    [_confirmPasswordTF resignFirstResponder];
    [_phoneTF resignFirstResponder];
    [_codeTF resignFirstResponder];
}
- (MBProgressHUD *)showNoticeWithMessage:(NSString *)message modeOfHUD:(MBProgressHUDMode)mode
{
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    [HUD show:YES];
    HUD.mode = mode;
    HUD.dimBackground = YES;
    HUD.labelText = message;
    
    return HUD;
}

- (void)showErrorInfoWithMessage:(NSString *)errorMessage hideAfterDelay:(NSTimeInterval)delay {
    MBProgressHUD *tips = [self showNoticeWithMessage:errorMessage modeOfHUD:MBProgressHUDModeText];
    [tips hide:YES afterDelay:delay];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
