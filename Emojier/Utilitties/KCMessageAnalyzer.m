//
//  SMAttributedString.m
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/9.
//  Copyright © 2015 Sam. All rights reserved.
//

#import "KCMessageAnalyzer.h"
#import "KCPropertyManager.h"
#import "KCCache.h"
#import "KCOnlinePropertyData.h"
#import "RegexKitLite.h"
#import "KCWordCluster.h"

#define ShowFontSize 20
#define FontName @"SF UI Text Light"
@implementation KCMessageAnalyzer

+(NSMutableAttributedString *)attributedStringWithContentString:(NSString *)contentStr withMessageID:(NSString *)messageID withAttributedStr:(NSAttributedString *)sourceAttS withFontColor:(UIColor *)fontColor{
    
    if (contentStr.length == 0) {
        return nil;
    }
    KCCache *cache = [KCCache shareCache];
    CGSize size = ((NSValue *)[cache objectForKey:messageID]).CGSizeValue;
    // if size already exist 
    if (size.height) {
        return (NSMutableAttributedString *)sourceAttS;
    }
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] init];
    NSString * pattern = [NSString stringWithFormat:@"%@|%@",REGEX_Pattern_Local,REGEX_Pattern_Onlie];
    NSMutableArray * parts = [NSMutableArray array];
    [contentStr enumerateStringsMatchedByRegex:pattern usingBlock:^(NSInteger captureCount, NSString *const __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        if ((*capturedRanges).length == 0) return;
        KCWordCluster * textPart = [[KCWordCluster alloc] init];
        textPart.realContentText = (*capturedStrings).lowercaseString;
        textPart.normalTextRange = *capturedRanges;
        if ([(*capturedStrings) hasPrefix:@"#|"] && [(*capturedStrings) hasSuffix:@"|"]){
            textPart.specialTextType = SMSpecialTextTypeOnlineEmoji;
        }
        else if([(*capturedStrings) hasPrefix:@"#["] && [(*capturedStrings) hasSuffix:@"]"]){
            textPart.specialTextType = SMSpecialTextTypeLocalEmoji;
        }
        
        [parts addObject:textPart];
    }];
    
    [contentStr enumerateStringsSeparatedByRegex:pattern usingBlock:^(NSInteger captureCount, NSString *const __unsafe_unretained *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        if ((*capturedRanges).length == 0) return;
        KCWordCluster *part = [[KCWordCluster alloc] init];
        part.realContentText = *capturedStrings;
        part.normalTextRange = *capturedRanges;
        [parts addObject:part];
    }];
    [parts sortUsingComparator:^NSComparisonResult(KCWordCluster *part1, KCWordCluster *part2) {
        if (part1.normalTextRange.location > part2.normalTextRange.location) {
            // part1>part2
            return NSOrderedDescending;
        }
        return NSOrderedAscending;
    }];
    
    
    NSDictionary * attr = @{NSFontAttributeName :[UIFont fontWithName:FontName size:ShowFontSize],NSBaselineOffsetAttributeName:@8,NSForegroundColorAttributeName:fontColor};
    NSMutableArray *specials = [NSMutableArray array];
    
    
    NSString * link;
    NSMutableArray *totalPropertyIDArray = [NSMutableArray array];
    

    BOOL nowHeightCanCache = YES;
    for (KCWordCluster *part in parts ) {
        NSAttributedString *substr = nil;
        if (part.specialTextType == SMSpecialTextTypeLocalEmoji) { // LocalEmojis
            NSTextAttachment *attch = [[NSTextAttachment alloc] init];
            NSString * imageName;
                imageName = [[part.realContentText stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"]"]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"#["]];
               UIImage * image = [UIImage imageNamed:imageName];
            if (image) {
                attch.image = image;
                attch.bounds = CGRectMake(0, 0, 30, 30);
                substr = [NSAttributedString attributedStringWithAttachment:attch];
                KCWordCluster *s = [part copy];
                s.normalTextRange = NSMakeRange(attributedString.length, 1);
                s.link = link;
                [specials addObject:s];
                
            } else {
                substr = [[NSAttributedString alloc] initWithString:part.realContentText attributes:attr];
            }
        }
        else if (part.specialTextType == SMSpecialTextTypeOnlineEmoji) { // Online Emojis
            NSString *keywordAndID = [[part.realContentText stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"#|"]] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"|"]] ;
            int dividerIndex = (int)[keywordAndID rangeOfString:@"_"].location;
            NSString *keyword,*property_id;
            if (dividerIndex != NSNotFound && dividerIndex > 0) {
                keyword =  [keywordAndID substringToIndex:dividerIndex];
                if (dividerIndex + 1 < keywordAndID.length) {
                    property_id = [keywordAndID substringFromIndex:dividerIndex + 1];
                }
            }
            keyword = keyword ? keyword : @"";
            property_id = property_id ? property_id :@"";
            NSString *imageName = [NSString stringWithFormat:@"%@@2x.png",[property_id stringByReplacingOccurrencesOfString:@":" withString:@"*"]];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[ImageCachePath stringByAppendingPathComponent:imageName]]) {
                NSTextAttachment *attch = [[NSTextAttachment alloc] init];
                UIImage *sourceImage = [UIImage imageWithContentsOfFile:[ImageCachePath stringByAppendingPathComponent:imageName]];
                KCOnlinePropertyData *propertyData = [KCPropertyManager localRequestPropertyDataWithPropertyID:property_id];
                if (propertyData.link.length) {
                    link = propertyData.link;
                }
                if ([link hasPrefix:@"http:://"]){
                    link = [link stringByReplacingOccurrencesOfString:@"http:://" withString:@"http://"];
                }
                link = [link stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    
                if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:link]]) {
                    UIGraphicsBeginImageContextWithOptions(sourceImage.size, NO, 0);
                    [sourceImage drawAtPoint:CGPointZero];
                    NSString *text = @"●";
                    CGFloat ratio = sourceImage.size.width / 32;
                    CGFloat fontSize = 15 * ratio;
                    NSLog(@"%@=====size",NSStringFromCGSize(sourceImage.size));
                    NSDictionary *dict = @{
                                           NSFontAttributeName : [UIFont systemFontOfSize:fontSize],
                                           NSForegroundColorAttributeName : [UIColor orangeColor]
                                           };
                    [text drawAtPoint:CGPointMake(sourceImage.size.width - 8 * ratio, -6 * ratio) withAttributes:dict];
                    UIImage *newImage =  UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    attch.image = newImage;
                }
                else{
                    attch.image = sourceImage;
                }

                attch.bounds = CGRectMake(0, 0, 30, 30);
                substr = [NSAttributedString attributedStringWithAttachment:attch];

                KCWordCluster *s = [part copy];
                s.normalTextRange = NSMakeRange(attributedString.length, 1);
                s.link = link;
                [specials addObject:s];
            }else{
                [totalPropertyIDArray addObject:property_id];
                substr = [[NSAttributedString alloc] initWithString:keyword attributes:attr];
            }
        }
        else{
            substr = [[NSAttributedString alloc] initWithString:part.realContentText attributes:attr];
        }
        substr = substr ? substr : [[NSAttributedString alloc] initWithString:@"" attributes:attr];
        [attributedString appendAttributedString:substr];
    }
    
    
    if (totalPropertyIDArray) {
        nowHeightCanCache = NO;
        [KCPropertyManager onlineRequestPropertyDataWithPropertyArray:(NSArray *)totalPropertyIDArray];
    }
    
    if (specials.count) {
        [attributedString addAttribute:@"specials" value:specials range:NSMakeRange(0, 1)];
    }
    
    if (nowHeightCanCache) {
        CGSize contentSize = [attributedString boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width * 2 / 3, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin  context:nil].size;
        [cache setObject:[NSValue valueWithCGSize:contentSize] forKey:messageID];
    }
    return attributedString;
}

+(CGSize)sizeWithContent:(NSString *)content withMessageID:(NSString *)messageID withAttributedStr:(NSAttributedString *)sourceAttS{
    KCCache *cache = [KCCache shareCache];
    CGSize size = ((NSValue *)[cache objectForKey:messageID]).CGSizeValue;
    if (size.height) {
        return size;
    }
    NSAttributedString * attributedString = [KCMessageAnalyzer attributedStringWithContentString:content withMessageID:messageID withAttributedStr:sourceAttS withFontColor:[UIColor blackColor]];
    CGSize contentSize = [attributedString boundingRectWithSize:CGSizeMake([UIScreen mainScreen].bounds.size.width * 2 / 3 , MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin  context:nil].size;
    return contentSize;
}


@end
