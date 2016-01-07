//
//  CKEmojiPredictKing.h
//  predictEmoji
//
//  Created by Sam on 15/4/19.
//  Copyright (c) 2015 zhangsai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Singleton.h"
#import "KCEmojiModel.h"

@class KCOnlinePropertyData;
// imageCache folder path
#define ImageCachePath [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:@"emojiImage"]
#define KiChatPrivateKey @"KiChatPrivateKey"
// Your APP_KEY
#define APP_KEY @"testappkey1"

typedef void (^ RequestEmojiModelArrayBlock) (NSMutableArray *emojiModelArray);
typedef void (^ OnlineRequestPropertyDataBlock)(NSMutableArray *emojiModelArray);

@interface KCPropertyManager : NSObject
// KCPropertyManager is a singleton
singleH(PropertyMgr);
@property (nonatomic, copy) RequestEmojiModelArrayBlock requestEmojiModelArrayBlk;
@property (nonatomic, strong) NSString *userKey;


/**
 *  cache json of keyword
 *
 *  @param keyword keyword
 *  @param json    json of this keyword that already cached
 */
- (NSString *)jsonResultWithKeyword:(NSString *)keyword;
/**
 *  @param keyword                   the keyword you want to replace by emoji
 *  @param requestEmojiModelArrayBlk with the block, you can get the final emojModelArray
 */
- (void)requestPropertyArrayWithKeyword:(NSString *)keyword emojiModelBlk:(RequestEmojiModelArrayBlock)requestEmojiModelArrayBlk;
/**
 *  When analysis the dialog list, you may find a property_id exist in a part of the sentence such as 
 *  "#|dog_12345678|"
 *
 *  @param property_id 12345678
 *
 *  @return a KCOnlinePropertyData model with the property_id
 */
+(KCOnlinePropertyData *)localRequestPropertyDataWithPropertyID:(NSString *)property_id;
/**
 *   When analysis the dialog list,you may find a few property models, you should add the into a array,
 *   then called this method with the array, then KCPropertyManager will download all the emojis with the 
 *   properties in the array. c
 
 *  @param propertyArray the propertyArray in the sentences
 */
+(void)onlineRequestPropertyDataWithPropertyArray:(NSArray *)propertyArray;


- (NSArray *)requestDownloadedEmojiArrayWithKeyword:(NSString *)keyword comeFrom:(SMComeFrom)comeFrom;
- (void)clearDownloadKeywordsArray;
 /**
 *  Call this method with "James", you can get an array
 *  ["James","James Bond","James 123","James 456"......]
 *
 *  @param hotWord James
 *
 *  @return ["James","James Bond","James 123","James 456"......]
 */
- (NSArray *)queryHotWordArrayWithHotWord:(NSString *)hotWord;
/**
 *  When User input "\snow" or User clicked "Transate" button, this method should be called.
 *  if User input "\snow", tranlate == NO
 *  if User clicked "Transate" button, translate == YES
 *  You will get callback, when the work is done
 *
 *  @param keyword       keyword that user input
 *  @param tanslate      wether user clicked "Transate" button or not
 *  @param translateDone the work is done or not
 */
- (void)requestPropertyArrayWithKeyword:(NSString *)keyword isTranslate:(BOOL)tanslate translateDone:(void (^)(BOOL))translateDone;

// clear all the image cache
- (void)clearImageCache;
// clear images if images size > maxSize (Bytes)
// some but not all images will be deleted
// images will be sorted by last use time, the earlier used will be deleted until all images size < maxSize * 0.5
- (void)clearImagesIfMoreThanSize:(long long)maxSize;
// the image folder size that already cached
- (long long)imageCacheFileSize;
- (void)updateImageNameAndUseDateWithEmojiModel:(KCEmojiModel *)emoji;

@end
