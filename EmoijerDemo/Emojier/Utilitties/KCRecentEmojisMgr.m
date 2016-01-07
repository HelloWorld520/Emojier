//
//  SMRecentEmojis.m
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/18.
//  Copyright © 2015 Sam. All rights reserved.
//

#import "KCRecentEmojisMgr.h"
#import "KCPropertyManager.h"

@interface KCRecentEmojisMgr()
@property (nonatomic, strong) NSMutableArray *recentEmojiArray;
@property (nonatomic, strong) NSMutableArray *recentDictArray;
@end

@implementation KCRecentEmojisMgr
singleM(RecentEmojiMgr);

- (NSMutableArray *)recentEmojiArray{
    if (_recentDictArray.count == 0) {
       NSString *filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"recentEmojiArray.plist"];
        NSArray *temp = [NSArray arrayWithContentsOfFile:filePath];
        self.recentDictArray = [NSMutableArray arrayWithArray:temp];
        _recentEmojiArray = [NSMutableArray array];
        for (NSDictionary * dict in temp) {
            KCEmojiModel * recentEmoji = [KCEmojiModel recentEmojiWithDict:dict];
            [_recentEmojiArray addObject:recentEmoji];
        }
        if (_recentEmojiArray == nil) {
            _recentEmojiArray = [NSMutableArray array];
            _recentDictArray = [NSMutableArray array];
        }
    }
    return _recentEmojiArray;
}

- (void)updateRecentEmojisWithResentEmoji:(KCEmojiModel *)recent withDict:(NSDictionary *)dict{
    if (!recent || !dict) return;
    BOOL hasSameEmoji = NO;
    NSUInteger index = 0;
    for (KCEmojiModel * emoji in self.recentEmojiArray) {
        if ([emoji.emojiImageName isEqualToString:recent.emojiImageName]) {
            // if the two recentEmoji have same emojiImageName, we should get the old index ,delete it and insert the new one at index 0
            hasSameEmoji = YES;
            break;
        }
        index ++;
    }
    
    [[KCPropertyManager sharePropertyMgr] updateImageNameAndUseDateWithEmojiModel:recent];
    
    
    if (hasSameEmoji) {
        [self.recentEmojiArray removeObjectAtIndex:index];
        [self.recentDictArray removeObjectAtIndex:index];
    }
    
    [self.recentEmojiArray insertObject:recent atIndex:0];
    [self.recentDictArray insertObject:dict atIndex:0];
    
    if (self.recentEmojiArray.count > RecentEmojiArrayMaxCount) {
        [self.recentEmojiArray removeLastObject];
        [self.recentDictArray removeLastObject];
    }
    NSString * filePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"recentEmojiArray.plist"];
    [self.recentDictArray writeToFile:filePath atomically:YES];
}


- (NSArray *)recentEmojiModelArray{
    return [self.recentEmojiArray copy];
}


@end
