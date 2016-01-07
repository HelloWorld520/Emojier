//
//  KCTextTranslator.m
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/12/17.
//  Copyright © 2015 Sam. All rights reserved.
//

#import "KCTextTranslator.h"
#import "KCWordCluster.h"
#import "KCPropertyManager.h"
#import "MJExtension.h"
#import "KCOnlinePropertyData.h"
#import "NSString+tools.h"
#import "Colours.h"
#import "KCTextAttahment.h"
#import "KCEmojiModel.h"
#import "KCRecentEmojisMgr.h"
#define ShowFontSize 20
#define FontName @"SF UI Text Light"


@implementation KCTextTranslator
singleM(Translator);

+ (void)translateSourcAttributedStr:(NSAttributedString *)sourceAttrs normalStr:(NSString *)normalStr withHighlightColor:(UIColor *)highlightColor imageSize:(CGSize)imageSize translateOneTime:(BOOL)translateOneTime toDestionAttributedStr:(void (^)(NSAttributedString *, BOOL))result{
    
    __block NSMutableArray *tempEmojArray = [NSMutableArray array];
    [sourceAttrs enumerateAttributesInRange:NSMakeRange(0, sourceAttrs.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        KCTextAttahment *attatchment = attrs[@"NSAttachment"];
        KCWordCluster *normalTextPart  = [[KCWordCluster alloc] init];
        if (attatchment) {
            normalTextPart.shouldSendAsString = attatchment.text;
            normalTextPart.attributedStr = attatchment.attriburedStr;
            normalTextPart.rangeBeforeTranslate = range;
            normalTextPart.specialTextType = SMSpecialTextTypeLocalEmoji;
            [tempEmojArray addObject:normalTextPart];
        }
    }];
    
    __block int specialTextCount = 0;
    __block int lastRangeLocation = 0;
    __block NSMutableArray *textPartArrayToTranslate = [NSMutableArray array];
    __block BOOL isChinese = NO;
    [normalStr enumerateSubstringsInRange:NSMakeRange(0, normalStr.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        isChinese = substring.isChinese;
        *stop =YES;
    }];
    NSStringEnumerationOptions option = 0;
    if (isChinese) {
        option = NSStringEnumerationByComposedCharacterSequences;
    }
    else{
        option = NSStringEnumerationByWords;
    }
    [normalStr enumerateSubstringsInRange:NSMakeRange(0, normalStr.length) options:option usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
        
        if (substring.length == 0) return;
        if (substringRange.location > 0) {
            int deltaIndex = (int)(substringRange.location - lastRangeLocation);
            for (int idx = 0; idx < deltaIndex; idx ++) {
                int beforeIndex = lastRangeLocation + idx;
                unichar beforeChar = [normalStr characterAtIndex:beforeIndex];
                if (beforeChar == 0xfffc) {
                    KCWordCluster * textPart = tempEmojArray[specialTextCount];
                    textPart.rangeBeforeTranslate = NSMakeRange(beforeIndex, 1);
                    [textPartArrayToTranslate addObject:textPart];
                    specialTextCount ++;
                }
                else if(beforeChar == ' '){
                    KCWordCluster *spacePart  = [[KCWordCluster alloc] init];
                    spacePart.rangeBeforeTranslate = NSMakeRange(beforeIndex, 1);
                    spacePart.specialTextType = SMSpecialTextTypeSpace;
                    spacePart.realContentText = @" ";
                    [textPartArrayToTranslate addObject:spacePart];
                }
                else{

                    KCWordCluster *otherPart  = [[KCWordCluster alloc] init];
                    otherPart.rangeBeforeTranslate = NSMakeRange(beforeIndex, 1);
                    otherPart.specialTextType = SMSpecialTextTypeNormal;
                    otherPart.realContentText = [normalStr substringWithRange:NSMakeRange(beforeIndex, 1)];
                    [textPartArrayToTranslate addObject:otherPart];

                }
            }
        }

        lastRangeLocation = (int)(substringRange.location + substringRange.length);
        KCWordCluster *normalTextPart  = [[KCWordCluster alloc] init];
        normalTextPart.realContentText = substring;
        normalTextPart.rangeBeforeTranslate = substringRange;
        normalTextPart.specialTextType = SMSpecialTextTypeNormal;
        [textPartArrayToTranslate addObject:normalTextPart];
    }];

    if (lastRangeLocation < normalStr.length - 1) {
        int deltaIndex = (int)(normalStr.length - lastRangeLocation);
        for (int idx = 0; idx < deltaIndex; idx ++) {
            int beforeIndex = lastRangeLocation + idx;
            unichar beforeChar = [normalStr characterAtIndex:beforeIndex];
            if (beforeChar == 0xfffc) {
                KCWordCluster * textPart = tempEmojArray[specialTextCount];
                textPart.rangeBeforeTranslate = NSMakeRange(beforeIndex, 1);
                textPart.specialTextType = SMSpecialTextTypeLocalEmoji;
                [textPartArrayToTranslate addObject:textPart];
            }
            else{
                KCWordCluster *normalTextPart  = [[KCWordCluster alloc] init];
                normalTextPart.realContentText = [normalStr substringWithRange:NSMakeRange(beforeIndex, 1)];
                normalTextPart.rangeBeforeTranslate = NSMakeRange(beforeIndex, 1);
                normalTextPart.specialTextType = SMSpecialTextTypeSpace;
                [textPartArrayToTranslate addObject:normalTextPart];
            }
            
        }
    }
    
    if (highlightColor == nil) {
        highlightColor = [UIColor colorFromHexString:@"#7198ff"];
    }
    if (imageSize.width == 0 || imageSize.height == 0) {
        imageSize = CGSizeMake(30, 30);
    }
    [self translateWithTextPartArray:textPartArrayToTranslate withHighlightColor:highlightColor imageSize:imageSize translateOneTime:translateOneTime translateResult:^(NSArray *EmojiArray, NSAttributedString *resultAttributedStr) {
        if (EmojiArray == nil && resultAttributedStr == nil) {
            result(nil,nil);
        }
        NSArray *arr = [resultAttributedStr attribute:@"specials" atIndex:0 effectiveRange:NULL];
        if (arr.count == 0) {
            result(resultAttributedStr,NO);
        }else{
            result(resultAttributedStr,YES);
        }
        
        // deleteImageCache
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(queue, ^{
            [[KCPropertyManager sharePropertyMgr] clearImagesIfMoreThanmaxSize];
        });
    }];
    
}

