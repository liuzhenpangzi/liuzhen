//
//  HomeViewCell.h
//  TeamTalk
//
//  Created by 1 on 16/11/4.
//  Copyright © 2016年 IM. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTTUserEntity;
@interface HomeViewCell : UICollectionViewCell

@property (nonatomic, strong) MTTUserEntity *userEntity;

/** 
 * 设置值
 */
- (void)setValueForImageViewWithURL:(NSString *)urlString andNickName:(NSString *)userName andUserID:(NSString *)userID;

@end
