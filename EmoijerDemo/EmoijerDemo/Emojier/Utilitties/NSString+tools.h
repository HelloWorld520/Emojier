//
//  NSString+tools.h
//  EmoijerDemo
//
//  Created by Sam on 16/1/4.
//  Copyright © 2016年 Sam. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (tools)
-(BOOL)isChinese;
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
- (NSString *)md5String;
@end
