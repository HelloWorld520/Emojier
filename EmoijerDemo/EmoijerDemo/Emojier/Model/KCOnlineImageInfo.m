//
//  SMPropretyImageData.m
//  ChatDemo-UI2.0
//
//  Created by Sam on 15/11/26.
//  Copyright © 2015 Sam. All rights reserved.
//

#import "KCOnlineImageInfo.h"

@implementation KCOnlineImageInfo

- (NSString *)description{
    return [NSString stringWithFormat:@"###SMPropretyImageData-----adv_width:%@,height:%@,img_type:%@,img_url:%@,width:%@,x_offset:%@,y_offset:%@###",self.adv_width,self.height,self.img_type,self.img_id,self.width,self.x_offset,self.y_offset];
}
@end