+ (void)translateWithTextPartArray:(NSMutableArray *)textPartArray withHighlightColor:(UIColor *)highlightColor imageSize:(CGSize)imageSize translateOneTime:(BOOL)translateOneTime translateResult:(void (^)(NSArray *EmojiArray,NSAttributedString *resultAttributedStr))result{
    NSMutableArray *textPartNeedToTranslate = [NSMutableArray array];
    NSMutableArray *textPartArrayForJoin = [NSMutableArray array];
    NSUInteger count = textPartArray.count;
    for (int i = 0; i < count; i ++) {
        KCWordCluster *singleTextPart = textPartArray[i];
        if (singleTextPart.specialTextType == SMSpecialTextTypeNormal) {
            NSString *text = singleTextPart.realContentText;
            NSArray *resultArr = [[KCPropertyManager sharePropertyMgr] queryHotWordArrayWithHotWord:text];
            if (resultArr.count) {
                if (i == count - 1) {
                        BOOL firstReallyExist = NO;
                        for (NSString *firstResultStr in resultArr) {
                            if ([text.lowercaseString isEqualToString:firstResultStr.lowercaseString]) {
                                firstReallyExist = YES;
                                break;
                            }
                        }
                        if (firstReallyExist) {
                            [textPartNeedToTranslate addObject:singleTextPart];
                        }
                    [textPartArrayForJoin addObject:singleTextPart];
                }else if(i < count - 1){ // not the lastobject
                    KCWordCluster *next1 = textPartArray[i + 1];
                    if(next1.specialTextType == SMSpecialTextTypeLocalEmoji){ // 已经是图片了
                        [textPartNeedToTranslate addObject:singleTextPart];
                        [textPartArrayForJoin addObject:singleTextPart];
                        [textPartArrayForJoin addObject:next1];
                        i ++;
                        
                    }else if(next1.specialTextType == SMSpecialTextTypeSpace || next1.specialTextType == SMSpecialTextTypeNormal){
                        KCWordCluster *needToTranslateTextPart = [[KCWordCluster alloc] init];
                        needToTranslateTextPart.specialTextType = SMSpecialTextTypeNormal;
                        NSString *finalText = [NSString stringWithFormat:@"%@%@",singleTextPart.realContentText,next1.realContentText];
                        int length = (int)singleTextPart.rangeBeforeTranslate.length + 1;
                        int maxCount = 8;
                        for (int j = 1; j < maxCount; j ++) {
                            if (i + 1 + j  <= count - 1) {
                                
                                KCWordCluster *nextNext = textPartArray[i + j + 1];
                                if (nextNext.specialTextType == SMSpecialTextTypeLocalEmoji) {
                                    // James + '_' + Bond + 🐶
                                    if ([finalText hasSuffix:@" "] || [finalText hasSuffix:@"-"]) {                                        needToTranslateTextPart.realContentText = [finalText substringToIndex:finalText.length - 1];
                                        needToTranslateTextPart.rangeBeforeTranslate = NSMakeRange(singleTextPart.rangeBeforeTranslate.location, length - 1);
                                        
                                        [textPartNeedToTranslate addObject:needToTranslateTextPart];
                                        
                                        [textPartArrayForJoin addObject:needToTranslateTextPart];
                                        [textPartArrayForJoin addObject:textPartArray[i + j]];
                                        [textPartArrayForJoin addObject:nextNext]; // 🐶
                                        i += 1 + j;
                                        j = maxCount;
                                    }
                                    else{
                                        needToTranslateTextPart.realContentText = finalText;
                                        needToTranslateTextPart.rangeBeforeTranslate = NSMakeRange(singleTextPart.rangeBeforeTranslate.location, length);
                                        
                                        [textPartNeedToTranslate addObject:needToTranslateTextPart];
                                        [textPartArrayForJoin addObject:needToTranslateTextPart];
                                        
                                        [textPartArrayForJoin addObject:nextNext];// 🐶
                                        i += 1 + j;
                                        j = maxCount;
                                    }
                                }
                                else if (nextNext.specialTextType == SMSpecialTextTypeSpace){                                     if ([finalText hasSuffix:@" "] ||[finalText hasSuffix:@"-"]) {                                         needToTranslateTextPart.realContentText = [finalText substringToIndex:finalText.length - 1];
                                        needToTranslateTextPart.rangeBeforeTranslate = NSMakeRange(singleTextPart.rangeBeforeTranslate.location, length - 1);
                                        
                                        [textPartNeedToTranslate addObject:needToTranslateTextPart];
                                        [textPartArrayForJoin addObject:needToTranslateTextPart];
                                        [textPartArrayForJoin addObject:textPartArray[i + j]];
                                        [textPartArrayForJoin addObject:nextNext];
                                        i += 1 + j;
                                        j = maxCount;
                                    }
                                    else{
                                        finalText = [finalText stringByAppendingString:@" "];
                                        length += 1;
                                    }
                                }
                                else if (nextNext.specialTextType == SMSpecialTextTypeNormal) {
                                    NSString *totalStr = [finalText stringByAppendingString:nextNext.realContentText];
                                    if ([resultArr containsObject:totalStr]) {
                                        finalText = totalStr;
                                        length += nextNext.rangeBeforeTranslate.length;
                                    }
                                    else{
                                        BOOL exist = NO;
                                        for (NSString *resultElement in resultArr) {
                                            if ([resultElement.lowercaseString containsString:totalStr.lowercaseString]) {
                                                if (resultElement.length > totalStr.length) {
                                                    unichar nextChar = [resultElement characterAtIndex:totalStr.length];
                                                    if (nextChar == ' ') {
                                                        exist = YES;
                                                    }
                                                    
                                                }
                                                else{
                                                     exist = YES;
                                                }
                                                break;
                                            }
                                        }
                                        if (exist) {
                                            finalText = totalStr;
                                            length += nextNext.rangeBeforeTranslate.length;
                                        }
                                        else{
                                            if ([finalText hasSuffix:@" "] || [finalText hasSuffix:@"-"]) {
                                                needToTranslateTextPart.realContentText = [finalText substringToIndex:finalText.length - 1];
                                                needToTranslateTextPart.rangeBeforeTranslate = NSMakeRange(singleTextPart.rangeBeforeTranslate.location, length - 1);
                                            }
                                            else{
                                                needToTranslateTextPart.realContentText = [finalText substringToIndex:finalText.length];
                                                needToTranslateTextPart.rangeBeforeTranslate = NSMakeRange(singleTextPart.rangeBeforeTranslate.location, length);
                                            }
 
                                            if (j == 1) {
                                                BOOL firstReallyExist = NO;
                                                if ([finalText hasSuffix:@" "] || [finalText hasSuffix:@"-"]){
                                                    for (NSString *firstResultStr in resultArr) {
                                                        if ([text.lowercaseString isEqualToString:firstResultStr.lowercaseString]) {
                                                            firstReallyExist = YES;
                                                            break;
                                                        }
                                                    }
                                                    if (firstReallyExist) {
                                                        [textPartNeedToTranslate addObject:needToTranslateTextPart];
                                                    }
                                                }else{ // if
                                                    for (NSString *firstResultStr in resultArr) {
                                                        if ([finalText.lowercaseString isEqualToString:firstResultStr.lowercaseString]) {
                                                            firstReallyExist = YES;
                                                            break;
                                                        }
                                                    }
                                                    if (firstReallyExist) {
                                                        [textPartNeedToTranslate addObject:needToTranslateTextPart];
                                                    }

                                                }
                                                
                                            }
                                            else{
                                                [textPartNeedToTranslate addObject:needToTranslateTextPart];

                                            }
                                            
                                            [textPartArrayForJoin addObject:needToTranslateTextPart];
                                            NSString *str = [textPartArray[i + j] realContentText];
                                            if (str.isChinese) {
                                                
                                            }
                                            else{
                                                [textPartArrayForJoin addObject:textPartArray[i + j]];
                                            }
                                            i += j;
                                            
                                            j = maxCount;
                                        }
                                    }
                                }
                                
                            }
                            else{
                                if ([finalText hasSuffix:@" "] || [finalText hasSuffix:@"-"]) {                                     needToTranslateTextPart.realContentText = [finalText substringToIndex:finalText.length - 1];
                                    needToTranslateTextPart.rangeBeforeTranslate = NSMakeRange(singleTextPart.rangeBeforeTranslate.location, length - 1);
                                    [textPartNeedToTranslate addObject:needToTranslateTextPart];
                                    
                                    [textPartArrayForJoin addObject:needToTranslateTextPart];
                                    [textPartArrayForJoin addObject:textPartArray[count - 1]];
                                    i = (int)count;
                                    j = maxCount;
                                }
                                else{
                                    needToTranslateTextPart.realContentText = finalText;
                                    needToTranslateTextPart.rangeBeforeTranslate = NSMakeRange(singleTextPart.rangeBeforeTranslate.location, length);
                                    
                                    [textPartNeedToTranslate addObject:needToTranslateTextPart];
                                    [textPartArrayForJoin addObject:needToTranslateTextPart];
                                    i = (int)count;
                                    j = maxCount;
                                }
                            }
                        }
                    }
                    
                }
                
            }
            else{
                [textPartArrayForJoin addObject:singleTextPart];
            }
        }
        else if (singleTextPart.specialTextType == SMSpecialTextTypeLocalEmoji || singleTextPart.specialTextType == SMSpecialTextTypeSpace)
        {
            [textPartArrayForJoin addObject:singleTextPart];
        }
    }
    
    if (textPartNeedToTranslate.count ==0) {
        result(nil,nil);
        return;
    }
    
    __block BOOL cancelTranslate = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (cancelTranslate) {
            NSLog(@"cancelTranslatecancelTranslatecancelTranslate");
            result(nil,nil);
        }
    });
    
    __block int totalCount = 0;
    for (KCWordCluster *textPart in textPartNeedToTranslate) {
        NSString *normalStr = textPart.realContentText;
        if (normalStr) {
            [[KCPropertyManager sharePropertyMgr] requestPropertyArrayWithKeyword:normalStr isTranslate:YES translateDone:^(BOOL done) {
                
                if (done) {
                    totalCount ++;
                    NSLog(@"%d=========totalCount",totalCount);
                    if (totalCount == textPartNeedToTranslate.count) {
                        cancelTranslate = NO;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self requestwithTextPartArray:textPartArrayForJoin withHighlightColor:highlightColor imageSize:imageSize translateOneTime:translateOneTime finalResult:^(NSArray *EmojiArray, NSAttributedString *resultAttributedStr) {
                                result(EmojiArray,resultAttributedStr);
                            }];
                            
                        });
                      
                    }
                }
                
            }];
            
        }
    }
}

