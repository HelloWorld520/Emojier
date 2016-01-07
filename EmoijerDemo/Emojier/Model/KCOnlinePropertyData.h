//
//  SMEmojiPropertyData.h
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/26.
//  Copyright © 2015 Sam. All rights reserved.
//

#import <Foundation/Foundation.h>
@class KCOnlineImageInfo;
@interface KCOnlinePropertyData : NSObject
@property (nonatomic, strong) KCOnlineImageInfo *imageData;
@property (nonatomic, strong) NSNumber *ascent;
@property (nonatomic, strong) NSNumber *data_count;
@property (nonatomic, strong) NSNumber *descent;
@property (nonatomic, strong) NSString *property_id;
@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSString *keyword;
@end
