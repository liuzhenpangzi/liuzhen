//
//  HomeConcernViewController.m
//  TeamTalk
//
//  Created by 1 on 16/11/15.
//  Copyright © 2016年 IM. All rights reserved.
//

#import "HomeConcernViewController.h"
#import "PublicProfileViewControll.h"
#import "ConcernFirstItemView.h"
#import "HomeViewCell.h"
#import "MJRefresh.h"
#import "MTTAFNetworkingClient.h"
#import "MTTPhotosCache.h"
#import "MTTUserEntity.h"
#import "DDUserModule.h"
#import "UIImage+Orientation.h"
/** API*/
#import "DDSendPhotoMessageAPI.h"
/** OSS数据*/
#import <AliyunOSSiOS/OSSService.h>
#import "GetUserInfoAPI.h"

#define HomeScreenWidth [UIScreen mainScreen].bounds.size.width
#define HomeScreenHeight [UIScreen mainScreen].bounds.size.height

static CGFloat const margin = 3; // item 的间距
static int const cols = 2;
static NSString *const concernReuseIdentifier = @"concernCell";
#define itemWidth (self.view.frame.size.width - ((cols - 1) * margin)) / cols

@interface HomeConcernViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, ConcernFirstItemViewDelegate>

@property (nonatomic, weak)   UICollectionView *collectionView;
/** 保存名字的数组*/
@property (nonatomic, strong) NSMutableArray *dataArray;
/** 保存URL的数组*/
@property (nonatomic, strong) NSMutableArray *urlArray;
/** 用户id*/
@property (nonatomic, strong) NSMutableArray *idArray;
@property (nonatomic, weak)   ConcernFirstItemView *firstItemView;
@property (nonatomic, weak)   NSTimer *timer;
@property (nonatomic, assign) BOOL cameraIsOpen;
/** 定时刷新*/
@property (nonatomic, weak)   NSTimer *refreshTimer;

@end

@implementation HomeConcernViewController

#pragma mark - lazy

- (NSMutableArray *)idArray
{
    if (_idArray == nil) {
        _idArray = [NSMutableArray array];
    }
    return _idArray;
}

- (NSMutableArray *)urlArray
{
    if (_urlArray == nil) {
        _urlArray = [NSMutableArray array];
    }
    return _urlArray;
}

- (NSMutableArray *)dataArray
{
    if (_dataArray == nil) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

#pragma mark - view

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.cameraIsOpen = NO;
    
    // 创建collectionView
    [self setupHomeCollectionView];
    
    // 注册监听
    [self listenForViewScroll];
}

#pragma mark - 监听事件

