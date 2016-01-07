//
//  ViewController.m
//  EmoijerDemo
//
//  Created by Sam on 16/1/4.
//  Copyright © 2016年 Sam. All rights reserved.
//

#import "ViewController.h"
#import "BottomView.h"
#import "KCPropertyManager.h"
#import "KCTextTranslator.h"
#import "KCMessageAnalyzer.h"
#import "NSString+tools.h"
#import "KCRecentEmojisMgr.h"
#import "Colours.h"
static NSString *cellID = @"EmojierDemoCellID";

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,BottomViewDelegate>
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong) BottomView *bottomView;
@property (nonatomic, strong) NSMutableArray *datasArrayM;
@property (nonatomic, strong) KCPropertyManager *propertyMgr;
@property (nonatomic, assign) BOOL recevicedReloadNotification;

@end

@implementation ViewController
- (NSMutableArray *)datasArrayM
{
    if (_datasArrayM == nil) {
        _datasArrayM = [NSMutableArray array];
    }
    return _datasArrayM;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.propertyMgr = [KCPropertyManager sharePropertyMgr];
    BottomView *bottomView = [[BottomView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 90, [UIScreen mainScreen].bounds.size.width, 90)];
    bottomView.delegate = self;
    self.bottomView = bottomView;
    UITableView *tableView= [[UITableView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 90)];
    self.tableView = tableView;
    tableView.delegate = self;
    tableView.dataSource = self;
    
    [self.view addSubview:tableView];
    [self.view addSubview:bottomView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChangeFrame:) name:UIKeyboardWillShowNotification object:nil];
       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChangeFrame:) name:UIKeyboardWillHideNotification object:nil];
           [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkEmoji:) name:UITextViewTextDidChangeNotification object:nil];
}

