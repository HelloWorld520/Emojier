//
//  SMEmojiTotalInfo.m
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/13.
//  Copyright © 2015 Sam. All rights reserved.
//

#import "KCLocalEmojiTotalInfo.h"


@interface KCLocalEmojiTotalInfo()
@property (nonatomic, strong) NSDictionary * emojiDict;
@end

@implementation KCLocalEmojiTotalInfo

- (NSDictionary *)emojiDict{
    if (_emojiDict == nil) {
        _emojiDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"emojiTotalData.plist" ofType:nil]];
    }
    return _emojiDict;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.activity = [KCEmojiModel categoryArrayWithEmojiDataArray:self.emojiDict[@"activity"]];
        self.nature = [KCEmojiModel categoryArrayWithEmojiDataArray:self.emojiDict[@"nature"]];
        self.food_drinks = [KCEmojiModel categoryArrayWithEmojiDataArray:self.emojiDict[@"food&drinks"]];
        self.objects = [KCEmojiModel categoryArrayWithEmojiDataArray:self.emojiDict[@"objects"]];
        self.objects_symbols = [KCEmojiModel categoryArrayWithEmojiDataArray:self.emojiDict[@"objects&symbols"]];
        self.people = [KCEmojiModel categoryArrayWithEmojiDataArray:self.emojiDict[@"people"]];
        self.travel_places = [KCEmojiModel categoryArrayWithEmojiDataArray:self.emojiDict[@"travel&places"]];
    }
    return self;
}
@end
