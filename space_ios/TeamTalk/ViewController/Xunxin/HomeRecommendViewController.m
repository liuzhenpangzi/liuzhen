//
//  HomeRecommendViewController.m
//  TeamTalk
//
//  Created by 1 on 16/11/15.
//  Copyright © 2016年 IM. All rights reserved.
//

#import "HomeRecommendViewController.h"
#import "PublicProfileViewControll.h"
#import "RecommendFirstItemView.h"
#import "InfiniteScrollView.h"
#import "HomeViewCell.h"
#import "MJRefresh.h"
#import "MTTAFNetworkingClient.h"
#import "MTTPhotosCache.h"
#import "MTTUserEntity.h"
#import "UIImage+Orientation.h"
/** API*/
#import "DDSendPhotoMessageAPI.h"
#import "HomeRecommendUserListAPI.h"
#import <AliyunOSSiOS/OSSService.h>
#import "GetUserInfoAPI.h"

#define HomeScreenWidth [UIScreen mainScreen].bounds.size.width
#define HomeScreenHeight [UIScreen mainScreen].bounds.size.height

static CGFloat const margin = 3; // item 的间距
static int const cols = 2;
static NSString *const recommendReuseIdentifier = @"recommendCell";
#define itemWidth (self.view.frame.size.width - ((cols - 1) * margin)) / cols

@interface HomeRecommendViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate, RecommendFirstItemViewDelegate, InfiniteScrollViewDelegate>

@property (nonatomic, weak)   UICollectionView *collectionView;
/** 用户昵称*/
@property (nonatomic, strong) NSMutableArray *dataArray;
/** 用户图片URL*/
@property (nonatomic, strong) NSMutableArray *urlArray;
/** 用户id*/
@property (nonatomic, strong) NSMutableArray *idArray;

@property (nonatomic, weak)   RecommendFirstItemView *firstItemView;
/** 定时上传图片*/
@property (nonatomic, weak)   NSTimer *timer;
/** 定时刷新请求数据*/
@property (nonatomic, weak)   NSTimer *refreshTimer;
@property (nonatomic, assign) BOOL cameraIsOpen;
@property (nonatomic, weak)   InfiniteScrollView *scrollView;
@property (nonatomic, assign) NSInteger page;
@property (nonatomic, strong) MTTUserEntity *userEntity;

@end

@implementation HomeRecommendViewController

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

#pragma mark - View

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self startRefreshTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self stopRefreshTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.page = 1;
    MTTUserEntity *userEntity = (MTTUserEntity *)TheRuntime.user;
    self.userEntity = userEntity;
    
    // 广告轮播器
    [self setupADView];
    self.cameraIsOpen = NO;
    
    // 创建collectionView
    [self setupHomeCollectionView];
    
    [self loadNewHomeRecommendDatas];
    
    // 注册监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentViewIsThisView) name:@"RecommendView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentViewIsAnotherView) name:@"FriendView" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentViewIsAnotherView) name:@"ConcernView" object:nil];
    // 控制器view将要消失的时候
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentViewIsAnotherView) name:@"HomeViewWillDisappear" object:nil];
}

#pragma mark - 监听事件

- (void)currentViewIsThisView
{
    if (self.refreshTimer == nil) {
        [self startRefreshTimer];
    }
}

- (void)currentViewIsAnotherView
{
    if (self.refreshTimer) {
        [self stopRefreshTimer];
    }
}

#pragma mark - 创建view

- (void)setupADView
{
    InfiniteScrollView *scrollView = [[InfiniteScrollView alloc] init];
    scrollView.imagesArray = @[
//                               [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://mobile.10thcommune.com/html/images/ad01.jpg"]]],
//                               [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://mobile.10thcommune.com/html/images/ad02.jpg"]]],
                               [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://mobile.10thcommune.com/html/images/ad03.jpg"]]]
                               ];
    
    scrollView.frame = CGRectMake(0, 0, HomeScreenWidth, 150);
    scrollView.delegate = self;
    
    self.scrollView = scrollView;
    [self.view addSubview:scrollView];
}

- (void)setupHomeCollectionView
{
    // 布局
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumLineSpacing = margin;
    layout.minimumInteritemSpacing = margin;
    layout.itemSize = CGSizeMake(itemWidth, itemWidth * 1.3);
    // 设置collectionView item开始时的高度
    layout.headerReferenceSize = CGSizeMake(0, 152);
    
    
    // collectionView
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, HomeScreenWidth, HomeScreenHeight - 64 - 49 - margin - 21) collectionViewLayout:layout];
    collectionView.backgroundColor = [UIColor whiteColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    [collectionView registerClass:[HomeViewCell class] forCellWithReuseIdentifier:recommendReuseIdentifier];
    
    
    // 上下拉刷新加载
//    [collectionView addHeaderWithTarget:self action:@selector(loadNewHomeRecommendDatas) dateKey:@"head"];
//    [collectionView headerBeginRefreshing];
    [collectionView addFooterWithTarget:self action:@selector(loadMoreHomeRecommendDatas)];
    
    
    // 显示自己摄像头数据
    RecommendFirstItemView *firstItemView = [[RecommendFirstItemView alloc] initWithFrame:CGRectMake(0, 152, itemWidth, itemWidth * 1.3)];
    firstItemView.backgroundColor = [UIColor lightGrayColor];
    firstItemView.delegate = self;
    self.firstItemView = firstItemView;
    [collectionView addSubview:firstItemView];
    
    // 广告轮播
    [collectionView addSubview:self.scrollView];
    
    self.collectionView = collectionView;
    [self.view addSubview:collectionView];
}

