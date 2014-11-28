//
//  CacheContainer.m
//  LayoutFramework
//
//  Created by liuke on 14-3-27.
//  Copyright (c) 2014年 liuke. All rights reserved.
//

#import "CacheContainer.h"
#import "NSMutableDictionary+Primary.h"
#import <objc/runtime.h>
#import "Bind.h"
#import "CacheInfo.h"
#import "FriendCache.h"
#import "RecentRecordCache.h"
#import "FriendGroupCache.h"
#import "AppCache.h"
#import "AppCommentCache.h"
#import "CrowdCache.h"
#import "DiscussionCache.h"
#import "ConversationCache.h"
#import "NSArray+copy.h"
#import "ThreadContainer.h"
#import "ZoneCache.h"
#import "Bind.h"


typedef void(^block_1)(id);
typedef void(^block_2)(id, id);


@interface StaticBindUnit : NSObject
@property (nonatomic) Class cls;
@property (nonatomic, strong) NSString* keypath;
@property (nonatomic, strong) block_1 block;
@property (nonatomic, strong) NSString* valueKVC;
@property (nonatomic, weak) id user;
@property (nonatomic) NSUInteger tag;
@property (nonatomic) CacheDataType type;
@end
@implementation StaticBindUnit

- (BOOL) isEqual:(id)object
{
    if ([object isKindOfClass:[StaticBindUnit class]]) {
        StaticBindUnit* unit = (StaticBindUnit*)object;
        if (unit.cls == self.cls && [self.keypath isEqualToString:unit.keypath] && [self.user isEqual:unit.user] && self.tag == unit.tag) {
            return YES;
        }
        return NO;
    }
    return NO;
}

@end


@interface CacheContainer()
{
    NSMutableDictionary* friendCache_;
    NSMutableDictionary* crowdCache_;
    NSMutableDictionary* discussionCache_;
    NSMutableDictionary* recentMsgCache_;
    NSMutableDictionary* noticeCache_;
    NSMutableDictionary* appRemindCache_;
    NSMutableDictionary* appCache_;
    NSMutableDictionary* appCommnetCache_;//应用的评论
    NSMutableDictionary* chatCache_;
    NSMutableDictionary* groupCache_;
    NSMutableDictionary* zoneCache_;

    
    NSMutableDictionary* staticBind_;//绑定表态属性
    NSMutableDictionary* allPropertyBind_;//绑定某种cache中的所有数据中的一个属性
    
    NSMutableDictionary* bindCache_;//为了解决unbind时的效率
}

@end

@implementation CacheContainer

SINGLETON_IMPLEMENT(CacheContainer)

- (id) init
{
    self = [super init];
    if (self) {
        friendCache_ = [[NSMutableDictionary alloc] init];
        crowdCache_ = [[NSMutableDictionary alloc] init];
        discussionCache_ = [[NSMutableDictionary alloc] init];
        recentMsgCache_ = [[NSMutableDictionary alloc] init];
        noticeCache_ = [[NSMutableDictionary alloc] init];
        appRemindCache_ = [[NSMutableDictionary alloc] init];
        appCache_ = [[NSMutableDictionary alloc] init];
        appCommnetCache_ = [[NSMutableDictionary alloc] init];
        chatCache_ = [[NSMutableDictionary alloc] init];
        groupCache_ = [[NSMutableDictionary alloc] init];
        zoneCache_ = [[NSMutableDictionary alloc] init];
        
        staticBind_ = [[NSMutableDictionary alloc] init];
        allPropertyBind_ = [[NSMutableDictionary alloc] init];
        
        bindCache_ = [[NSMutableDictionary alloc] init];
        FILTER_LOG_THIS_FILE
    }
    return self;
}

- (NSMutableDictionary*) getCache:(CacheDataType) type
{
    switch (type) {
        case FRIEND_CACHE:
            return friendCache_;
        case CROWD_CACHE:
            return crowdCache_;
        case DISCUSSION_CACHE:
            return discussionCache_;
        case RECENT_MSG_CACHE:
            return recentMsgCache_;
        case NOTICE_CACHE:
            return noticeCache_;
        case APP_REMIND_CACHE:
            return appRemindCache_;
        case APP_CACHE:
            return appCache_;
        case APPCOMMENT_CACHE:
            return appCommnetCache_;
        case CHAT_CACHE:
            return chatCache_;
        case GROUP_CACHE:
            return groupCache_;
        case ZONE_CACHE:
            return zoneCache_;
        default:
            break;
    }
    return nil;
}

