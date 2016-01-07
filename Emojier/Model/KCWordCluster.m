//
//  SMSpecialText.m
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/8.
//  Copyright © 2015 Sam. All rights reserved.
//

#import "KCWordCluster.h"
@interface KCWordCluster()<NSCopying>
@end
@implementation KCWordCluster

- (instancetype)copyWithZone:(NSZone *)zone {
    KCWordCluster *copy = [[[self class] allocWithZone:zone] init];
    copy.specialTextType = self.specialTextType;
    copy.shouldSendAsString = self.shouldSendAsString;
    copy.attributedStr = self.attributedStr;
    copy.normalTextRange = self.normalTextRange;
    copy.rangeBeforeTranslate = self.rangeBeforeTranslate;
    copy.link = self.link;
    return copy;
}
@end