#pragma mark - 定时刷新

- (void)startRefreshTimer
{
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:13.0 target:self selector:@selector(loadNewHomeRecommendDatas) userInfo:nil repeats:YES];
    // 添加到主运行循环中
    [[NSRunLoop currentRunLoop] addTimer:self.refreshTimer forMode:NSRunLoopCommonModes];
}

- (void)refreshUserAliyunOSSImages
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NSInteger i = 0; i < self.urlArray.count; i++) {
            
            NSString *userID = self.idArray[i];
            if (![userID containsString:self.userEntity.userID]) {
                // 检查是否有对应文件
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
                    // 删除数据
                    [self.idArray removeObject:userID];
                    [self.dataArray removeObjectAtIndex:i];
                    [self.urlArray removeObjectAtIndex:i];
                }
            }
        }
        // 刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
    });
}

- (void)stopRefreshTimer
{
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
}

#pragma mark - load_data

- (void)loadNewHomeRecommendDatas
{
    [self.dataArray removeAllObjects];
    self.page = 1;
    
    MTTUserEntity *userEntity = (MTTUserEntity *)TheRuntime.user;
    [self.dataArray addObject:userEntity.nick];
    [self.urlArray  addObject:userEntity.userID];
    [self.idArray   addObject:userEntity.userID];
    
    HomeRecommendUserListAPI *api = [[HomeRecommendUserListAPI alloc] init];
    NSDictionary *params = @{
                             @"page": @"0",
                             @"pageSize": @"10"
                             };
    // 请求数据
    [api requestWithObject:params Completion:^(NSArray *response, NSError *error) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // 检查阿里云是否有对应的用户图片数据
            [self aliyunOSSImagesForUsers:response andCurrentUserEntity:userEntity];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
        });
    }];
    
    [self.collectionView headerEndRefreshing];
}

- (void)loadMoreHomeRecommendDatas
{
    MTTUserEntity *userEntity = (MTTUserEntity *)TheRuntime.user;
    [self.dataArray addObject:userEntity.nick];
    [self.urlArray  addObject:userEntity.userID];
    [self.idArray   addObject:userEntity.userID];
    
    NSString *currentPage = [NSString stringWithFormat:@"%zd", self.page];
    HomeRecommendUserListAPI *api = [[HomeRecommendUserListAPI alloc] init];
    NSDictionary *params = @{
                             @"page": currentPage,
                             @"pageSize": @"10"
                             };
    
    // 请求数据
    [api requestWithObject:params Completion:^(NSArray *response, NSError *error) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            // 检查阿里云是否有对应的用户图片数据
            [self aliyunOSSImagesForUsers:response andCurrentUserEntity:userEntity];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.page++;
                [self.collectionView reloadData];
            });
        });
    }];
    
    [self.collectionView footerEndRefreshing];
}

// 检查阿里云是否有对应的用户图片数据
- (void)aliyunOSSImagesForUsers:(NSArray *)response andCurrentUserEntity:(MTTUserEntity *)userEntity
{
    for (NSString *info in response) {
        if (![info containsString:userEntity.userID]) {
            // 截取用户信息
            NSRange range      = [info rangeOfString:@"-"];
            NSString *userID   = [info substringToIndex:range.location];
            NSString *userNickName  = [info substringFromIndex:range.location + 1];
            
            
            NSString  *constrainURL = nil;
            NSString  *objectKey = [NSString stringWithFormat:@"im/live/%@.png", userID];
            OSSClient *client = [[DDSendPhotoMessageAPI sharedPhotoCache] ossInit];
            OSSTask   *task = [client presignConstrainURLWithBucketName:kHomeBucketNameInAliYunOSS
                                                          withObjectKey:objectKey
                                                 withExpirationInterval: 30 * 60];
            if (!task.error) {
                constrainURL = task.result;
                // 保存URL的数组
                [self.urlArray  addObject:constrainURL];
                // 保存昵称的数组
                [self.dataArray addObject:userNickName];
                // 保存id
                [self.idArray addObject:userID];
                
            } else {
                NSLog(@"error: %@", task.error);
            }
        }
    }
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
    HomeViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:recommendReuseIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[HomeViewCell alloc] initWithFrame:CGRectMake(0, 0, itemWidth, itemWidth * 1.3)];
    }
    if (indexPath.row == 0) {
        cell.backgroundColor = [UIColor whiteColor];
    }else {
        cell.backgroundColor = [UIColor lightGrayColor];
    }
    
    // 给cell传值
    [cell setValueForImageViewWithURL:self.urlArray[indexPath.item] andNickName:self.dataArray[indexPath.item] andUserID:self.idArray[indexPath.item]];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *userID = self.idArray[indexPath.item];
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

// 广告轮播的点击
- (void)infiniteScrollView:(InfiniteScrollView *)infiniteScrollView didClickImageAtIndex:(NSInteger)index
{
    NSLog(@"%s", __func__);
}

// 拖拽完成
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.cameraIsOpen) {
        [self startTimer];
    }
    [self startRefreshTimer];
}

// 将要开始拖拽的时候
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.cameraIsOpen) {
        [self stopTimer];
    }
    [self stopRefreshTimer];
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
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"提示" message:@"已关闭相机功能，如需重新开启可前往“设置->隐私->相机”里设置开启" preferredStyle:UIAlertControllerStyleAlert];
    
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
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(dealWithTimerThing) userInfo:nil repeats:YES];
    
    // 添加到主运行循环中
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)dealWithTimerThing
{
    [self uploadImageToAliyunOSS];
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
