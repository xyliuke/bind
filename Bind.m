//
//  Bind.m
//  LayoutFramework
//
//  Created by liuke on 14-3-13.
//  Copyright (c) 2014年 liuke. All rights reserved.
//

#import "Bind.h"
#import "FBKVOController.h"
#import <objc/runtime.h>
#import "CacheInfo.h"
#import "NSArray+copy.h"
#import "ThreadContainer.h"

@implementation KeyUnit

- (id)copyWithZone:(NSZone *)zone
{
    KeyUnit *result = [[[self class] allocWithZone:zone] init];
    result.pre_keyunit = self;
    result.key = self.key;
    return result;
}
@end

@interface BindUnit : NSObject
@property (nonatomic, strong) void(^block)(id, id);
@property (nonatomic) NSUInteger tag;//标识位
@property (nonatomic, strong) NSString* key;//绑定key
@property (nonatomic, strong) NSString* keypath;//绑定的keypath
@property (nonatomic) Class class_;//使用者的类名
@property (nonatomic, weak) id user;//使用者的对象
@end
@implementation BindUnit

- (BOOL) isEqual:(id)object
{
    BindUnit* b = (BindUnit*)object;
    if (!self.user) {
        self.block = nil;
        return NO;
    }
    if (self.tag == b.tag && (self.key && [self.key isKindOfClass:[NSString class]] && [self.key isEqualToString:b.key]) && (self.keypath && [self.keypath isKindOfClass:[NSString class]] && [self.keypath isEqualToString:b.keypath]) && self.class_ == b.class_ && [self.user isEqual:b.user]) {
        return YES;
    }
    return NO;
}
@end


@interface Bind()
{
    FBKVOController* fb;
    NSMutableDictionary* observeMap_;
    NSMutableDictionary* observeMapValue_;
}

@end

@implementation Bind


- (id) initWithObserver:(id)observer
{
    self = [super init];
    if (self) {
        fb = [[FBKVOController alloc] initWithObserver:observer];
        observeMap_ = [NSMutableDictionary dictionary];
        FILTER_LOG_THIS_FILE
    }
    return self;
}

- (KeyUnit*) CreateWarpper:(id)user
{
    KeyUnit* k = [[KeyUnit alloc] init];
    k.key = user;
    return k;
}

- (KeyUnit*) getWarpper:(id)user
{
    NSMutableArray* delKeys = [NSMutableArray new];
    __block KeyUnit* ret = nil;
    NSDictionary* dic = [NSDictionary dictionaryWithDictionary:observeMap_];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KeyUnit* k = (KeyUnit*)key;
        if ([k isKindOfClass:[KeyUnit class]]) {
            if ([k.key isEqual:user]) {
                ret = key;
                *stop = YES;
            }
            if (!k.key) {
                [delKeys addObject:k.pre_keyunit];
            }
        }
    }];
    [observeMap_ removeObjectsForKeys:delKeys];
    return ret;
}

- (NSMutableArray*) getValuesByKey:(id)user
{
    NSMutableArray* delKeys = [NSMutableArray new];
    __block NSMutableArray* ret = nil;
    NSDictionary* dic = [NSDictionary dictionaryWithDictionary:observeMap_];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KeyUnit* k = (KeyUnit*)key;
        if ([k isKindOfClass:[KeyUnit class]]) {
            if ([k.key isEqual:user]) {
                NSLog(@"obj:%@",obj);
                ret = obj;
                *stop = YES;
            }
            if (!k.key) {
                [delKeys addObject:k.pre_keyunit];
            }
        }
    }];
    [observeMap_ removeObjectsForKeys:delKeys];
    return ret;
}

- (void) removeKeyAndValue:(id)user
{
    NSMutableArray* delKeys = [NSMutableArray new];
    NSDictionary* dic = [NSDictionary dictionaryWithDictionary:observeMap_];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KeyUnit* k = (KeyUnit*)key;
        if ([k isKindOfClass:[KeyUnit class]]) {
            if (!k.key) {
                [delKeys addObject:k.pre_keyunit];
            }else if ([user isEqual:k.key]) {
                [delKeys addObject:k.pre_keyunit];
            }
        }
    }];
    [observeMap_ removeObjectsForKeys:delKeys];
}

- (void) removeAllNullKeys
{
    NSMutableArray* delKeys = [NSMutableArray new];
    NSDictionary* dic = [NSDictionary dictionaryWithDictionary:observeMap_];
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        KeyUnit* k = (KeyUnit*)key;
        if ([k isKindOfClass:[KeyUnit class]]) {
            if (!k.key) {
                [delKeys addObject:k.pre_keyunit];
            }
        }
    }];
    [observeMap_ removeObjectsForKeys:delKeys];
}

