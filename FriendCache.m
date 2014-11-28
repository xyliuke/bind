//
//  FriendCache.m
//  LayoutFramework
//
//  Created by liuke on 14-3-29.
//  Copyright (c) 2014年 liuke. All rights reserved.
//

#import "FriendCache.h"
#import "CacheContainer.h"
#import "PropertyJsonMap.h"
#import "NSString+Util.h"

@implementation FriendCache

#pragma -- mark 重写父类的方法

- (NSString*) map:(NSString *)json_key
{
    static NSDictionary* dic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dic = @{
                KEY_AGE : [FriendCache __age__],
                KEY_NAME : [FriendCache __name__],
                KEY_NICK_NAME : [FriendCache __nick_name__],
                };
    });
    NSString* ret = [dic objectForKey:json_key];
    if (ret) {
        return ret;
    }
    return [super map:json_key];
}

- (NSDictionary*) getDotMap:(NSDictionary*) data
{
    static NSMutableDictionary* dic = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dic = [[NSMutableDictionary alloc] init];
        [dic addEntriesFromDictionary:[super getDotMap]];
        [dic addEntriesFromDictionary: @{
                                         @"device.pc" : [FriendCache __device_pc__],
                                         @"device.android" : [FriendCache __device_android__],
                                         }];
    });
    return dic;
}

- (void) fromDictionary:(NSDictionary *)dic
{
    [super fromDictionary:dic];
}

- (void) getExtraInfo:(NSString *)key
{
}

@end
