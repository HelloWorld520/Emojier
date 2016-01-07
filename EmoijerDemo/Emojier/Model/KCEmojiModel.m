//
//  KCEmojiModel.m
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/18.
//  Copyright © 2015 Sam. All rights reserved.
//

#import "KCEmojiModel.h"
#import "KCOnlinePropertyData.h"
#import "KCOnlineImageInfo.h"
#import <objc/runtime.h>

@implementation KCEmojiModel

+ (instancetype)recentEmojiWithDict:(NSDictionary *)dict{
    KCEmojiModel * recent = [[self alloc] initWithDict:dict];
    return recent;
}


- (instancetype)initWithDict:(NSDictionary *)dict{
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}
+(NSArray *)categoryArrayWithEmojiDataArray:(NSArray *)emojiDataArray{
    NSMutableArray * arrayM = [NSMutableArray array];
    for (NSDictionary * dict in emojiDataArray) {
        KCEmojiModel * categoryModel = [[KCEmojiModel alloc] initWithDict:dict];
        [arrayM addObject:categoryModel];
    }
    return (NSArray *)arrayM;
}


+(NSDictionary *)emojiModelWithEmoji:(id)emojiModel type:(SMEmojiType)emojiType{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    KCEmojiModel *emojiMd = (KCEmojiModel *)emojiModel;
    unsigned int outCount;
    Ivar *ivarList = class_copyIvarList([KCEmojiModel class], &outCount);
    for (int i = 0; i < outCount; i ++) {
        Ivar ivar = ivarList[i];
        const char *ivarName = ivar_getName(ivar);
        NSString *propertyName = [[NSString stringWithFormat:@"%s",ivarName] substringFromIndex:1];
        if([propertyName isEqualToString:@"emojiType"]){
            dict[propertyName] = @(emojiMd.emojiType);
        }
        else if([propertyName isEqualToString:@"comeFrom"]){
            dict[propertyName] = @(emojiMd.comeFrom);
        }
        else{
            SEL selector = NSSelectorFromString(propertyName);
            IMP imp = [emojiMd methodForSelector:selector];
            id (*func)(KCEmojiModel *,SEL,NSString *) = (void *)imp;
            id something = func(emojiMd,selector,propertyName);
            if (something != nil) {
                dict[propertyName] = (typeof(something))something;
            }
        }
    }
    
    free(ivarList);
    return dict;
}


+ (instancetype)emojiModelWithOnlineProperty:(KCOnlinePropertyData *)propertyData{
    KCEmojiModel * recent = [[KCEmojiModel alloc] init];
    recent.emojiType = SMEmojiTypeOnline;
    // @":" is not avaliable when name a file
    recent.emojiImageName = [propertyData.property_id stringByReplacingOccurrencesOfString:@":" withString:@"*"];
    recent.link = propertyData.link;
    recent.property_id = propertyData.property_id;
    recent.keyword = propertyData.keyword;
    return recent;
}


@end
