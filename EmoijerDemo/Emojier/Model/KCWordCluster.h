//
//  SMSpecialText.h
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/8.
//  Copyright © 2015 Sam. All rights reserved.
//



/**
 *   When handle the sentence, you should convert the sentence to an array of wordCluster
 */


#import <Foundation/Foundation.h>

/**
 *  RegularExpression
 *  When Dialog list, the RegularExpressions will help to find out
 *  custom emojis including Online and local
 */
// OnlineEmoji
#define REGEX_Pattern_Onlie @"(#\\|)[\\w:_\\- ]{1,}\\|"
// LocalEmoji
#define REGEX_Pattern_Local @"(#\\[)[\\w:_*\\- ]{1,}\\]"

typedef NS_ENUM(int,SMSpecialTextType){
    // normal str
    SMSpecialTextTypeNormal = 0,
    // localEmoji
    SMSpecialTextTypeLocalEmoji,
    // OnlineEmoji
    SMSpecialTextTypeOnlineEmoji,
    // space
    SMSpecialTextTypeSpace
};

@interface KCWordCluster : NSObject

/**
 *  You cannot send the sentence such as "I love 🐶"
 *  You should send it like this "I love #|dog_12345678|"
 *  Then when the receiver got this message, you can
 *  use KCMessageAnalyzer to convert "#|dog_12345678|"
 *  to a picture "🐶"
 *
 * realContentText----- here is the real word "dog"
 
 * shouldSendAsString----- here is "#|dog_12345678|"
 
 * specialTextType---- is SMSpecialTextTypeOnlineEmoji
 
 * attributedStr---- is an attributedString alloc with the pic "🐶"
 
 * normalTextRange---- is the range in the stence after the conversion
 
 * rangeBeforeTranslate---- is the range before the conversion
 
 * link---- here may be "http://www.google.com",when you tap the

 * "🐶", the URL will be opened.
 */

@property (nonatomic, copy) NSString * realContentText;
@property (nonatomic, assign) SMSpecialTextType specialTextType;
@property (nonatomic, copy)   NSString * shouldSendAsString;
@property (nonatomic, strong) NSAttributedString *attributedStr;
@property (nonatomic, assign) NSRange normalTextRange;
@property (nonatomic, assign) NSRange rangeBeforeTranslate;
@property (nonatomic, strong) NSString *link;


@end

