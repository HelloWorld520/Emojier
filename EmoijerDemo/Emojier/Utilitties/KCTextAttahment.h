//
//  SMTextAttahment.h
//  ChatDemo-UI2.0
//
//  Created by 张赛 on 15/12/25.
//  Copyright © 2015 张赛. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KCTextAttahment : NSTextAttachment
/**
 *  NSTextAttachment dose not has the property `text` which means its real content
 *  But when we send "I love 🐶 and 🐒" we want to retore the attributedString to 
 *  "I love #|dog_12345678| and #|monkey_87654321|". So when you creat an TextAttachment
 *  you should bind the `text` with it .
 *  
 *  somethimes when we find the TextAttachment we want to know it's origin attriburedStr,
 *  so the property `attriburedStr` is to make it eaiser to get the attriburedStr.
 */
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSAttributedString *attriburedStr;
@end
