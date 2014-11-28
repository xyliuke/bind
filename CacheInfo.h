//
//  CacheInfo.h
//  LayoutFramework
//
//  Created by liuke on 14-3-27.
//  Copyright (c) 2014年 liuke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSString+Util.h"


//定义属性xxx的宏，同时声明一个对应的__xxx__类函数来得到属性名
#define PROPERTY(TYPE, VAR, COMMENT) @property (nonatomic, strong) TYPE VAR; \
+(NSString*) __##VAR##__;
//定义NSString属性的宏
#define PROPERTY_STRING(VAR, COMMENT) PROPERTY(NSString*, VAR, COMMENT)
//定义NSNumber属性的宏
#define PROPERTY_NUMBER(VAR, COMMENT) PROPERTY(NSNumber*, VAR, COMMENT)
//定义NSArray类型属性的宏
#define PROPERTY_ARRAY(VAR, COMMENT) PROPERTY(NSMutableArray*, VAR, COMMENT)
//定义字典类型的宏
#define PROPERTY_DICTIONARY(VAR, COMMENT) PROPERTY(NSMutableDictionary*, VAR, COMMENT)

#define __DOT__ @"."

#define STATIC_PROPERTY_DEFINE(TYPE, VAR, COMMENT) + (TYPE) VAR; + (void) set##VAR:(TYPE) var; \
+(NSString*) __##VAR##__;

#define STATIC_PROPERTY_IMPL(CLASS, TYPE, VAR, COMMNET) static TYPE _##VAR;  + (TYPE) VAR{return _##VAR;} + (void) set##VAR:(TYPE)xxx{_##VAR = xxx; \
[[CacheContainer shareInstance] runStaticPropertyBindBlock:NSClassFromString([NSString stringWithUTF8String:#CLASS]) keypath:[NSString stringWithUTF8String:#VAR] newer:xxx];} 

#define STATIC_PROPERTY_NUMBER_DEFINE(VAR, COMMENT) STATIC_PROPERTY_DEFINE(NSNumber*, VAR, COMMENT)
#define STATIC_PROPERTY_NUMBER_IMPL(CLASS, VAR, COMMNET) STATIC_PROPERTY_IMPL(CLASS, NSNumber*, VAR, COMMNET)

/**
 *  cache数据的分类，尽量保持数据不冗余
 */
typedef enum CacheDataType{
    FRIEND_CACHE,//好友信息
    GROUP_CACHE,//好友的分组
    CROWD_CACHE,//群信息
    DISCUSSION_CACHE,//讨论组信息
    RECENT_MSG_CACHE,//最近消息
    NOTICE_CACHE,//通知信息
    APP_REMIND_CACHE,//应用提醒信息
    APP_CACHE,//应用中心信息
    APPCOMMENT_CACHE,//应用评论
    CHAT_CACHE,//聊天信息相关
    ACCOUNT_CACHE,//账号信息
    ZONE_CACHE,//动态数据
    NONE_CACHE//设置一个无用的标识
} CacheDataType;

@class Bind;

@interface CacheInfo : NSObject

#pragma -- mark 数据封装

/**
 *  表示一个cache对象的唯一标识，一般是jid
 */
PROPERTY_STRING(key, "第一标识")
PROPERTY_STRING(subKey, "第二标识")

@property (nonatomic) NSUInteger tag;//作为一个自增1的对象计数存在
/**
 *  数据类型
 */
@property (nonatomic) CacheDataType cacheType;


#pragma -- mark 绑定相关

- (void) bind:(NSString *)keypath tag:(NSUInteger) tag userClass:(Class) cls user:(id) user block:(void (^)(id old, id newer))block;

- (BOOL) unbind:(NSString *)keypath tag:(NSUInteger) tag userClass:(Class) cls user:(id) user;

- (void) unbind:(id) user;

- (void) unbindAllNull;

- (BOOL) hasBind:(NSString *)keyPath tag:(NSUInteger)tag userClass:(Class)cls user:(id)user;

#pragma -- mark json解析

/**
 *  通过json的key值得到对应的类属性名，这个函数需要子类重写对应的映射关系。如果在这个关系中找不到，则再去PropertyJsonMap类中去找。
 *
 *  @param json_key json的key值
 *
 *  @return 返回对应的类属性名的字符串
 */
- (NSString*) map:(NSString*) json_key;

/**
 *  返回json中的依赖关系的key，比如a.b映射成a_b.这个函数需要子类重写对应的映射关系。如果在这个关系中找不到，则再去PropertyJsonMap类中去找。
 *
 *  @return 返回存在层级的映射关系表
 */
- (NSDictionary*) getDotMap;

/**
 *  判断这个属性是否需要默认值,这个函数需要根据情况被子类重写
 *
 *  @param property 属性名的字符串
 *  @param value    返回默认值
 *
 *  @return 当实际值不合法时需要默认值则返回YES
 */
- (BOOL) isNeedDefalutValue:(NSString*) property default:(id*) value;

/**
 *  将json转化成类属性
 *
 *  @param dic json转换成的字典
 */
- (void) fromDictionary:(NSDictionary*) dic;
/**
 *  获取key，因为一些json中可能没有key值，如好友组信息。这个方法需要各子类根据情况重写
 *
 *  @param dic
 *
 *  @return 返回key对应的值
 */
- (NSString*) getKey:(NSDictionary*) dic;

/**
 *  初始化类中的所有属性，NSString:@""; NSNumber:@(0); NSArray:@{}
 *
 *  @param obj 需要初始化的对象
 */
- (void) initProperty:(id) obj;

#pragma -- mark 去biz层获取自己相关的数据


/**
 *  用于获取额外数据时使用，通过对biz层或者网络进行数据获取，获取完成后添加到cachecontainer中
 *
 *  @param key 对key对应的cache数据进行获取
 */
- (void) getExtraInfo:(NSString*) key;

/**
 *  deep copy
 *
 *  @param dic
 *
 *  @return 
 */
+ (NSMutableDictionary*) deepMutableCopy:(NSDictionary*) dic;

// 判断此类是否还有keypath
- (BOOL) isExistProperty:(NSString*) keypath;
@end