/**
 *  将对同一个属性的所有监听事件保存在一个字典中，其中字典的key是监听的种类，一般是类名+属性名拼接，
 *  字典中的value是一个NSMutableArray的数组，数据中保存所有的block
 *
 *  @param key   监听的种类值
 *  @param block 监听事件的block
 *  @return 如果当前添加这个种类的监听是第一个，则返回YES，否则返回NO
 */
- (BOOL) add2MultiObserve: (NSString*) key keypath:(NSString*) keypath tag:(NSUInteger) tag userClass:(Class) cls user:(id) user block:(void (^)(id old, id newer))block
{
    NSMutableArray* ht = [self getValuesByKey:user];
    if (ht) {
        NSArray* copy = [ht copyNewArray];
        BindUnit* unit = [[BindUnit alloc] init];
        unit.block = block;
        unit.tag = tag;
        unit.class_ = cls;
        unit.key = key;
        unit.keypath = keypath;
        unit.user = user;
        if (![copy containsObject:unit]) {
            [ht addObject:unit];
            return YES;
        }else{
            [copy enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([unit isEqual:obj]) {
                    BindUnit* b = (BindUnit*)obj;
                    b.block = block;
                    *stop = YES;
                }
            }];
        }
        return NO;
    }else{
        ht = [[NSMutableArray alloc] init];
        BindUnit* unit = [[BindUnit alloc] init];
        unit.block = block;
        unit.tag = tag;
        unit.class_ = cls;
        unit.key = key;
        unit.keypath = keypath;
        unit.user = user;
        [ht addObject:unit];
        KeyUnit* ku = [self CreateWarpper:user];
        [observeMap_ setObject:ht forKey:ku];
        return YES;
    }
}

- (void) sendMultiObserveBlock:(id) user keypath:(NSString*)keypath old:(id)old value:(id) value
{
    NSArray* val = [observeMap_ allValues];
    NSArray* values = [val copyNewArray];
    [values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (obj && [obj isKindOfClass:[NSArray class]]) {
            NSArray* v = [obj copyNewArray];
            [ThreadContainer asyncInMainThread:^{
                for (BindUnit* unit in v) {
                    if ([keypath isEqualToString:unit.keypath]) {
                        if (unit.user) {
                            unit.block(old, value);
                        }else{
                            unit.block = nil;
                        }
                    }
                }
            }];
        }
    }];
}


- (void) observe:(id)object keyPath:(NSString *)keyPath tag:(NSUInteger)tag userClass:(Class)cls user:(id) user block:(void (^)(id, id))block
{
    [ThreadContainer asyncInBackgroundThread:^{
        CacheInfo* c = object;
        __weak id u = user;
        if ([self add2MultiObserve:c.key keypath:keyPath tag:tag userClass:cls user:u block:block]) {
            //注册监听
            [fb observe: object
                keyPath: keyPath
                options: NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
             | NSKeyValueChangeInsertion | NSKeyValueChangeRemoval | NSKeyValueChangeReplacement
                  block:^(id observer, id object, NSDictionary *change) {
                      id old = [change objectForKey:@"old"];
                      id newer = [change objectForKey:@"new"];
                      if ([old isEqual:newer]) {
                          
                      }else{
                          [self sendMultiObserveBlock:u keypath:keyPath old:old value:newer];
                      }
                  }];
        }
    }];
}

- (void) unobserve:(id)object keyPath:(NSString *)keyPath tag:(NSUInteger)tag userClass:(Class)cls user:(id) user
{
    NSMutableArray* values = [self getValuesByKey:user];//[observeMap_ objectForKey:user];
    if (!values && ![values isKindOfClass:[NSArray class]]) {
        return;
    }
    NSArray* array = [values copyNewArray];
    NSMutableArray* del = [[NSMutableArray alloc] init];
    for (BindUnit* unit in array) {
        if (unit.tag == tag && unit.class == cls && [unit.user isEqual:user] && [unit.keypath isEqualToString:keyPath]) {
            [del addObject:unit];
        }
    }
    
    [values removeObjectsInArray:del];
}


- (void) unobserve:(id) user
{
    if (user) {
        [self removeKeyAndValue:user];
    }
}

- (void) unobserveAllNull
{
    [self removeAllNullKeys];
}

- (BOOL) hasBind:(id)object keyPath:(NSString *)keyPath tag:(NSUInteger)tag userClass:(Class)cls user:(id)user
{
    NSArray* array = [self getValuesByKey:user];
    if (!array) {
        return NO;
    }
    array = [array copyNewArray];
    BindUnit* unit = [[BindUnit alloc] init];
    unit.tag = tag;
    unit.class_ = cls;
    unit.key = ((CacheInfo*)object).key;
    unit.keypath = keyPath;
    unit.user = user;
    return [array containsObject: unit];
}

@end
