//
//  SMEmojiPropertyData.m
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/26.
//  Copyright © 2015 Sam. All rights reserved.
//

#import "KCOnlinePropertyData.h"
#import "MJExtension.h"
@implementation KCOnlinePropertyData

+(void)load{
    
    [NSObject mj_setupReplacedKeyFromPropertyName:^NSDictionary *{
        return @{@"imageData":@"1",@"property_id":@"id"};
    }];
}

/**
 *  @property (nonatomic, strong) SMPropretyImageData *imageData;
 @property (nonatomic, strong) NSNumber *ascent;
 @property (nonatomic, strong) NSNumber *data_count;
 @property (nonatomic, strong) NSNumber *descent;
 @property (nonatomic, strong) NSString *property_id;
 *
 */
- (NSString *)description{
    return [NSString stringWithFormat:@"SMEmojiPropertyData-----imageData:%@,ascent:%@,data_count:%@,descent:%@,property_id:%@",self.imageData, self.ascent,self.data_count,self.descent,self.property_id];
}



@end
