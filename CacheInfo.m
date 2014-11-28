//
//  CacheInfo.m
//  LayoutFramework
//
//  Created by liuke on 14-3-27.
//  Copyright (c) 2014年 liuke. All rights reserved.
//

#import "CacheInfo.h"
#import "Bind.h"
#import <objc/runtime.h>
#import "PropertyJsonMap.h"
#import "NSDictionary+Json.h"


@interface CacheInfo()

@property (nonatomic, strong) Bind* bind;

@end

@implementation CacheInfo

- (id) init
{
    self = [super init];
    if (self) {
        [self initProperty:self];
        self.bind = [[Bind alloc] initWithObserver:self];
        static NSUInteger tag_ = 0;
        self.tag = tag_ ++;
        FILTER_LOG_THIS_FILE
    }
    return self;
}


- (void) bind:(NSString *)keypath tag:(NSUInteger)tag userClass:(Class)cls user:(id) user block:(void (^)(id, id))block
{
    if([self respondsToSelector:NSSelectorFromString(keypath)]){
        [self.bind observe:self keyPath:keypath tag:tag userClass:cls user:user block:block];
    }
}

- (BOOL) unbind:(NSString *)keypath tag:(NSUInteger)tag userClass:(Class)cls user:(id) user
{
    [self.bind unobserve:self keyPath:keypath tag:tag userClass:cls user:user];
    return YES;
}

- (void) unbind:(id) user
{
    [self.bind unobserve: user];
}

- (void) unbindAllNull
{
    [self.bind unobserveAllNull];
}

- (BOOL) hasBind:(NSString *)keyPath tag:(NSUInteger)tag userClass:(Class)cls user:(id)user
{
    return [self.bind hasBind:self keyPath:keyPath tag:tag userClass:cls user:user];
}

- (BOOL) isExistProperty:(NSString*) keypath
{
    objc_property_t p = class_getProperty([self class], [keypath cStringUsingEncoding:NSUTF8StringEncoding]);
    if (p == NULL) {
        return NO;
    }
    return YES;
}
//得到属性的类型，目前只支持NSString和NSNumber
- (Class) getPropertyClassType:(NSString*) property
{
    return [self getPropertyClassType:self property:property];
}

//得到属性的类型，目前只支持NSString和NSNumber
- (Class) getPropertyClassType:(id) obj property:(NSString*) property
{
    objc_property_t p = class_getProperty([obj class], [property cStringUsingEncoding:NSUTF8StringEncoding]);
    const char * attributes = property_getAttributes(p);//获取属性类型
    NSString* type = [NSString stringWithUTF8String:attributes];
    //    NSLog(@"%@ range:%d", type, [type rangeOfString:@"NSString"].location);
    if ([type rangeOfString:@"NSString"].location != NSNotFound) {
        return [NSString class];
    }else if ([type rangeOfString:@"NSNumber"].location != NSNotFound){
        return [NSNumber class];
    }else if ([type rangeOfString:@"Array"].location != NSNotFound){
        return [NSArray class];
    }else if ([type rangeOfString:@"Dictionary"].location != NSNotFound){
        return [NSDictionary class];
    }

    return nil;
}

- (void) setProperty:(NSString*) property value:(id) value
{
    if (!value || [[NSNull null] isEqual:value]) {
        return;
    }
    BOOL exist = [self isExistProperty:property];
    NSAssert(exist, @"在类 %@ 中不存在属性：%@", self, property);
    if (exist) {
        //赋值存在，则直接赋值
        Class cls = [self getPropertyClassType:property];
        DDLogVerbose(@"%@的类型为：%@", property, cls);
        NSAssert(cls, @"%@类中%@实际类型：%@，期望类型：%@，json数据中得到的数据类型和类属性中定义的类型不匹配，请检查", self, property, [value class], cls);
        if(cls && [value isKindOfClass: cls]){
            if ([self isValueLegal:value]) {//值合法
                if (![[self valueForKeyPath:property] isEqual:value]) {
                    [self setValue:value forKeyPath:property];
                }
            }else{
                id defalut = [value copy];//判断是否需要默认值
                if ([self isNeedDefalutValue:property default:&defalut]) {
                    if (![[self valueForKeyPath:property] isEqual:value]) {
                        [self setValue:value forKeyPath:property];
                    }
                }else{
                    if (![[self valueForKeyPath:property] isEqual:value]) {
                        [self setValue:value forKeyPath:property];
                    }                }
            }
        }else if(cls && (cls == [NSString class] && [value isKindOfClass:[NSNumber class]])){
            [self setValue:[NSString stringWithFormat:@"%@", value] forKeyPath:property];
        }else if(cls && (cls == [NSNumber class] && [value isKindOfClass:[NSString class]])){
            if ([@"true" isEqualToStringIgnoreCase:value]) {
                [self setValue:@1 forKeyPath:property];
            }else if ([@"false" isEqualToStringIgnoreCase:value]){
                [self setValue:@0 forKeyPath:property];
            }else{
                [self setValue:@([value floatValue]) forKeyPath:property];
            }
        }else if (cls && (cls == [NSString class]) && [value isKindOfClass:[NSDictionary class]]){
            [self setValue:[value toString] forKey:property];
        }else if (cls && (cls == [NSDictionary class]) && [value isKindOfClass:[NSString class]]){
            [self setValue:[value toDictionary] forKey:property];
        }else{
            LOG_NETWORK_WARNING(@"%@类中%@的值为：%@实际类型：%@，期望类型：%@，json数据中得到的数据类型和类属性中定义的类型不匹配，请检查", self, property, value, [value class], cls);
        }
    }
}

