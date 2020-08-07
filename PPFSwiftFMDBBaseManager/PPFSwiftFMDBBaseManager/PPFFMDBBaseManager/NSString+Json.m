//
//  NSString+Json.m
//  PPFSwiftFMDBBaseManager
//
//  Created by colinpian on 2020/8/7.
//  Copyright © 2020 com.PPFSwiftFMDBBaseManager.ppf. All rights reserved.
//

#import "NSString+Json.h"

@implementation NSString (Json)

/**
 string -> dic或者array
 
 @return dic或者array
 */
- (id)ppf_dictionaryOrArray 
{
    
    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    
    if (jsonData)
    {
        id dicOrArray = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if ([dicOrArray isKindOfClass:[NSArray class]] ||
            [dicOrArray isKindOfClass:[NSDictionary class]])
        {
            return dicOrArray;
        }
    }
    
    return nil;
}

@end