- (void) addCache:(id)info key:(NSString *)key forType:(CacheDataType)type
{
    NSAssert(key, @"cache的key值不存在");
    if (!key) {
        return;
    }
    BOOL exist = YES;
    if (![[self getCache:type] objectForKey:key]) {
        exist = NO;
    }
    //将数据添加到cache集合中
    [[self getCache:type] addObject:info key:key];
    if (!exist) {
        //原来不存在，新增后需要重新绑定所有该对象的属性
        [self reBind4AllProperty:type];
    }
}


- (CacheInfo*) getCache:(NSString *)key forType:(CacheDataType)type
{
    if (!key) {
        return nil;
    }
    return [[[self getCache:type] copy]objectForKey:key];
}

- (CacheInfo*) getCacheByKey:(NSString *)key
{
    CacheDataType type = FRIEND_CACHE;
    for (int i = FRIEND_CACHE; i <= NONE_CACHE; i++) {
        type = (CacheDataType) i;
        CacheInfo* ret = [self getCache:key forType:type];
        if (ret) {
            return ret;
        }
    }
    return nil;
}

- (CacheInfo*) updateCache:(NSString *)key data:(NSDictionary *)data forType:(CacheDataType)type
{
    CacheInfo* cache = [self getCache:key forType:type];
    if (cache) {
        [cache fromDictionary:data];
        [self reBind4AllProperty:type];
    }else{
        cache = [self createCache:type];
        [cache fromDictionary:data];
        cache.key = key;
        cache.cacheType = type;
        [self addCache:cache key:key forType:type];
    }
    return cache;
}

- (CacheInfo*) updateCache:(NSDictionary *)data forType:(CacheDataType)type
{
    if (data && [data isKindOfClass:[NSDictionary class]]) {
        CacheInfo* tmp = [self createCache:type];
        NSAssert(tmp, @"通过类型没有创建出对应的cache类，你需要在createCache函数中添加对应的类型处理");
        NSString* key = [tmp getKey:data];
        NSAssert(key, @"得到的数据中没有key值，请检查是数据错误还是解析错误");
        if (key) {
            return [self updateCache:key data:data forType:type];
        }else{
            return nil;
        }
    }
    return nil;
}

- (NSArray*) updateCacheByArray:(NSArray *)data forType:(CacheDataType)type
{
    if (![data isKindOfClass:[NSArray class]]) {
        return @[];
    }
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CacheInfo* cache = [[CacheContainer shareInstance] updateCache:obj forType:type];
        if (cache) {
            [arr addObject:cache];
        }
    }];
    return arr;
}

- (CacheInfo*) updateCacheNoKey:(NSDictionary *)data forType:(CacheDataType)type
{
    CacheInfo* tmp = [self createCache:type];
    NSString* key = [tmp getKey:data];
    NSMutableDictionary* copy = [data mutableCopy];
    [copy setObject:key forKey:@"jid"];//自动添加key
    return [self updateCache:key data:data forType:type];
}

- (CacheDataType) getType:(NSString *)key
{
    CacheDataType type = FRIEND_CACHE;
    for (int i = FRIEND_CACHE; i <= NONE_CACHE; i++) {
        type = (CacheDataType) i;
        NSDictionary* dic = [self getCache:type];
        if ([dic objectForKey:key]) {
            return type;
        }
    }
    return NONE_CACHE;
}

- (void) clearCache:(CacheDataType)type
{
    NSMutableDictionary* dic = [self getCache:type];
    if (dic) {
        [dic removeAllObjects];
    }
}

- (void) clearAllCache
{
    CacheDataType type = FRIEND_CACHE;
    for (int i = FRIEND_CACHE; i <= NONE_CACHE; i++) {
        type = (CacheDataType) i;
        [self clearCache:type];
    }
}

- (void) clearCache:(NSString *)key type:(CacheDataType)type
{
    NSMutableDictionary* dic = [self getCache:type];
    if (dic) {
        [dic removeObjectForKey:key];
    }
}

- (NSString*) getKey:(NSDictionary *)data type:(CacheDataType)type
{
    CacheInfo* info = [self createCache:type];
    return [info getKey:data];
}

- (id) getCacheProperty:(NSString *)key keyPath:(NSString*) keypath forType:(CacheDataType)type
{
    CacheInfo* cache = [self getCache:key forType:type];
    return [cache valueForKey:keypath];
}

