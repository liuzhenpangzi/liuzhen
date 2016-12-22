package com.tenth.space.ui.fragment;

import android.content.Intent;
import android.os.Bundle;
import android.support.annotation.Nullable;
import android.support.v4.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ListView;

import com.tenth.space.DB.DBInterface;
import com.tenth.space.DB.entity.UserEntity;
import com.tenth.space.R;
import com.tenth.space.imservice.event.BlogInfoEvent;
import com.tenth.space.imservice.event.GroupEvent;
import com.tenth.space.imservice.event.UserInfoEvent;
import com.tenth.space.imservice.manager.IMContactManager;
import com.tenth.space.protobuf.IMBaseDefine;
import com.tenth.space.ui.activity.UserActivity;
import com.tenth.space.ui.adapter.ContactAdapter;
import com.tenth.space.utils.IMUIHelper;

import java.util.Iterator;
import java.util.List;

import de.greenrobot.event.EventBus;

import static com.tenth.space.imservice.event.GroupEvent.Event.GROUP_INFO_OK;
import static com.tenth.space.imservice.event.GroupEvent.Event.GROUP_INFO_UPDATED;
import static com.tenth.space.imservice.event.GroupEvent.Event.event;
import static com.tenth.space.imservice.event.UserInfoEvent.Event.USER_INFO_UPDATE;

/**
 * Created by Administrator on 2016/11/28.
 */

public class AttentionFragment extends Fragment implements AdapterView.OnItemLongClickListener{

    private View mcurView;
    private ContactAdapter contactAdapter;
    private ListView attentionUsers;
    private List<UserEntity> contactList;

    @Nullable
    @Override
    public View onCreateView(LayoutInflater inflater,ViewGroup container,Bundle savedInstanceState) {
        if (null != mcurView) {
            ((ViewGroup) mcurView.getParent()).removeView(mcurView);
            return mcurView;
        }
        mcurView = inflater.inflate(R.layout.fragments_contact, null);
        initView();
        EventBus.getDefault() .register(this);
        return mcurView;
    }
    private void initView(){
        contactAdapter = new ContactAdapter(getActivity());
        mcurView.findViewById(R.id.new_friends).setVisibility(View.GONE);
        attentionUsers = (ListView) mcurView.findViewById(R.id.all_contact_list);
        attentionUsers.setOnItemLongClickListener(this);
        attentionUsers.setAdapter(contactAdapter);
        renderUserList();
    }
    private void renderUserList() {
        contactList = IMContactManager.instance().getContactSortedList();
        for (Iterator<UserEntity> userEntitys = contactList.iterator(); userEntitys.hasNext();) {
            UserEntity userEntity = userEntitys.next();
            if(! userEntity.getRelation().equals(IMBaseDefine.UserRelationType.RELATION_FOLLOW.name())){
                userEntitys.remove();
            }
        }
        // 没有任何的联系人数据
        if (contactList.size() <= 0) {
            mcurView.findViewById(R.id.contact).setVisibility(View.GONE);
            mcurView.findViewById(R.id.no_attention).setVisibility(View.VISIBLE);
            return;
        }else {
            mcurView.findViewById(R.id.contact).setVisibility(View.VISIBLE);
            mcurView.findViewById(R.id.no_attention).setVisibility(View.GONE);
        }
        contactAdapter.putUserList(contactList);
        contactAdapter.notifyDataSetChanged();
    }
    private void renderUserList1() {
        contactList = DBInterface.instance().loadAllUsers();
        for (Iterator<UserEntity> userEntitys = contactList.iterator(); userEntitys.hasNext();) {
            UserEntity userEntity = userEntitys.next();
            if(! userEntity.getRelation().equals(IMBaseDefine.UserRelationType.RELATION_FOLLOW.name())){
                userEntitys.remove();
            }
        }
        // 没有任何的联系人数据
        if (contactList.size() <= 0) {
            mcurView.findViewById(R.id.contact).setVisibility(View.GONE);
            mcurView.findViewById(R.id.no_attention).setVisibility(View.VISIBLE);
            return;
        }else {
            mcurView.findViewById(R.id.contact).setVisibility(View.VISIBLE);
            mcurView.findViewById(R.id.no_attention).setVisibility(View.GONE);
        }
        contactAdapter.putUserList(contactList);
        contactAdapter.notifyDataSetChanged();
    }
    public void onEventMainThread(BlogInfoEvent event) {
        switch (event.getEvent()) {
            case FOLLOW_SUCCESS:
                renderUserList();
                break;
        }
    }
    public void onEventMainThread(UserInfoEvent.Event event) {
        switch (event) {
            case USER_INFO_UPDATE:
                renderUserList1();
                break;
        }
    }
//    @Override
//    public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
//        UserEntity userEntity = contactList.get(position);
//        String avatar = userEntity.getAvatar();
//        int peerId = userEntity.getPeerId();
//        Intent intent = new Intent(getActivity(), UserActivity.class);
//        intent.putExtra("avatar",avatar);
//        intent.putExtra("peerId",peerId);
//        intent.putExtra("main_name",userEntity.getMainName());
//        startActivity(intent);
//    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        EventBus.getDefault().unregister(this);
    }

    @Override
    public boolean onItemLongClick(AdapterView<?> parent, View view, int position, long id) {
        IMUIHelper.attentionItemLongClick(contactList.get(position),getActivity());
        return false;
    }
}
