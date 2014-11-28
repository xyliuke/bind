//
//  FriendCache.h
//  LayoutFramework
//
//  Created by liuke on 14-3-29.
//  Copyright (c) 2014年 liuke. All rights reserved.
//

#import "CacheInfo.h"

@interface FriendCache : CacheInfo

PROPERTY_STRING(name, 姓名)
PROPERTY_STRING(age, 年龄)
PROPERTY_STRING(nick_name, 昵称)
PROPERTY_NUMBER(device_pc, pc设备是否在线)
PROPERTY_NUMBER(device_android, 安卓设备是否在线)

@end
