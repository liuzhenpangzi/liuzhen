//
//  GetUserInfoAPI.m
//  TeamTalk
//
//  Created by 1 on 16/12/20.
//  Copyright © 2016年 MoguIM. All rights reserved.
//

#import "GetUserInfoAPI.h"
#import "IMBuddy.pb.h"
#import "MTTUserEntity.h"

@implementation GetUserInfoAPI

- (int)requestTimeOutTimeInterval
{
    return 0;
}

- (int)requestServiceID
{
    return SID_BUDDY_LIST;
}

- (int)responseServiceID
{
    return SID_BUDDY_LIST;
}

- (int)requestCommendID
{
    return CID_BUDDY_LIST_USER_INFO_REQUEST;
}

- (int)responseCommendID
{
    return CID_BUDDY_LIST_USER_INFO_RESPONSE;
}

- (Analysis)analysisReturnData
{
    Analysis analysis = (id)^(NSData* data)
    {
        IMUsersInfoRsp *rsp = [IMUsersInfoRsp parseFromData:data];
//        NSLog(@"rsp--%@", rsp);
        
        NSMutableArray *array = [NSMutableArray array];
        for (UserInfo *info in [rsp userInfoList]) {
            MTTUserEntity *userEntity = [[MTTUserEntity alloc] initWithPB:info];
            [array addObject:userEntity];
        }
        
        return array;
    };
    
    return analysis;
}

- (Package)packageRequestObject
{
    Package package = (id)^(id object,uint32_t seqNo) {
        
        NSArray *listArray = (NSArray *)object;
        NSString *user_id = nil;
        if (listArray.count) {
            user_id = listArray[0];
        }
        NSInteger userID = [user_id integerValue];
        
        MTTUserEntity *userEntity = (MTTUserEntity *)TheRuntime.user;
        
        IMUsersInfoReqBuilder *reqBuilder = [IMUsersInfoReq builder];
        // 设置参数
        [reqBuilder setUserId:(UInt32)userEntity.userID];
        [reqBuilder setUserIdListArray:@[@(userID)]];
        [reqBuilder setAttachData:nil];
        
        
        DDDataOutputStream *dataout = [[DDDataOutputStream alloc] init];
        [dataout writeInt:0];
        [dataout writeTcpProtocolHeader:SID_BUDDY_LIST
                                    cId:CID_BUDDY_LIST_USER_INFO_REQUEST
                                  seqNo:seqNo];
        [dataout directWriteBytes:[reqBuilder build].data];
        [dataout writeDataCount];
        
        return [dataout toByteArray];
    };
    
    return package;
}

@end
