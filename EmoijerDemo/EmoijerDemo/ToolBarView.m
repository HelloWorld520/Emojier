//
//  ToolBarView.m
//  EmoijerDemo
//
//  Created by Sam on 16/1/4.
//  Copyright © 2016年 Sam. All rights reserved.
//

#import "ToolBarView.h"
@interface ToolBarView()
@property (nonatomic, strong) UIButton *recent;
@property (nonatomic, strong) UIButton *translate;
@property (nonatomic, strong) UIButton *dismiss;
@property (nonatomic, strong) UIButton *slash;
@end

#define Button_Font_Size 14
@implementation ToolBarView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        UIButton *recent = [[UIButton alloc] init];
        [self addSubview:recent];
        recent.tag = 0;
        [recent setTitle:@"Recent" forState:UIControlStateNormal];
        recent.titleLabel.font = [UIFont systemFontOfSize:Button_Font_Size];
        recent.layer.borderColor = [UIColor greenColor].CGColor;
        recent.layer.borderWidth = 1;
        recent.layer.cornerRadius = 3;
        recent.clipsToBounds = YES;
        self.recent = recent;
        
        UIButton *translate = [[UIButton alloc] init];
        [self addSubview:translate];
        translate.tag = 1;
        translate.titleLabel.font = [UIFont systemFontOfSize:Button_Font_Size];
        [translate setTitle:@"Translate" forState:UIControlStateNormal];
        translate.layer.borderColor = [UIColor orangeColor].CGColor;
        translate.layer.borderWidth = 1;
        translate.layer.cornerRadius = 3;
        translate.clipsToBounds = YES;
        self.translate = translate;
        
        
        UIButton *dismiss = [[UIButton alloc] init];
        [self addSubview:dismiss];
        dismiss.tag = 2;
        dismiss.titleLabel.font = [UIFont systemFontOfSize:Button_Font_Size];
        [dismiss setTitle:@"Dismiss" forState:UIControlStateNormal];
        dismiss.layer.borderColor = [UIColor redColor].CGColor;
        dismiss.layer.borderWidth = 1;
        dismiss.layer.cornerRadius = 3;
        dismiss.clipsToBounds = YES;
        self.dismiss = dismiss;
        self.backgroundColor = [UIColor lightGrayColor];
        
        
        
        UIButton *slash = [[UIButton alloc] init];
        [self addSubview:slash];
        slash.tag = 3;
        slash.layer.borderColor = [UIColor redColor].CGColor;
        slash.layer.borderWidth = 1;
        slash.layer.cornerRadius = 3;
        slash.clipsToBounds = YES;
        self.slash = slash;
        [slash setImage:[UIImage imageNamed:@"xiegang"] forState:UIControlStateNormal];
        
        self.backgroundColor = [UIColor lightGrayColor];
        
        
        // slash
        [slash addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [recent addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [translate addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [dismiss addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return self;
}

- (void)buttonClicked:(UIButton *)button{
    if ([self.delegate respondsToSelector:@selector(toolBarButtonClicked:)]) {
        [self.delegate toolBarButtonClicked:button];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    _recent.frame = CGRectMake(0, 0, self.frame.size.width / 4, self.frame.size.height);
    _translate.frame = CGRectMake(self.frame.size.width / 4, 0, self.frame.size.width / 4,self.frame.size.height);
    _dismiss.frame = CGRectMake(self.frame.size.width / 4 * 2, 0, self.frame.size.width / 4,self.frame.size.height);
    _slash.frame = CGRectMake(self.frame.size.width / 4 * 3, 0, self.frame.size.width / 4,self.frame.size.height);
}



@end