+ (void)requestwithTextPartArray:(NSMutableArray *)textPartArray withHighlightColor:(UIColor *)highlightColor imageSize:(CGSize)imageSize translateOneTime:(BOOL)translateOneTime finalResult:(void (^)(NSArray *EmojiArray,NSAttributedString *resultAttributedStr))result {
    if (textPartArray == nil) {
        result(nil,nil);
    }
    NSMutableAttributedString *finalAttributedS = [[NSMutableAttributedString alloc] init];
    NSDictionary * attr = @{NSFontAttributeName :[UIFont fontWithName:FontName size:ShowFontSize],NSBaselineOffsetAttributeName:@8};
    
    NSDictionary * linkAttr;
    if (translateOneTime == NO) {
       linkAttr =  @{NSFontAttributeName :[UIFont fontWithName:FontName size:ShowFontSize],NSForegroundColorAttributeName:highlightColor,NSBaselineOffsetAttributeName:@8};
    }

    
    NSMutableArray *finalEmojiArray = [NSMutableArray array];
    NSMutableArray *specialsArray = [NSMutableArray array];
    
    for (KCWordCluster *finalTextPart in textPartArray) {
        NSAttributedString *substr = nil;
        if (finalTextPart.specialTextType == SMSpecialTextTypeNormal) {
            NSString *json = [[KCPropertyManager sharePropertyMgr] jsonResultWithKeyword:finalTextPart.realContentText];
            if (json) {
                NSDictionary *totalDict = [NSString dictionaryWithJsonString:json];
                int cand_count = [totalDict[@"cand_count"] intValue];
                if (cand_count == 1) { // only one property, show now
                    KCOnlinePropertyData *property = [KCOnlinePropertyData mj_objectWithKeyValues:totalDict[@"1"]];
                    NSString *property_id = property.property_id;
                    NSString *imageName = [property_id stringByReplacingOccurrencesOfString:@":" withString:@"*"];
                    NSString *imagePath = [NSString stringWithFormat:@"%@/%@@2x.png",ImageCachePath,imageName];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                        UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
                        KCTextAttahment *attch = [[KCTextAttahment alloc] init];
                        if (image) {
                            attch.image = image;
                            attch.bounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
                            substr = [NSAttributedString attributedStringWithAttachment:attch];
                            attch.attriburedStr = substr;
                            KCWordCluster *t = [[KCWordCluster alloc] init];
                            t.attributedStr = substr;
                            t.rangeBeforeTranslate = finalTextPart.rangeBeforeTranslate;
                            t.shouldSendAsString = [NSString stringWithFormat:@"#|%@_%@|",finalTextPart.realContentText,property.property_id];
                            attch.text = t.shouldSendAsString;
                            t.specialTextType = SMSpecialTextTypeLocalEmoji;
                            [finalEmojiArray addObject:t];
                        }
                    }
                    else{
                        substr = [[NSAttributedString alloc] initWithString:finalTextPart.realContentText attributes:attr];
                    }
                }
                else if(cand_count > 1){// more than one
                    
                    if (translateOneTime) { // don't show highted words, replace with fisrt emoji
                        KCOnlinePropertyData *property = [KCOnlinePropertyData mj_objectWithKeyValues:totalDict[@"1"]];
                        NSString *property_id = property.property_id;
                        NSString *imageName = [property_id stringByReplacingOccurrencesOfString:@":" withString:@"*"];
                        NSString *imagePath = [NSString stringWithFormat:@"%@/%@@2x.png",ImageCachePath,imageName];
                        if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
                            UIImage * image = [UIImage imageWithContentsOfFile:imagePath];
                            KCTextAttahment *attch = [[KCTextAttahment alloc] init];
                            if (image) {
                                attch.image = image;
                                attch.bounds = CGRectMake(0, 0, imageSize.width, imageSize.height);
                                substr = [NSAttributedString attributedStringWithAttachment:attch];
                                attch.attriburedStr = substr;
                                KCWordCluster *t = [[KCWordCluster alloc] init];
                                t.attributedStr = substr;
                                t.rangeBeforeTranslate = finalTextPart.rangeBeforeTranslate;
                                t.shouldSendAsString = [NSString stringWithFormat:@"#|%@_%@|",finalTextPart.realContentText,property.property_id];
                                attch.text = t.shouldSendAsString;
                                t.specialTextType = SMSpecialTextTypeLocalEmoji;
                                [finalEmojiArray addObject:t];
                            }
                        }
                        else{
                            substr = [[NSAttributedString alloc] initWithString:finalTextPart.realContentText attributes:attr];
                        }
                    }
                    else{
                        substr = [[NSAttributedString alloc] initWithString:finalTextPart.realContentText attributes:linkAttr];
                        finalTextPart.normalTextRange = NSMakeRange(finalAttributedS.length, finalTextPart.rangeBeforeTranslate.length);
                        [specialsArray addObject:finalTextPart];
                    }
                }
                else{
                    substr = [[NSAttributedString alloc] initWithString:finalTextPart.realContentText attributes:attr];
                }
                
            }
            else{ // if no json, means there's no emoji to this word, show the normal words
                if (finalTextPart.realContentText.length) {
                    substr = [[NSAttributedString alloc] initWithString:finalTextPart.realContentText attributes:attr];
                }
                else{
                    substr = [[NSAttributedString alloc] initWithString:@"" attributes:attr];
                }
            }
        }
        else if (finalTextPart.specialTextType == SMSpecialTextTypeSpace) {
            // if space, show it
            substr = [[NSAttributedString alloc] initWithString:@" " attributes:attr];
            
        }
        else if (finalTextPart.specialTextType == SMSpecialTextTypeLocalEmoji) {
            // if LocalEmoji, get its attributedStr
            NSAttributedString * attrS = finalTextPart.attributedStr;
            if (attrS) {
                substr = attrS;
                [finalEmojiArray addObject:finalTextPart.copy];
            }
            else{
                substr = [[NSAttributedString alloc] initWithString:@""];
            }
        }
        [finalAttributedS appendAttributedString:substr];
    }
    if (finalAttributedS.length && result) {
        if (specialsArray.count && translateOneTime == NO) {
            [finalAttributedS addAttribute:@"specials" value:specialsArray range:NSMakeRange(0, 1)];
        }
        result(finalEmojiArray,finalAttributedS);
    }
}

