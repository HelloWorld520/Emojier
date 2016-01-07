//
//  SMAttributedString.h
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/9.
//  Copyright © 2015 Sam. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface KCMessageAnalyzer : NSObject

/**
 *  When analyse the dialog list, you should call this method in every tableView cell
 *
 *  @param contentStr cell.label.text
 *  @param messageID  unique messageID to do cell size cache
 *  @param sourceAttS cell.label.attributedText if the size is alreay cached, there's no need to 
                      analyse the text again
 *  @param fontColor  if there are words have more than one emojis, it will be highlighted with the color
 *
 *  @return the final attributedStr which already been convert to attributedStr
 */
+(NSMutableAttributedString *)attributedStringWithContentString:(NSString *)contentStr withMessageID:(NSString *)messageID withAttributedStr:(NSAttributedString *)sourceAttS withFontColor:(UIColor *)fontColor;
/**
 *  You will set the tabelViewCell's height with the textLabel/textView size
 *
 *  @param content    textLabel.text
 *  @param messageID  unique messageID
 *  @param sourceAttS textLabel.attributedText
 *  messageID and sourceAttS is used to get cache data
 *
 *  @return textLabelSize
 */
+(CGSize)sizeWithContent:(NSString *)content withMessageID:(NSString *)messageID withAttributedStr:(NSAttributedString *)sourceAttS;

@end