- (CacheInfo*) createCache:(CacheDataType) type
{
    CacheInfo* cache = nil;
    switch (type) {
        case FRIEND_CACHE:
            cache = [[FriendCache alloc] init];
            break;
        case RECENT_MSG_CACHE:
            cache = [[RecentRecordCache alloc] init];
            break;
        case GROUP_CACHE:
            cache = [[FriendGroupCache alloc] init];
            break;
        case APP_CACHE:
            cache = [[AppCache alloc] init];
            break;
        case APPCOMMENT_CACHE://应用评论
            cache = [[AppCommentCache alloc] init];
            break;
        case CROWD_CACHE:
            cache = [[CrowdCache alloc] init];
            break;
        case DISCUSSION_CACHE:
            cache = [[DiscussionCache alloc] init];
            break;
        case NOTICE_CACHE://通知信息
            break;
        case APP_REMIND_CACHE://应用提醒信息
            break;
        case CHAT_CACHE://聊天信息相关
            cache = [[ConversationCache alloc] init];
            break;
        case ACCOUNT_CACHE://账号信息
            break;
        case ZONE_CACHE:
            cache = [[ZoneCache alloc] init];
            break;
        default:
            break;
    }
    return cache;
}

- (void) bind:(NSString *)key keypath:(NSString *)keypath user:(id)user tag:(NSUInteger)tag forType:(CacheDataType)type block:(void (^)(id))block
{
    [self bind:key keypath:keypath user:user tag:tag forType:type block2:^(id old, id newer) {
        block(newer);
    }];
}

- (void) addBindCache:(id)user obj:(NSString*)value type:(CacheDataType)type
{
    __block BOOL isExist = NO;
    NSDictionary* dic = [NSDictionary dictionaryWithDictionary:bindCache_];
    NSMutableArray* del = [[NSMutableArray alloc] init];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KeyUnit* key_unit = (KeyUnit*)key;
        if (key_unit.key) {
            if ([key_unit.key isEqual:user]) {
                StaticBindUnit* v = (StaticBindUnit*)obj;
                if (v.type == type && [v.valueKVC isEqualToString:value]) {
                    isExist = YES;
                    *stop = YES;
                }
            }
        }else{
            [del addObject:key_unit];
        }
    }];
    if (!isExist) {
        KeyUnit* key_unit = [[KeyUnit alloc] init];
        key_unit.key = user;
        StaticBindUnit* v = [[StaticBindUnit alloc] init];
        v.type = type;
        v.valueKVC = value;
        [bindCache_ setObject:v forKey:key_unit];
    }
    [bindCache_ removeObjectsForKeys:del];
}

- (NSArray*) getBindCacheValue:(id)user
{
    NSMutableArray*  del = [[NSMutableArray alloc] init];
    NSMutableArray*  ret = [[NSMutableArray alloc] init];
    NSDictionary* dic = [NSDictionary dictionaryWithDictionary:bindCache_];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KeyUnit* k = (KeyUnit*)key;
        if (k.key) {
            if ([k.key isEqual:user]) {
                [ret addObject:obj];
                [del addObject:key];
            }
        }else{
            [del addObject:key];
        }
    }];
    [bindCache_ removeObjectsForKeys:del];
    return ret;
}

- (void) bind:(NSString *)key keypath:(NSString *)keypath user:(id)user tag:(NSUInteger)tag forType:(CacheDataType)type block2:(void (^)(id, id))block
{
    NSAssert(key, @"绑定的key值不能为空");
    if(key){
        CacheInfo* cache = [self getCache:key forType:type];
        if (!cache) {
            //当前没有找到要绑定的数据，则生成一个新的空数据
            cache = [self createCache:type];
            cache.key = key;
            [self addCache:cache key:key forType:type];
            [cache getExtraInfo:key];//进行数据获取
        }
        
        if ([cache respondsToSelector:NSSelectorFromString(keypath)]) {
            [ThreadContainer asyncInMainThread:^{
                block([cache valueForKeyPath:keypath], [cache valueForKeyPath:keypath]);//先返回数据
            }];
            [self addBindCache:user obj:key type:type];
            [cache bind:keypath tag:tag userClass:[user class] user:user block:block];
        }
    }

}

- (void) bindOnlyOnce:(NSString *)key keypath:(NSString *)keypath user:(id)user tag:(NSUInteger)tag forType:(CacheDataType)type block:(void (^)(id))block
{
    if (![self hasBind:key keypath:keypath tag:tag type:type user:user]) {
        [self bind:key keypath:keypath user:user tag:tag forType:type block:block];
    }
}