+ (NSString *)resotreNormalStringWithAttributedString:(NSAttributedString *)attributedStr andNormalText:(NSString *)normalText{
    __block NSString *finalSendStr = @"";
    [attributedStr enumerateAttributesInRange:NSMakeRange(0, attributedStr.length) options:0 usingBlock:^(NSDictionary<NSString *,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        KCTextAttahment *attatchment = attrs[@"NSAttachment"];
        if (!attatchment) {
            NSString *sub = [normalText substringWithRange:range];
            finalSendStr = [finalSendStr stringByAppendingString:sub];
        }
        else{
            NSString *attachText = attatchment.text;
            finalSendStr = [finalSendStr stringByAppendingString:attachText];
        }
    }];
    return finalSendStr;
}


+ (void)translateWhenUserClickedEmoji:(KCEmojiModel *)recent withSourceAttrubutedStr:(NSMutableAttributedString *)str content:(NSString *)content{
    int currentIndex = (int)str.length;
    // 如果是online的,要删除对应的keyword
    NSRange keywordRange;
    if (recent.emojiType == SMEmojiTypeOnline) {
       if (recent.keyword) {
            keywordRange = [content rangeOfString:recent.keyword];
            if (keywordRange.location != NSNotFound) {
                if (keywordRange.location) {
                    unichar bfChar = [content characterAtIndex:keywordRange.location - 1];
                    if (bfChar == '\\') {// 判断有没有加"\"
                        currentIndex = (int)keywordRange.location - 1;
                        [str deleteCharactersInRange:NSMakeRange(keywordRange.location - 1, keywordRange.length + 1)];
                    }
                    else{
                        currentIndex = (int)keywordRange.location;
                        [str deleteCharactersInRange:keywordRange];
                    }
                }
                else{
                    currentIndex = (int)keywordRange.location;
                    [str deleteCharactersInRange:keywordRange];
                }
            }
        }
        
    }
    NSMutableAttributedString *textAttachmentString = [KCTextTranslator textAttachmentStringWithEmojiModel:recent];
   [str insertAttributedString:textAttachmentString atIndex:currentIndex];
}

