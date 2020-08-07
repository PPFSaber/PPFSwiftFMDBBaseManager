//
//  NSString+Json.h
//  PPFSwiftFMDBBaseManager
//
//  Created by colinpian on 2020/8/7.
//  Copyright © 2020 com.PPFSwiftFMDBBaseManager.ppf. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Json)

/**
 string -> dic或者array
 
 @return dic或者array
 */
- (id)ppf_dictionaryOrArray;
@end

NS_ASSUME_NONNULL_END