- (void) bindStatic:(Class)cls keypath:(NSString *)keypath user:(id)user tag:(NSUInteger)tag block:(void (^)(id))block
{
    NSString* key = [NSString stringWithFormat:@"%@_%@_%@_%d", NSStringFromClass(cls), keypath, NSStringFromClass([user class]), tag];
    
    StaticBindUnit* unit = [[StaticBindUnit alloc] init];
    unit.cls = cls;
    unit.keypath = keypath;
    unit.block = block;
    unit.user = user;
    unit.tag = tag;
    [staticBind_ setObject:unit forKey:key];
    
    id v = objc_msgSend(cls, NSSelectorFromString(keypath));
    [self runStaticPropertyBindBlock:cls keypath:keypath newer:v];//将当前值callback返回
}

- (void) reBind4AllProperty:(CacheDataType) type
{
    NSArray* array = [[allPropertyBind_ allValues] copyNewArray];
    for (StaticBindUnit* unit in array) {
        if (unit.type == type) {
            [self bind:unit.keypath type:type valueKVC:unit.valueKVC block:unit.block];
        }
    }
}

- (void) bind:(NSString *)keypath type:(CacheDataType)type valueKVC:(NSString *)valueKVC block:(void (^)(id))block
{
    static NSObject* obj = nil;
    if (!obj) {
        obj = [NSObject new];
    }
    
    [self unbind:obj];
    
    NSString* k = [NSString stringWithFormat:@"%@_%d", keypath, type];
    StaticBindUnit* unit = [[StaticBindUnit alloc] init];
    unit.keypath = keypath;
    unit.block = block;
    unit.type = type;
    unit.valueKVC = valueKVC;
    [allPropertyBind_ setObject:unit forKey:k];

    NSArray* caches = [[self getCache:type] allValues];
    
    NSArray* allCachesCopy = [caches copyNewArray];
    for (CacheInfo* cache in allCachesCopy) {
        [self bind:cache.key keypath:keypath user:obj tag:cache.tag forType:type block2:^(id old, id newer) {
            id ret = [caches valueForKeyPath:valueKVC];
            block(ret);
        }];
    }
}

- (void) bindCache:(NSString *)key keypath:(NSString *)keypath user:(id)user tag:(NSUInteger)tag forType:(CacheDataType)type block:(void (^)(id, CacheInfo*))block
{
    [self bind:key keypath:keypath user:user tag:tag forType:type block:^(id newer) {
        CacheInfo* cache = [self getCache:key forType:type];
        block(newer, cache);
    }];
}

- (BOOL) hasBind:(NSString *)key keypath:(NSString*) keypath tag:(NSUInteger)tag type:(CacheDataType)type user:(id) user
{
    CacheInfo* cache = [self getCache:key forType:type];
    if (cache) {
        return [cache hasBind:keypath tag:tag userClass:[user class] user:user];
    }else{
        return NO;
    }
}

- (void) unbindInCache:(NSDictionary*) cache user:(id)user
{
    if (cache) {
        NSDictionary* newCache = [NSDictionary dictionaryWithDictionary:cache];
        [newCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            CacheInfo* c = (CacheInfo*) obj;
            [c unbind:user];
        }];
    }
}

- (void) unbind:(id)user
{
    if (!user) {
        return;
    }
    
    NSArray* arr = [[self getBindCacheValue:user] copyNewArray];
    
    for (StaticBindUnit* unit in arr) {
        NSDictionary* map = [self getCache:unit.type];
        CacheInfo* cache = [map objectForKey:unit.valueKVC];
        [cache unbind:user];
    }
}

- (void) unbindAllNull
{
    [ThreadContainer asyncInBackgroundThread:^{
        CacheDataType type = FRIEND_CACHE;
        for (int i = FRIEND_CACHE; i <= NONE_CACHE; i++) {
            type = (CacheDataType) i;
            NSDictionary* newCache = [NSDictionary dictionaryWithDictionary:[self getCache:type]];
            [newCache enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                CacheInfo* c = (CacheInfo*) obj;
                [c unbindAllNull];
            }];
        }
    }];
}

- (void) runStaticPropertyBindBlock:(Class)cls keypath:(NSString *)keypath newer:(id)newer
{
    [[staticBind_ copy] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        StaticBindUnit* unit = (StaticBindUnit*)obj;
        if ([unit.keypath isEqualToString:keypath] && unit.cls == cls) {
            [ThreadContainer asyncInMainThread:^{
                unit.block(newer);
            }];
        }
    }];
}

@end
