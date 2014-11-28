//
//  Bind.h
//  LayoutFramework
//
//  Created by liuke on 14-3-13.
//  Copyright (c) 2014年 liuke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyUnit : NSObject<NSCopying>
@property (nonatomic, weak) id key;
@property (nonatomic, weak) id pre_keyunit;
@end

@interface Bind : NSObject

/**
 *  生成一个观察对象
 *
 *  @param observer 接收者
 *
 *  @return Bind对象
 */
- (id) initWithObserver:(id) observer;

/**
 *  当有值更新后，会以block方式通知。block的参数是最新的值，只能使用对象，所以基本类型的对象的对应关系为：
 *  BOOL->NSNumber
 *  int->NSNumber
 *
 *  @param object   观察的值对象
 *  @param selector 观察值对象中的属性方法
 */
- (void) observe:(id)object keyPath:(NSString *)keyPath tag:(NSUInteger)tag userClass:(Class)cls user:(id) user block:(void (^)(id, id))block;

- (void) unobserve:(id)object keyPath:(NSString*) keyPath tag:(NSUInteger) tag userClass:(Class) cls user:(id) user;

- (void) unobserve:(id) user;

- (void) unobserveAllNull;

- (BOOL) hasBind:(id)object keyPath:(NSString *)keyPath tag:(NSUInteger)tag userClass:(Class)cls user:(id) user;

@end
