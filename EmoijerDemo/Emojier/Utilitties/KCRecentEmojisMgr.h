//
//  SMRecentEmojis.h
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/18.
//  Copyright © 2015 Sam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"
#import "KCEmojiModel.h"

@interface KCRecentEmojisMgr : NSObject

singleH(RecentEmojiMgr);
/**
 *  get the recent emojis array which contains Online and Local
 *
 */
- (NSArray *)recentEmojiModelArray;
/**
 * When User click an emoji or translate a word to a emoji, you can call this method to store it
 */
- (void)updateRecentEmojisWithResentEmoji:(KCEmojiModel *)recent withDict:(NSDictionary *)dict;

@end
