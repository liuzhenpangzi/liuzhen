//
//  HomeViewCell.m
//  TeamTalk
//
//  Created by 1 on 16/11/4.
//  Copyright © 2016年 IM. All rights reserved.
//

#import "HomeViewCell.h"
#import "UIImageView+SDWebImage.h"
#import "MTTUserEntity.h"
/** OSS数据*/
#import <AliyunOSSiOS/OSSService.h>
#import "DDSendPhotoMessageAPI.h"

@interface HomeViewCell()

@property (nonatomic, weak) UIImageView *showImageView;
@property (nonatomic, weak) UIView *infoView;
@property (nonatomic, weak) UILabel *nickLabel;
@property (nonatomic, strong) NSString *urlHeader;

@end

@implementation HomeViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        MTTUserEntity *userEntity = (MTTUserEntity *)TheRuntime.user;
        NSString *urlString = [NSString stringWithFormat:@"http://%@.oss-cn-shenzhen.aliyuncs.com/im/avatar/%@.png", kBucketNameInAliYunOSS, userEntity.userID];
        self.userEntity = userEntity;
        self.urlHeader = urlString;
        
        
        UIImageView *imageView = [[UIImageView alloc] init];
        self.showImageView = imageView;
        [self.contentView addSubview:imageView];
        
        
        // 用户信息 height = 35
        UIView *infoView = [[UIView alloc] init];
        self.infoView = infoView;
        [imageView addSubview:infoView];
        
        
        // 昵称
        UILabel *nickLabel = [[UILabel alloc] init];
        self.nickLabel = nickLabel;
        [imageView addSubview:nickLabel];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.showImageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    self.infoView.frame = CGRectMake(0, self.frame.size.height - 20, self.frame.size.width, 20);
    self.infoView.backgroundColor = [UIColor colorWithRed:14.0/255.0 green:207.0/255.0 blue:49.0/255.0 alpha:1.0];
    self.infoView.alpha = 0.3;
    
    self.nickLabel.frame = CGRectMake(0, self.infoView.frame.origin.y + 2.5, self.frame.size.width, 15);
    self.nickLabel.font  = [UIFont systemFontOfSize:15.0];
    self.nickLabel.textAlignment = NSTextAlignmentCenter;
    self.nickLabel.textColor = [UIColor whiteColor];
}

- (void)setUserEntity:(MTTUserEntity *)userEntity
{
    self.showImageView.image  = nil;
    
    // 用户id
    NSString *userID = [NSString stringWithFormat:@"%@", userEntity.userID];
    // 获取自己的id
    MTTUserEntity *mySelf = (MTTUserEntity *)TheRuntime.user;
    NSString *myID = [NSString stringWithFormat:@"%@", mySelf.userID];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 展示数据
        if (![myID isEqualToString:userID]) {
            // OSS加密
            NSString  *constrainURL = nil;
            NSString  *objectKey = [NSString stringWithFormat:@"im/live/%@.png", userID];
            OSSClient *client = [[DDSendPhotoMessageAPI sharedPhotoCache] ossInit];
            OSSTask   *task = [client presignConstrainURLWithBucketName:kHomeBucketNameInAliYunOSS
                                                          withObjectKey:objectKey
                                                 withExpirationInterval: 30 * 60];
            if (!task.error) {
                constrainURL = task.result;
            } else {
                NSLog(@"error: %@", task.error);
            }
            
            // 图片数据
            [self.showImageView sd_setImageWithURL:[NSURL URLWithString:constrainURL] placeholderImage:self.showImageView.image options:SDWebImageRetryFailed];
        }
    });
    
    // 昵称
    if (userEntity.nick.length) {
        self.nickLabel.text = userEntity.nick;
    }else if (userEntity.name.length){
        self.nickLabel.text = userEntity.name;
    }else {
        self.nickLabel.text = @"我是机器人";
    }
}

- (void)setValueForImageViewWithURL:(NSString *)urlString andNickName:(NSString *)userName andUserID:(NSString *)userID
{
    UIImage *placeholderImage = nil;
    NSString *url = nil;
    if (![userID isEqualToString:self.userEntity.userID]) {
        url = [NSString stringWithFormat:@"http://%@.oss-cn-shenzhen.aliyuncs.com/im/avatar/%@.png?x-oss-process=image/resize,m_mfit,h_200,w_200", kBucketNameInAliYunOSS, userID];
        placeholderImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]]];
        if (!placeholderImage) {
            placeholderImage = [UIImage imageNamed:@"toux"];
        }
    }
    
    // 图片数据
    [self.showImageView sd_setImageWithURL:[NSURL URLWithString:urlString] placeholderImage:placeholderImage options:SDWebImageRetryFailed];
    
    // 昵称
    if (userName.length) {
        self.nickLabel.text = userName;
    }else {
        self.nickLabel.text = @"我是机器人";
    }
}

@end
