package com.tenth.space.imservice.manager;

import android.util.Log;

import com.google.protobuf.ProtocolStringList;
import com.tenth.space.DB.entity.UserEntity;
import com.tenth.space.imservice.event.CountEvent;
import com.tenth.space.protobuf.IMBaseDefine;
import com.tenth.space.protobuf.IMBuddy;

import java.util.ArrayList;
import java.util.List;

import de.greenrobot.event.EventBus;

/**
 * Created by Administrator on 2016/11/29.
 */

public class IMonLineCountManager extends IMManager {
    private static IMonLineCountManager inst = new IMonLineCountManager();

    public static IMonLineCountManager instance() {
        return inst;
    }

    public IMonLineCountManager() {
    }

    // 依赖的服务管理
    private IMSocketManager imSocketManager = IMSocketManager.instance();

    public void  getONlineCount(int userId){
        imSocketManager.isSocketConnect();
        IMBuddy.IMALLOnlineUserCntReq req=  IMBuddy.IMALLOnlineUserCntReq.newBuilder()
                .setUserId(userId).build();
        int sid =IMBaseDefine.ServiceID.SID_BUDDY_LIST_VALUE;
        int cid = IMBaseDefine.BuddyListCmdID.CID_BUDDY_LIST_ALL_ONLINE_USER_CNT_REQUEST_VALUE;
        imSocketManager.sendRequest(req,sid,cid);

    }
    public void sendRecommendRqs(int uerId ){
        IMBuddy.IMRecommendListReq recommendListReq=IMBuddy.IMRecommendListReq
                .newBuilder()
                .setUserId(uerId)
                .setPage(Integer.MAX_VALUE)
                .setPageSize(Integer.MAX_VALUE)
                .build();
        int sid = IMBaseDefine.ServiceID.SID_BUDDY_LIST_VALUE;
        int cid = IMBaseDefine.BuddyListCmdID.CID_BUDDY_LIST_RECOMMEND_LIST_REQUEST_VALUE;
        imSocketManager.sendRequest(recommendListReq, sid, cid);
    }

    public  void  getRecommendRsp(IMBuddy.IMRecommendListRsp imRecommendListRsp){
        List<UserEntity> userEntityList=new ArrayList<>();
       userEntityList.add(0,new UserEntity(IMLoginManager.instance().getLoginId()));
        List<Integer> recommendListList = imRecommendListRsp.getRecommendListList();
        ProtocolStringList recommendNickListList = imRecommendListRsp.getRecommendNickListList();
        //Log.i("GTAG","recommendListList="+recommendListList.size()+"  recommendNickListList="+recommendNickListList.size());
        if (recommendListList==null||recommendNickListList==null){
            return;
        }
        for (int i=0;i<recommendListList.size();i++){
            if (recommendListList.get(i)!=IMLoginManager.instance().getLoginId()){
                //Log.i("GTAG","id="+recommendListList.get(i));
                UserEntity userEntity=new UserEntity();
                userEntity.setPeerId(recommendListList.get(i));
                userEntity.setMainName(recommendNickListList.get(i));
                userEntityList.add(userEntity);
            }

        }
        triggerEvent(new CountEvent(CountEvent.Event.RECOMMEND_OK_BACK,userEntityList));

    }

    public void onOperateGetCount(IMBuddy.IMALLOnlineUserCntRsp imallOnlineUserCntRsp) {
        int userCnt = imallOnlineUserCntRsp.getOnlineUserCnt();
        triggerEvent(new CountEvent(CountEvent.Event.UPDATACOUNT,userCnt));
        //发送出去
    }
    public  synchronized void triggerEvent( CountEvent event) {
        EventBus.getDefault().postSticky(event);
    }

    @Override
    public void doOnStart() {

    }

    @Override
    public void reset() {
        EventBus.getDefault().unregister(inst);
    }
}
