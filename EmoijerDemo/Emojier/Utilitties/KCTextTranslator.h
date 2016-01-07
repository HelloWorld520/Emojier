//
//  KCTextTranslator.h
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/12/17.
//  Copyright © 2015 Sam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"
@class KCEmojiModel;
@interface KCTextTranslator : NSObject
singleH(Translator);

/*
This method is used to convert sentence to display format which can be present by os system. It doesn't matter if part of sentence had been converted to emojis. when conversion done, your callback will be called with the final Attributed String and if the sentence contains words that have more than one emojis. For detail parameters and prototype, please refer to below:

    @param `sourceAttrs` textView.attirebutedText (can't be nil)
                                                           
    @param `highlightColor`   If there are keywords have more than one emojis, the keyword will be highlighted, so you need set what color you want.

    @param `imageSize` When translate a keyword into an image(Actually it is an attributedString with an `KCAttachment`), you need to set the image size.`Default is (30,30).`

    @param `normalStr` textView.text  (can't be nil)
                                              
    @param `translateOneTime`   As described above, some words may have have more than one emojis, if `translateOneTime` is `NO`, the keyword will be replaced by a the first emoji, otherwise the keyword will be highlighted so that user can tap the keyword and chose one emoji. there is no need to specify `highlightColor` When `translateOneTime` is `NO`.
  
    @param `result`      final result
 */
+ (void)translateSourcAttributedStr:(NSAttributedString *)sourceAttrs normalStr:(NSString *)normalStr withHighlightColor:(UIColor *)highlightColor imageSize:(CGSize )imageSize translateOneTime:(BOOL)translateOneTime toDestionAttributedStr:(void (^)(NSAttributedString *destiAttrs,BOOL hasMutiEmojis))result;

/**
 *  When send message you should resotore the attributedString to normalString
 *
 *  @param attributedStr textView.attirebutedText
 *  @param normalText    textView.text
 *
 *  @return finalNormalString
 */
+ (NSString *)resotreNormalStringWithAttributedString:(NSAttributedString *)attributedStr andNormalText:(NSString *)normalText;
/**
 *  User select an emoji, textView.attributedText should be changed.
 *
 *  @param emoji   emoji that user select
 *  @param str     textView.attributedText
 *  @param content textView.text
 */
+ (void)translateWhenUserClickedEmoji:(KCEmojiModel *)emoji withSourceAttrubutedStr:(NSMutableAttributedString *)str content:(NSString *)content;


+(NSMutableAttributedString *)textAttachmentStringWithEmojiModel:(KCEmojiModel *)emojiModel;

@end