#define INVALID_STR (@"\U0000FFFC")
- (void)checkEmoji:(NSNotification *)notification{
    KCTextView * textView = self.bottomView.editorView;
    NSString *totalStr = textView.text;
    
    unichar lastChar = [totalStr characterAtIndex:totalStr.length - 1];
    if (lastChar == 0xfffc) {
        return;
    }
    NSString * textStr = textView.text;
    // 1.找到光标的位置
    NSRange selectedRange = textView.selectedRange;
    NSUInteger selected_start_idx = selectedRange.location;
    NSUInteger selected_end_idx = selectedRange.location + selectedRange.length;
    // 2.拿到所有字符
    // 3.将整个字符串按照空格生成一个数组
    NSArray * splitArray = [textStr componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    
    NSUInteger start_idx = 0;
    NSUInteger end_idx = 0;
    NSUInteger i = 0;
    NSString * currentStr = nil;
    // 3.拿出每个数组元素
    for (i = 0; i < splitArray.count; i++) {
        NSString *str = splitArray[i];
        NSInteger str_len = str.length;
        end_idx = start_idx + str_len;
        if ([str containsString:INVALID_STR]) {
            str = [str stringByReplacingOccurrencesOfString:INVALID_STR withString:@""];
        }
        if ([str isEqualToString:@""]) {
            start_idx += str_len + 1;
            continue;
        }
        if (end_idx >= selected_start_idx && selected_start_idx >= start_idx && end_idx >= selected_end_idx && selected_end_idx >= start_idx) {
            currentStr = str;
            break;
        }
        start_idx += str_len + 1;
    }
    
    
    
    if (currentStr != nil) {
       
            // if length == 1 and current must have prefix "\" so there cannot be any useful keyStr, just return
            if (currentStr.length == 1)return;
            // 1.go to sql and query local emojis
            if ([currentStr hasPrefix:@"\\"]) {
                // keyword
                NSString *keyword = [currentStr substringFromIndex:1];
                
                [self.propertyMgr requestPropertyArrayWithKeyword:keyword emojiModelBlk:^(NSMutableArray *emojiModelArray) {
                    
                    self.bottomView.recentEmoijs = (NSArray *)emojiModelArray;
                    
                }];
            }
            else{
                
            }
    }

}

- (void)emojiButtonClicked:(KCEmojiModel *)emoji{
    NSDictionary * dict = [KCEmojiModel emojiModelWithEmoji:emoji type:emoji.emojiType];
    [[KCRecentEmojisMgr shareRecentEmojiMgr] updateRecentEmojisWithResentEmoji:emoji withDict:dict];
    // 1.拿到当前输入框里的所有字符
    KCTextView * textView = self.bottomView.editorView;
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
    NSString *content = textView.text;
    textView.textAlignment = NSTextAlignmentCenter;
    
    [KCTextTranslator translateWhenUserClickedEmoji:emoji  withSourceAttrubutedStr:str content:content];
    
    
    NSDictionary * attr = @{NSFontAttributeName :[UIFont fontWithName:FontName size:ShowFontSize]};
   
    [str addAttributes:attr range:NSMakeRange(0, str.length)];
    textView.attributedText = str;
}

- (void)BottomViewButtonClicked:(UIButton *)button{
    switch (button.tag) {
        case 0: // recent
        {
            for (KCEmojiModel *emoji in [KCRecentEmojisMgr shareRecentEmojiMgr].recentEmojiModelArray) {
                emoji.comeFrom = SMComeFromRecent;
            }
            [self.bottomView setRecentEmoijs:[KCRecentEmojisMgr shareRecentEmojiMgr].recentEmojiModelArray];
        }
            break;
        case 1: // translate
            [self translateNormalStrToEmojis];
            break;
        case 2: // dismiss
        {
            [self.bottomView.editorView resignFirstResponder];
        }
            break;
        case 3: // slash
        {
            [self.bottomView.editorView insertText:@"\\"];
        }

            break;
        default:
            break;
    }
}

- (void)translateNormalStrToEmojis{
    
    // 0.拿到textView
    KCTextView * messageTextView = self.bottomView.editorView;
    // 1.拿到所有的字符
    NSString * content = messageTextView.text;
    // 1.1有可能content里边全是乱码,直接返回
    BOOL allAreEmoji = YES;
    for (int k = 0; k < content.length; k ++) {
        unichar singleChar = [content characterAtIndex:k];
        if (singleChar != 0xfffc) {
            allAreEmoji = NO;
            break;
        }
    }
    if (allAreEmoji) {
        return;
    }
    // 创建一个属性字符串,最后传递给textView
    messageTextView.isTranslating = YES;
    
    // 翻译
    // translateSourcAttributedStr:messageTextView.attributedText normalStr:content  toDestionAttributedStr:^(NSAttributedString *destiAttrs, BOOL hasMutiEmojis) {
    
    [KCTextTranslator  translateSourcAttributedStr:messageTextView.attributedText normalStr:content withHighlightColor:[UIColor colorFromHexString:@"#7198ff"] imageSize:CGSizeMake(30, 30) translateOneTime:YES toDestionAttributedStr:^(NSAttributedString *destiAttrs, BOOL hasMutiEmojis) {
        if (destiAttrs == nil && hasMutiEmojis == NO) {
            messageTextView.isTranslating = NO;
            return ;
        }
        else{
            messageTextView.attributedText = destiAttrs;
            messageTextView.font = [UIFont fontWithName:FontName size:ShowFontSize];
            if (hasMutiEmojis) {
                messageTextView.editable = NO;
                messageTextView.selectable = NO;
            }
            else{
                messageTextView.isTranslating = NO;
                [self->_propertyMgr clearDownloadKeywordsArray];
            }
        }
    }];
    
    
}


- (void)sendButtonClicked{
    NSAttributedString *attributedStr = self.bottomView.editorView.attributedText;
    NSString *normalText = self.bottomView.editorView.text;
    NSString *finalSendStr = [KCTextTranslator resotreNormalStringWithAttributedString:attributedStr andNormalText:normalText];
    [self.datasArrayM addObject:finalSendStr];
    [self.tableView reloadData];
    if (self.datasArrayM.count) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.datasArrayM.count - 1 inSection:0];
        [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
    self.bottomView.editorView.selectable = YES;
    self.bottomView.editorView.editable = YES;
    self.bottomView.editorView.text = @"";
    
}
- (void)keyboardChangeFrame:(NSNotification *)notification{
    NSDictionary * userInfo = notification.userInfo;
    NSTimeInterval time = [userInfo[@"UIKeyboardAnimationDurationUserInfoKey"] floatValue];
    CGRect bounds = [userInfo[@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
    CGFloat height = bounds.size.height;
    if ([notification.name isEqualToString:@"UIKeyboardWillHideNotification"]) {
        height = 0;
    }
    [UIView animateWithDuration:time animations:^{
        _bottomView.transform = CGAffineTransformMakeTranslation(0, -height);
        _tableView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - height - 90);
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.datasArrayM.count - 1 inSection:0];
        if (self.datasArrayM.count) {
          [_tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }

    }];
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.datasArrayM.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    NSString *text =  self.datasArrayM[indexPath.row];
    cell.textLabel.text = text;
    cell.textLabel.numberOfLines = 0;
    NSString *md5s = text.md5String;
    NSMutableAttributedString *attr = [KCMessageAnalyzer attributedStringWithContentString:text withMessageID:md5s withAttributedStr:cell.textLabel.attributedText withFontColor:[UIColor blackColor]];
    cell.textLabel.attributedText = attr;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}


- (void)DownloadImageByPropertyIDDoneNotification:(NSNotification *)notification{
    
    if (_recevicedReloadNotification) {
        return;
    }
    else{
        _recevicedReloadNotification = YES;
        __weak typeof(self) weak_self = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_tableView reloadData];
            if (self.datasArrayM.count) {
                   [self->_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:weak_self.datasArrayM.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }
            self->_recevicedReloadNotification = NO;
        });
    }
}




@end
