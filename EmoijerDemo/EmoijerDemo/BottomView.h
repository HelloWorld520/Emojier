//
//  BottomView.h
//  EmoijerDemo
//
//  Created by Sam on 16/1/4.
//  Copyright © 2016年 Sam. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KCTextView.h"
#import "ToolBarView.h"
#define ShowFontSize 20
#define FontName @"SF UI Text Light"
@class KCEmojiModel;
@protocol BottomViewDelegate <NSObject>

- (void)BottomViewButtonClicked:(UIButton *)button;
- (void)sendButtonClicked;
- (void)emojiButtonClicked:(KCEmojiModel *)emoji;
@end

@interface BottomView : UIView

@property (nonatomic, strong) KCTextView *editorView;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) ToolBarView *toolBar;
@property (nonatomic, strong) NSArray *recentEmoijs;

@property (nonatomic, weak) id <BottomViewDelegate>delegate;
@end