- (NSString*) map:(NSString *)json_key
{
    return [PropertyJsonMap map:json_key];
}

- (NSDictionary*) getDotMap
{
    return [PropertyJsonMap getDotMap];
}

//判断一个值是否是合法值
- (BOOL) isValueLegal:(id) value
{
    if (value || ![[NSNull null] isEqual:value]) {
        return YES;
    }
    return NO;
}

- (BOOL) isNeedDefalutValue:(NSString*) property default:(id*) value;
{
    return NO;
}

- (void) fromDictionary:(NSDictionary *)dic
{
    //首先使用a.b方式得到值
    NSDictionary* dot = [self getDotMap];
    [dot enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* value = [dic objectForDotKeypath:key];
        if(value){
            [self setProperty:obj value:value];
        }
    }];
    
    __weak CacheInfo* _wself = self;
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* keypath = nil;
        keypath = [self map:key];
//        NSAssert(keypath, @"没有找到 %@--->%@ 的映射关系，请确定是否需要处理.这个断言最后需要注释掉", key, keypath);
        if (keypath) {
            if ([[CacheInfo __key__] isEqualToString: keypath]) {
                if (!self.key || [@"" isEqualToString:self.key]) {
                    self.key = obj;
                }
            }else{
                if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                    [_wself setProperty:keypath value:obj];
                }else if([obj isKindOfClass:[NSArray class]]){
                    [_wself setProperty:keypath value:obj];
                }else if([obj isKindOfClass:[NSDictionary class]]){
                    [_wself setProperty:keypath value:obj];
                }
            }
        }
    }];
}

- (NSString*) getKey:(NSDictionary*) dic
{
    __block NSString* ret = nil;
    
    //首先使用a.b方式得到值
    NSMutableDictionary* dot = [[NSMutableDictionary alloc] init];
    [dot setDictionary:[PropertyJsonMap getDotMap]];
    [dot addEntriesFromDictionary:[self getDotMap]];
    [dot enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([[CacheInfo __key__] isEqualToString:obj]) {
            NSString* value = [dic valueForKeyPath:key];
            ret = value;
            *stop = YES;
        }
    }];
    
    if (ret) {
        return ret;
    }
    
    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString* keypath = [self map:key];
        if (!keypath) {
            keypath = [PropertyJsonMap map:key];
        }
        if (keypath) {
            if ([[CacheInfo __key__] isEqualToString: keypath]) {
                ret = obj;
                *stop = YES;
            }
        }
    }];
    return ret;
}

- (void) getExtraInfo:(NSString *)key
{
    
}

- (void) initProperty:(id) obj
{
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList([obj class], &outCount);
    for (int i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        const char* char_f = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        Class cls = [self getPropertyClassType:obj property:propertyName];
        if (cls == [NSString class]) {
            [obj setValue:@"" forKey:propertyName];
        }else if(cls == [NSNumber class]){
            [obj setValue:@(0) forKey:propertyName];
        }else if (cls == [NSArray class]){
            [obj setValue:[NSMutableArray new] forKey:propertyName];
        }else if (cls == [NSDictionary class]){
            [obj setValue:[NSMutableDictionary new] forKey:propertyName];
        }
    }
    free(properties);
}

+ (NSMutableDictionary*) deepMutableCopy:(NSDictionary *)dic
{
    CFPropertyListRef p = CFPropertyListCreateDeepCopy(NULL, (__bridge CFPropertyListRef)(dic), kCFPropertyListMutableContainersAndLeaves);
    NSMutableDictionary* ret = (__bridge  NSMutableDictionary*)p;
    CFBridgingRelease(p);
    return ret;
}

#pragma -- mark 动态添加类

+ (BOOL) resolveClassMethod:(SEL)sel
{
    NSString* selector = NSStringFromSelector(sel);
    if ([selector hasPrefix:@"__"] && [selector hasSuffix:@"__"]) {
        
        NSString *classname = NSStringFromClass([self class]);
        Class ourClass = object_getClass(NSClassFromString(classname));
        NSString* ret = [selector substringWithRange:NSMakeRange(2, selector.length - 4)];
        NSString*(^block)(id, IMP) = ^(id self, IMP imp){
            return ret;
        };
        IMP imp = imp_implementationWithBlock(block);
        class_addMethod(ourClass, sel, imp, "@@:");
        return YES;
    }
    
    return [super resolveClassMethod:sel];
}

@end