+(NSMutableAttributedString *)textAttachmentStringWithEmojiModel:(KCEmojiModel *)emojiModel{
    KCTextAttahment *textAttachment = [[KCTextAttahment alloc] initWithData:nil ofType:nil];
    // 既然到了点击的这一步,说明图片应该是下载下来了(如果没有下载下来的话,后续还会有判断)
    NSString *imageName = emojiModel.emojiImageName;
    UIImage *to_image;
    NSString *shouldSend;
    if (emojiModel.emojiType == SMEmojiTypeOnline) {
        to_image = [UIImage imageWithContentsOfFile:[ImageCachePath stringByAppendingPathComponent:imageName]];
        shouldSend = [NSString stringWithFormat:@"#|%@_%@|",emojiModel.keyword,emojiModel.property_id];
    }
    else{
        to_image = [UIImage imageNamed:imageName];
        if ([imageName hasSuffix:@"@2x"]) {
            imageName = [imageName substringToIndex:imageName.length - 1 - 3];
        }
        shouldSend = [NSString stringWithFormat:@"#[%@]",imageName];

    }

    textAttachment.text = shouldSend;
    textAttachment.image = to_image;
    textAttachment.bounds = CGRectMake(0, 0, 30, 30);
    // 2.将新的Emoji添加到字符串最后
    NSMutableAttributedString *textAttachmentString = (NSMutableAttributedString *)[NSAttributedString attributedStringWithAttachment:textAttachment] ;
    textAttachment.attriburedStr = textAttachmentString;
    return textAttachmentString;
}
@end
