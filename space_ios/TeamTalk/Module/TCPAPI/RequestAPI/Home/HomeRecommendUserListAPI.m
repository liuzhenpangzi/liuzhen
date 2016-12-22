//
//  HomeRecommendUserListAPI.m
//  TeamTalk
//
//  Created by 1 on 16/12/16.
//  Copyright © 2016年 MoguIM. All rights reserved.
//

#import "HomeRecommendUserListAPI.h"
#import "IMBuddy.pb.h"
#import "MTTUserEntity.h"
#import "MTTGroupEntity.h"

@implementation HomeRecommendUserListAPI

/**
 *  请求超时时间
 *
 *  @return 超时时间
 */
- (int)requestTimeOutTimeInterval
{
    return 0;
}

/**
 *  请求的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)requestServiceID
{
    return SID_BUDDY_LIST;
}

/**
 *  请求返回的serviceID
 *
 *  @return 对应的serviceID
 */
- (int)responseServiceID
{
    return SID_BUDDY_LIST;
}

/**
 *  请求的commendID
 *
 *  @return 对应的commendID
 */
- (int)requestCommendID
{
    return CID_BUDDY_LIST_RECOMMEND_LIST_REQUEST;
}

/**
 *  请求返回的commendID
 *
 *  @return 对应的commendID
 */
- (int)responseCommendID
{
    return CID_BUDDY_LIST_RECOMMEND_LIST_RESPONSE;
}

/**
 *  解析数据的block
 *
 *  @return 解析数据的block
 */
- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSData *data) {
        
        IMRecommendListRsp *resp = [IMRecommendListRsp parseFromData:data];
//        NSLog(@"resp--%@", resp);
        
        NSMutableArray *array = [NSMutableArray array];
        for (NSInteger i = 0; i < resp.recommendList.count; i++) {
            NSString *userID   = resp.recommendList[i];
            NSString *userName = resp.recommendNickList[i];
            
            NSString *info = [NSString stringWithFormat:@"%@-%@", userID, userName];
            [array addObject:info];
//            NSRange range = [info rangeOfString:@"-"];
//            NSLog(@"%@---%zd", info, range.location);
//            
//            NSString *headString = [info substringToIndex:range.location];
//            NSString *fonString = [info substringFromIndex:range.location + 1];
//
//            NSLog(@"headString-%@, fonString-%@", headString, fonString);
        }
        
        return array;
    };
    return analysis;
}

/**
 *  打包数据的block
 *
 *  @return 打包数据的block
 */
- (Package)packageRequestObject
{
    Package package = (id)^(id object,uint32_t seqNo) {
        
        NSDictionary *params = (NSDictionary *)object;
        NSString *pageString     = [params objectForKey:@"page"];
        NSString *pageSizeString = [params objectForKey:@"pageSize"];
        NSInteger page           = [pageString integerValue];
        NSInteger pageSize       = [pageSizeString integerValue];
        
        MTTUserEntity *userEntity = (MTTUserEntity *)TheRuntime.user;
        
        IMRecommendListReqBuilder *reqBuilder = [IMRecommendListReq builder];
        // 设置参数
        [reqBuilder setUserId:(UInt32)userEntity.userID];
        [reqBuilder setPage:(UInt32)page];
        [reqBuilder setPageSize:(UInt32)pageSize];
        [reqBuilder setAttachData:nil];
        
        
        DDDataOutputStream *dataout = [[DDDataOutputStream alloc] init];
        [dataout writeInt:0];
        [dataout writeTcpProtocolHeader:SID_BUDDY_LIST
                                    cId:CID_BUDDY_LIST_RECOMMEND_LIST_REQUEST
                                  seqNo:seqNo];
        [dataout directWriteBytes:[reqBuilder build].data];
        [dataout writeDataCount];
        
        return [dataout toByteArray];
    };
    
    return package;
}

@end
