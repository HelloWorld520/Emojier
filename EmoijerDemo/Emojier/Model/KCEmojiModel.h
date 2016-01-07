//
//  KCEmojiModel.h
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/18.
//  Copyright © 2015 Sam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCEmojiModel.h"

#define RecentEmojiArrayMaxCount 7

typedef NS_ENUM(int,SMEmojiType) {
    SMEmojiTypeLocal = 0, // localEmoji
    SMEmojiTypeOnline // OnlineEmoji
};

typedef NS_ENUM(int,SMComeFrom) {
    SMComeFromNone = 0,
    SMComeFromRecent,
    SMComeFromTranslate
//    SMComeFromEscape // for \keyword
};


@class KCOnlinePropertyData;
@interface KCEmojiModel : NSObject


@property (nonatomic, assign) SMEmojiType emojiType;
@property (nonatomic, strong) NSString *emojiImageName;
@property (nonatomic, strong) NSString  *property_id; 
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSString *keyword;
@property (nonatomic, assign) SMComeFrom comeFrom;



+(instancetype)recentEmojiWithDict:(NSDictionary *)dict;
+(NSDictionary *)emojiModelWithEmoji:(id)emojiModel type:(SMEmojiType)emojiType;
+(instancetype)emojiModelWithOnlineProperty:(KCOnlinePropertyData *)propertyData;
+(NSArray *)categoryArrayWithEmojiDataArray:(NSArray *)emojiDataArray;

@end
