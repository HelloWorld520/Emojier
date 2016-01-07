//
//  ToolBarView.h
//  EmoijerDemo
//
//  Created by Sam on 16/1/4.
//  Copyright © 2016年 Sam. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ToolBarViewDelegate <NSObject>

- (void)toolBarButtonClicked:(UIButton *)button;

@end

@interface ToolBarView : UIView
@property (nonatomic, weak) id <ToolBarViewDelegate>delegate;
@end
