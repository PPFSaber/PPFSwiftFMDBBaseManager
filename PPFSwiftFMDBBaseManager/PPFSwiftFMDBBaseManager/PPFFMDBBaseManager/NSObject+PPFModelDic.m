//
//  NSObject+PPFModelDic.m
//  DTSimulate
//
//  Created by colinpian on 2020/7/31.
//  Copyright © 2020 PPF. All rights reserved.
//

#import "NSObject+PPFModelDic.h"
#import <YYModel/YYModel.h>
@implementation NSObject (PPFModelDic)
- (NSDictionary *)modelToDictionary
{
    NSString *jsonStr = [self yy_modelToJSONString];
    return [[self class] dictionaryWithJSON:jsonStr];
}


+ (NSDictionary *)dictionaryWithJSON:(id)json {
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding : NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}
@end
