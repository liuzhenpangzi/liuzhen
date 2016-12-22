package com.tenth.space.ui.activity;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import com.tenth.space.DB.DBInterface;
import com.tenth.space.DB.entity.UserEntity;
import com.tenth.space.R;
import com.tenth.space.app.IMApplication;
import com.tenth.space.imservice.manager.IMBuddyManager;
import com.tenth.space.imservice.manager.IMLoginManager;
import com.tenth.space.imservice.manager.IMSocketManager;
import com.tenth.space.protobuf.IMBaseDefine;
import com.tenth.space.protobuf.IMBuddy;
import com.tenth.space.utils.IMUIHelper;
import com.tenth.space.utils.ImageLoaderUtil;
import com.tenth.space.utils.Utils;
import com.nostra13.universalimageloader.core.ImageLoader;

public class UserActivity extends Activity {

    private ImageView avator;
    private TextView userName;
    private Button add_btn;
    private Button chat_btn;
    private Button addFollow;
    private int peerId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_attention_user);
        initView();
        setData();
    }

    private void initView() {
        avator = (ImageView) findViewById(R.id.user_portrait);
        userName = (TextView) findViewById(R.id.nickName);
        add_btn = (Button) findViewById(R.id.add_btn);
        addFollow = (Button) findViewById(R.id.add_follow);
        chat_btn = (Button) findViewById(R.id.msg_btn);
    }

    private void setData() {
        String avator_url=null;
        String main_name;
        Intent intent = getIntent();
        String friend_name = intent.getStringExtra("friend_name");
        peerId = intent.getIntExtra("peerId", 0);
        addFollow.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                    int userId = IMLoginManager.instance().getLoginId();
                    IMBuddy.IMFollowUserReq followUserReq
                            = IMBuddy.IMFollowUserReq
                            .newBuilder()
                            .setUserId(userId)
                            .setFriendId(peerId)
                            .build();
                    int sid = IMBaseDefine.ServiceID.SID_BUDDY_LIST_VALUE;
                    int cid = IMBaseDefine.BuddyListCmdID.CID_BUDDY_LIST_FOLLOW_USER_REQUEST_VALUE;
                    IMSocketManager.instance().sendRequest(followUserReq, sid, cid);
                finish();
                }
        });
        if (! Utils.isStringEmpty(friend_name)) {
            add_btn.setVisibility(View.GONE);
            chat_btn.setVisibility(View.VISIBLE);
            main_name=friend_name;
            final UserEntity byUserName = DBInterface.instance().queryByUserName(friend_name);
            avator_url=byUserName.getAvatar();
            chat_btn.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    String sessionKey = byUserName.getSessionKey();
                    IMUIHelper.openChatActivity(UserActivity.this, sessionKey);
                    UserActivity.this.finish();
                }
            });
        } else {
            add_btn.setVisibility(View.VISIBLE);
            chat_btn.setVisibility(View.GONE);
            avator_url = intent.getStringExtra("avatar");
            main_name = intent.getStringExtra("main_name");
            add_btn.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    Intent addIntent = new Intent(UserActivity.this, AddActivity.class);
                    addIntent.putExtra("friendId", peerId);
                    startActivity(addIntent);
                    UserActivity.this.finish();
                }
            });
        }
        ImageLoader.getInstance().displayImage(IMApplication.app.UrlFormat(avator_url), avator, ImageLoaderUtil.getAvatarOptions(0, 0));
        userName.setText(main_name);
    }

}
