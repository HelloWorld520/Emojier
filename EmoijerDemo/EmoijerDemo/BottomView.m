//
//  BottomView.m
//  EmoijerDemo
//
//  Created by Sam on 16/1/4.
//  Copyright © 2016年 Sam. All rights reserved.
//

#import "BottomView.h"
#import "KCEmojiModel.h"

@interface BottomView()<ToolBarViewDelegate>
@property (nonatomic, strong)UIView *recentBackView;
@property (nonatomic, strong) NSMutableArray *buttonArrayM;
@property (nonatomic, strong) UIButton *backButton;

#define PER_ANIMATE_DURATION 0.05
#define FADE_ANIMATE_DURATION 0.5

@end
@implementation BottomView

- (NSMutableArray *)buttonArrayM{
    if (_buttonArrayM == nil) {
        _buttonArrayM = [NSMutableArray array];
    }
    return _buttonArrayM;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
        UIView *recentBackView = [[UIView alloc] init];
        self.recentBackView = recentBackView;
        [self addSubview:recentBackView];
        recentBackView.backgroundColor = [UIColor orangeColor];
        
        ToolBarView *toolBar = [[ToolBarView alloc] init];
        self.toolBar = toolBar;
        [self addSubview:toolBar];
        toolBar.delegate = self;
        
        KCTextView *editorView = [[KCTextView alloc] init];
        self.editorView = editorView;
        [self addSubview:editorView];
        _editorView.font = [UIFont fontWithName:FontName size:ShowFontSize];
        
        UIButton *sendButton = [[UIButton alloc] init];
        self.sendButton = sendButton;
        [self addSubview:sendButton];
        [sendButton setTitle:@"Send" forState:UIControlStateNormal];
        sendButton.backgroundColor = [UIColor lightGrayColor];
        [sendButton addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];

        
        
        UIButton *backButton = [[UIButton alloc] init];
        self.backButton = backButton;
        [recentBackView addSubview:backButton];
        [backButton setTitle:@"Back" forState:UIControlStateNormal];
        backButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        
        
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 1;
        self.layer.cornerRadius = 5;
        self.clipsToBounds  = YES;

        self.backgroundColor = [UIColor whiteColor];
        
    }
    return self;
}

- (void)back{
    NSLog(@"back");
    [self.buttonArrayM removeAllObjects];
    self.recentBackView.hidden = YES;
    
}



- (void)setRecentEmoijs:(NSArray *)recentEmoijs{
    _recentEmoijs = recentEmoijs;
    self.recentBackView.hidden = NO;
    [self bringSubviewToFront:self.recentBackView];
    for (UIView *view  in self.recentBackView.subviews) {
        if (view != self.backButton) {
            [view removeFromSuperview];
        }
    }
    CGFloat WH = 40;
    int k = 0;
    NSString *filePath =[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"emojiImage"] ;
    for (KCEmojiModel * recentEmoji in recentEmoijs) {
        UIImage *image;
        if (recentEmoji.emojiType == SMEmojiTypeOnline) {
            NSString *imagePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@@2x.png",recentEmoji.emojiImageName]];
            image = [UIImage imageWithContentsOfFile:imagePath];
        }
        else{
            image = [UIImage imageNamed:recentEmoji.emojiImageName];
        }
        UIButton * button = [[UIButton alloc] init];
        [button addTarget:self action:@selector(emojiClicked:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = k;
        
        
        button.frame = CGRectMake(- 40, 0, 40, 40);
        [button setImage:image forState:UIControlStateNormal];
        [self.recentBackView addSubview:button];
        if (button.center.x != (k + 0.5 )* WH) {
            [UIView animateWithDuration:PER_ANIMATE_DURATION delay:0 usingSpringWithDamping:.6 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
                button.center = CGPointMake((k + 0.5 )* WH , button.center.y);
            } completion:NULL];
        }
        k ++;
        if (k > 8) {
            break;
        }
    }
    

}

- (void)emojiClicked:(UIButton *)button{
    NSUInteger buttonTag = button.tag;
    KCEmojiModel * recent = _recentEmoijs[buttonTag];
    if ([self.delegate respondsToSelector:@selector(emojiButtonClicked:)]) {
        [self.delegate emojiButtonClicked:recent];
    }
}
- (void)send{
    if ([self.delegate respondsToSelector:@selector(sendButtonClicked)]) {
        [self.delegate sendButtonClicked];
    }
}
- (void)toolBarButtonClicked:(UIButton *)button
{
    if ([self.delegate respondsToSelector:@selector(BottomViewButtonClicked:)]) {
        [self.delegate BottomViewButtonClicked:button];
    }
}



- (void)layoutSubviews
{
    [super layoutSubviews];
    _toolBar.frame = CGRectMake(0, 0, self.frame.size.width / 3 * 2, 40);
    
    _editorView.frame = CGRectMake(5, 5 + 40, self.frame.size.width - 80, self.frame.size.height - 10 - 40);
    _sendButton.frame = CGRectMake(CGRectGetMaxX(_editorView.frame) + 5, 0, 70, self.frame.size.height);
    
    _recentBackView.frame = CGRectMake(0, 0, self.frame.size.width , 40);
    
    _backButton.frame = CGRectMake(self.frame.size.width - 40,0, 40, 40);
}


@end
