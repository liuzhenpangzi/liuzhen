package com.tenth.space.imservice.event;

import com.tenth.space.DB.entity.UserEntity;

import java.util.List;

/**
 * Created by Administrator on 2016/11/29.
 */

public class CountEvent {

    private  List<UserEntity> list;
    private CountEvent.Event event;
    private int count;

    public List<UserEntity> getList() {
        return list;
    }

    /**很多的场景只是关心改变的类型以及change的Ids*/

    public CountEvent(Event event,int count){
        this.event = event;
        this.count=count;
    }

    public CountEvent(Event event,List<UserEntity> list){
        this.event = event;
        this.list=list;
    }
    public enum Event{
        UPDATACOUNT,
        RECOMMEND_OK_BACK
    }

    public Event getEvent() {
        return event;
    }

    public void setEvent(Event event) {
        this.event = event;
    }

    public int getCount() {
        return this.count;
    }
}
