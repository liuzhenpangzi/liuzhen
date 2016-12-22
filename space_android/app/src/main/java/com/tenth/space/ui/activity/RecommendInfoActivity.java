package com.tenth.space.ui.activity;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.TextView;

import com.tenth.space.DB.entity.UserEntity;
import com.tenth.space.R;
import com.tenth.space.config.IntentConstant;
import com.tenth.space.imservice.event.UserInfoEvent;
import com.tenth.space.imservice.manager.IMContactManager;
import com.tenth.space.moments.MomentsBaseActivity;
import com.tenth.space.ui.base.TTBaseActivity;
import com.tenth.space.ui.fragment.ContactsFragment;
import com.tenth.space.utils.ImageLoaderUtil;
import com.tenth.space.utils.ToastUtils;
import com.tenth.space.utils.Utils;

import java.util.ArrayList;
import java.util.Map;

import butterknife.OnClick;
import de.greenrobot.event.EventBus;


public class RecommendInfoActivity extends Activity implements View.OnClickListener {
    private ImageView headIv;
    private TextView go_back;
    private RadioButton radio_man;
    private RadioButton radio_women;
    private TextView nickName;
    private TextView fans_cnt;
    private TextView et_signature;
    private TextView tv_referralcode;
    private LinearLayout ll_progress_bar;
    private int peerId;
    private UserEntity currentEntity;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_recommend_info);
        EventBus.getDefault().register(this);
        peerId=getIntent().getIntExtra(IntentConstant.KEY_PEERID,-1);
        initView();
        initData();
    }

    private void initData() {
        ArrayList<Integer> integers=new ArrayList<>();
        integers.add(peerId);
        IMContactManager.instance().reqGetDetaillUsers(integers);
    }

    private void initView() {
        // 设置标题栏
        headIv=(ImageView)findViewById(R.id.user_portrait);
        headIv.setOnClickListener(this);
        go_back=(TextView)findViewById(R.id.go_back);
        go_back.setOnClickListener(this);
        radio_man=(RadioButton)findViewById(R.id.rb_man);
        radio_women=(RadioButton)findViewById(R.id.rb_woman);
        nickName=(TextView)findViewById(R.id.nickName);
        fans_cnt=(TextView)findViewById(R.id.fans_cnt);
        et_signature=(TextView)findViewById(R.id.et_signature);
        tv_referralcode=(TextView)findViewById(R.id.tv_referralcode);
        ll_progress_bar=(LinearLayout)findViewById(R.id.ll_progress_bar);
    }

    public  void onEventMainThread(UserInfoEvent.Event event){
        switch (event){
            case USER_INFO_UPDATE:
                ll_progress_bar.setVisibility(View.GONE);
                Map<Integer, UserEntity> map = IMContactManager.instance().getUserMap();
                 currentEntity = map.get(peerId);
                ImageLoaderUtil.instance().displayImage(currentEntity.getAvatar(),headIv,ImageLoaderUtil.getAvatarOptions(10,0));
                int gender = currentEntity.getGender();
                if (gender==2){
                    radio_women.setChecked(true);
                }else {
                    radio_man.setChecked(true);
                }
                nickName.setText(currentEntity.getMainName()+"");
                fans_cnt.setText(currentEntity.getFansCnt()+"");
                et_signature.setText(currentEntity.getSignature()+"");
                tv_referralcode.setText(currentEntity.getRealName()+"");
                break;
        }

    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (EventBus.getDefault().isRegistered(this)) {
            EventBus.getDefault().unregister(this);
        }
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()){
            case R.id.go_back:
                finish();
                break;
            case R.id.user_portrait:
                if (!Utils.isStringEmpty(currentEntity.getAvatar())){
                    Intent intent = new Intent(this, DetailPortraitActivity.class);
                    intent.putExtra(IntentConstant.KEY_AVATAR_URL, currentEntity.getAvatar());
                    intent.putExtra(IntentConstant.KEY_IS_IMAGE_CONTACT_AVATAR, true);
                    startActivity(intent);
                }else {
                    ToastUtils.show("该用户还未上传图片");
                }

                break;
        }

    }
}