// 监听主界面view的滚动
- (void)listenForViewScroll
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainViewIsOtherView:) name:@"RecommendView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainViewIsOtherView:) name:@"FriendView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainViewIsOtherView:) name:@"HomeViewWillDisappear" object:nil];
    /** 滚动到当前页*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainViewIsConcernView:) name:@"ConcernView" object:nil];
}

// 实现监听的方法
- (void)mainViewIsOtherView:(NSNotification *)note
{
    if (self.refreshTimer) {
        [self stopRefreshTimer];
    }
}

// 显示的位置是当前控制器的view
- (void)mainViewIsConcernView:(NSNotification *)note
{
    if (self.refreshTimer == nil) {
        [self startRefreshTimer];
    }
}

#pragma mark - 创建view

- (void)setupHomeCollectionView
{
    // 布局
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = margin;
    layout.minimumInteritemSpacing = margin;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth * 1.3);
    
    
    // collectionView
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, HomeScreenWidth, HomeScreenHeight - 64 - 49 - margin - 21) collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor whiteColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [collectionView registerClass:[HomeViewCell class] forCellWithReuseIdentifier:concernReuseIdentifier];
    
    
    // 显示自己摄像头数据
    ConcernFirstItemView *firstItemView = [[ConcernFirstItemView alloc] initWithFrame:CGRectMake(0, 0, itemWidth, itemWidth * 1.3)];
    firstItemView.backgroundColor = [UIColor lightGrayColor];
    firstItemView.delegate = self;
    self.firstItemView = firstItemView;
    [collectionView addSubview:firstItemView];
    
    
    self.collectionView = collectionView;
    [self.view addSubview:collectionView];
}

#pragma mark - 定时刷新

- (void)startRefreshTimer
{
    [self loadNewHomeData];
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:11.0 target:self selector:@selector(loadNewHomeData) userInfo:nil repeats:YES];
    // 添加到主运行循环中
    [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
}

- (void)stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

#pragma mark - 获取数据库好友列表

- (void)getAllContactsFromFMDB
{
    MTTUserEntity *userEntity = (MTTUserEntity *)TheRuntime.user;
    [self.dataArray addObject:userEntity.nick];
    [self.urlArray  addObject:userEntity.userID];
    [self.idArray   addObject:userEntity.userID];
    
    // 获取关注好友
    NSArray *concernUserArray = [[DDUserModule shareInstance] getAllAttention];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (MTTUserEntity *userEntity in concernUserArray) {
            NSString *userID = [NSString stringWithFormat:@"%@", userEntity.userID];
            // 检查是否有图片
            NSString *objectKey = [NSString stringWithFormat:@"im/live/%@.png", userID];
            OSSClient *client   = [[DDSendPhotoMessageAPI sharedPhotoCache] ossInit];
            NSError *error      = nil;
            BOOL isExist = [client doesObjectExistInBucket:kHomeBucketNameInAliYunOSS objectKey:objectKey error:&error];
            if (!error) {
                if(isExist) {
                    // 文件存在
                    [self.dataArray addObject:userEntity.nick];
                    [self.idArray addObject:userID];
                    
                    NSString  *constrainURL = nil;
                    NSString  *objectKey = [NSString stringWithFormat:@"im/live/%@.png", userID];
                    OSSClient *client = [[DDSendPhotoMessageAPI sharedPhotoCache] ossInit];
                    OSSTask   *task = [client presignConstrainURLWithBucketName:kHomeBucketNameInAliYunOSS
                                                                  withObjectKey:objectKey
                                                         withExpirationInterval: 30 * 60];
                    if (!task.error) {
                        constrainURL = task.result;
                        // 保存URL的数组
                        [self.urlArray addObject:constrainURL];
                    } else {
                        NSLog(@"error: %@", task.error);
                    }
                }
            }
        }
        // 刷新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    });
}

#pragma mark - load_data

- (void)loadNewHomeData
{
    [self.dataArray removeAllObjects];
    
    [self getAllContactsFromFMDB];
}

#pragma mark - collectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
//    return 28;
    return self.dataArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HomeViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:concernReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[HomeViewCell alloc] initWithFrame:CGRectMake(0, 0, itemWidth, itemWidth * 1.3)];
    }
    if (indexPath.row == 0) {
        cell.backgroundColor = [UIColor whiteColor];
    }else {
        cell.backgroundColor = [self randomColor];
    }
    
    // 设置值
    [cell setValueForImageViewWithURL:self.urlArray[indexPath.item] andNickName:self.dataArray[indexPath.item] andUserID:self.idArray[indexPath.item]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *userID = self.idArray[indexPath.item + 1];
    GetUserInfoAPI *userInfoAPI = [[GetUserInfoAPI alloc] init];
    [userInfoAPI requestWithObject:@[userID] Completion:^(NSArray *response, NSError *error) {
        [response enumerateObjectsUsingBlock:^(MTTUserEntity *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // 跳转用户信息控制器
            PublicProfileViewControll *ppVC = [[PublicProfileViewControll alloc] init];
            ppVC.user = obj;
            
            [self pushViewController:ppVC animated:YES];
        }];
    }];
}

#pragma mark - UIScrollViewDelegate

// 拖拽完成
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.cameraIsOpen) {
        if (self.timer == nil) {
            [self startTimer];
        }
    }
    
    if (self.refreshTimer == nil) {
        [self startRefreshTimer];
    }
}

// 将要开始拖拽的时候
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.cameraIsOpen) {
        if (self.timer) {
            [self stopTimer];
        }
    }
    
    if (self.refreshTimer) {
        [self stopRefreshTimer];
    }
}

#pragma mark - CollectionFirstItemViewDelegate

- (void)startUploadImage
{
    self.cameraIsOpen = YES;
    [self startTimer];
}

- (void)stopUploadImage
{
    self.cameraIsOpen = NO;
    [self stopTimer];
}

#pragma mark - 提醒用户开启摄像头

- (void)userRefuseOpenCamera
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"已关闭相机功能，如需重新开启可前往 “设置->隐私->相机” 里设置开启" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

// 提醒设置
- (void)alertUserOpenCameraSetting
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"未获得授权使用摄像头" message:@"请在iOS“设置”-“隐私”-“相机”中打开" preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - 定时器事件

// 开启定时器
- (void)startTimer
{
    // 20s上传阿里云
    self.timer = [NSTimer scheduledTimerWithTimeInterval:6.0 target:self selector:@selector(uploadImageToAliyunOSS) userInfo:nil repeats:YES];
    
    // 添加到主运行循环中
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)uploadImageToAliyunOSS
{
    UIImage *image = self.firstItemView.imageView.image;
    UIImage *newImage = [UIImage fixOrientation:image];
    // 等比缩放图片
    newImage = [UIImage scaleImage:newImage toScale:0.5];
    NSData *imgData = UIImageJPEGRepresentation(newImage, 0.3);
    if (imgData == nil) return;
    
    // 上传文件名
    MTTPhotoEnity *photoEnity = [[MTTPhotoEnity alloc] init];
    photoEnity.localPath = [[MTTPhotosCache sharedPhotoCache] getHomeImgKeyName];
    
    // 缓存磁盘
    [[MTTPhotosCache sharedPhotoCache] storePhoto:imgData forKey:photoEnity.localPath toDisk:YES];
    NSString *imgKey = [photoEnity.localPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // 将图片上传阿里云
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[DDSendPhotoMessageAPI sharedPhotoCache] homeUploadBlogToAliYunOSSWithContent:imgKey success:^(NSString *fileURL) {
            
        } failure:^(NSError *error) {
            DDLog(@"upload failure：error");
        }];
    });
}

// 暂停
- (void)stopTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - other
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIColor *)randomColor
{
    CGFloat r = arc4random_uniform(256) / 255.0;
    CGFloat g = arc4random_uniform(256) / 255.0;
    CGFloat b = arc4random_uniform(256) / 255.0;
    
    UIColor *color = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
    return color;
}

@end
