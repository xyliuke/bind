//
//  CacheContainer.h
//  LayoutFramework
//
//  Created by liuke on 14-3-27.
//  Copyright (c) 2014年 liuke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CacheInfo.h"


/**
 *  Cache的容器类，单例对象
 */
@interface CacheContainer : NSObject

SINGLETON_DEFINE(CacheContainer)

/**
 *  向Cache容器中添加好友信息的数据类,如果对应的数据已经存在，则可能造成不可预知的后果。
 *  所以最好的使用方式是首先使用getCache:forType去查找盲该值是否存在，不存在再添加
 *
 *  @param info 好友数据类
 *  @param key  唯一标识，为jid
 */
- (void) addCache:(id) info key:(NSString*) key forType:(CacheDataType) type;

/**
 *  通过key获取好友信息
 *
 *  @param key 好友的唯一标识
 *
 *  @return 返回好友的数据对象
 */
- (CacheInfo*) getCache:(NSString*) key forType:(CacheDataType) type;

/**
 *  在所有cache中查找数据
 *
 *  @param key key值
 *
 *  @return 
 */
- (CacheInfo*) getCacheByKey:(NSString *)key;

/**
 *  更新数据，如果数据的key已经存在，则将原有的值进行更新，如果值不存在，则创建一个新的cache对象
 *
 *  @param key  对象的key值
 *  @param data json数据
 *  @param type cache的类型
 *
 *  @return 返回cache的对象
 */
- (CacheInfo*) updateCache:(NSString*) key data:(NSDictionary*) data forType:(CacheDataType) type;
/**
 *  直接通过数据更新，key值是通过数据得到，功能与updateCache一样
 *
 *  @param data json数据
 *  @param type cache的类型
 *
 *  @return 返回cache的对象
 */
- (CacheInfo*) updateCache:(NSDictionary*) data forType:(CacheDataType) type;
/**
 *  直接更新一个数组的json对象
 *
 *  @param data json数据的数组
 *  @param type cache的类型
 *
 *  @return 返回cache的对象的数组
 */
- (NSArray*) updateCacheByArray:(NSArray*) data forType:(CacheDataType) type;

- (CacheInfo*) updateCacheNoKey:(NSDictionary *)data forType:(CacheDataType)type;

/**
 *  根据key值遍历所有cache,查询该key属于那种类型的cache
 *
 *  @param key
 *
 *  @return
 */
- (CacheDataType) getType:(NSString*) key;
/**
 *  清空某种类型的cache
 *
 *  @param type 类型
 */
- (void) clearCache:(CacheDataType) type;
/**
 *  清空所有cache数据
 */
- (void) clearAllCache;
/**
 *  删除指定的key和类型的数据
 *
 *  @param key
 *  @param type 
 */
- (void) clearCache:(NSString*) key type:(CacheDataType) type;

- (NSString*) getKey:(NSDictionary*) data type:(CacheDataType) type;

/**
 *  将当前的一个属性与cache层的一个属性绑定。将通过key值找到的类中value属性与target进行绑定, block中是更新后的新值
 *
 *  @param key     需要绑定来源的key值，一般是cache中的key等唯一标识
 *  @param keypath 通过key值找到的对象中的绑定属性
 *  @param user    使用者的对象，这里需要注意一个对象中不能存在循环使用同一tag和key、keypath
 *  @param tag     一个标识，用于区分是否被循环绑定
 *  @param type    绑定类型
 *
 *  @return 绑定成功返回YES、如果当前key对应的cacheinfo对象不存在，则返回NO，返回NO时需要获取key对应的数据
 */
- (void) bind:(NSString*) key keypath:(NSString*) keypath user:(id) user tag:(NSUInteger)tag forType:(CacheDataType) type block:(void(^)(id newer)) block;

- (void) bind:(NSString*) key keypath:(NSString*) keypath user:(id) user tag:(NSUInteger)tag forType:(CacheDataType) type block2:(void(^)(id old, id newer)) block;

- (void) bindOnlyOnce:(NSString*) key keypath:(NSString*) keypath user:(id) user tag:(NSUInteger)tag forType:(CacheDataType) type block:(void(^)(id newer)) block;

- (void) bindStatic:(Class) cls keypath:(NSString*) keypath user:(id) user tag:(NSUInteger)tag block:(void(^)(id newer)) block;
/**
 *  绑定某种cache中的某种属性的变化
 *
 *  @param keypath <#keypath description#>
 *  @param type    <#type description#>
 */
- (void) bind:(NSString*) keypath type:(CacheDataType) type valueKVC:(NSString*)valueKVC block:(void(^)(id)) block;

/**
 *  将当前的一个属性与cache层的一个属性绑定。将通过key值找到的类中value属性与target进行绑定, block中是更新后的新值和key对应的CacheInfo对象
 *
 *  @param key          需要绑定来源的key值，一般是cache中的key等唯一标识
 *  @param keypath      通过key值找使用者的对象，这里需要注意一个对象中不能存在循环使用同一tag和key、keypath到的对象中的绑定属性
 *  @param user         使用者的对象，这里需要注意一个对象中不能存在循环使用同一tag和key、keypath
 *  @param tag          一个标识，用于区分是否被循环绑定
 *  @param type         绑定类型
 *
 *  @return 绑定成功返回YES、如果当前key对应的cacheinfo对象不存在，则返回NO，返回NO时需要获取key对应的数据
 */
- (void) bindCache:(NSString*) key keypath:(NSString*) keypath user:(id) user tag:(NSUInteger)tag forType:(CacheDataType) type block:(void(^)(id newer, CacheInfo* extra)) block;
/**
 *  将所有tag的绑定进行解绑
 *
 *  @param user 解绑定使用者
 *
 */
- (void) unbind:(id) user;

- (void) unbindAllNull;

/**
 *  执行静态绑定的block
 *
 *  @param newer 最新的值
 */
- (void) runStaticPropertyBindBlock:(Class) cls keypath:(NSString*) keypath newer:(id) newer;


@end
