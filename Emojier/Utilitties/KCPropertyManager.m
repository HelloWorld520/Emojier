//
//  CKEmojiPredictKing.m
//  predictEmoji
//
//  Created by Sam on 15/4/19.
//  Copyright (c) 2015 zhangsai. All rights reserved.
//

#import "KCPropertyManager.h"
#import "FMDB.h"
#import "NSString+tools.h"
#import "KCOnlineImageInfo.h"
#import "AFNetworking.h"
#import "MJExtension.h"
#import "KCOnlinePropertyData.h"

#import "UIImageView+WebCache.h"
#import "KCWordCluster.h"
#import "Colours.h"

#define ShowFontSize       20
#define FontName           @"SF UI Text Light"
#define KiChatTime_Public  @"pubtimestamp"
#define KiChatTime_Private @"pritimestamp"


@interface KCPropertyManager()
{
    NSMutableArray *_propertyRequestCacheArray;
    NSMutableDictionary *_dowloadKeywordDict;
}
@property (nonatomic, strong) FMDatabase *db;
@property (nonatomic, strong) FMDatabaseQueue *queue;
@property (nonatomic, strong) NSString *timesTamp;

@end
@implementation KCPropertyManager
singleM(PropertyMgr);

#define SEARCH_URL @"http://api.emojier.net/cn1/emoji/search"
#define PROPERTY_URL @"http://api.emojier.net/cn1/emoji/getproperty"
#define LIST_URL @"http://api.emojier.net/cn1/emoji/gettaglist"

- (instancetype)init
{
    // path of t_property_data.sqlite in the sandbox
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    NSString *fileName = [path stringByAppendingPathComponent:@"t_property_data.sqlite"];
    NSFileManager *myFileMgr = [NSFileManager defaultManager];
    NSError *copyError;
    if ([myFileMgr fileExistsAtPath:fileName] == NO) {
        [myFileMgr copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"t_property_data.sqlite" ofType:nil] toPath:fileName error:&copyError];
    }
    if (copyError) {
        NSLog(@"copy t_property_data.sqlite error");
    }
    
    
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    self.userKey = [userDefault objectForKey:KiChatPrivateKey];
    
    self.db = [FMDatabase databaseWithPath:fileName];
    self.queue = [FMDatabaseQueue databaseQueueWithPath:fileName];
    [self.queue inDatabase:^(FMDatabase *db) {
        if ([db open]) {
            // Create t_property_cache
            BOOL success =  [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_property_cache (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, keyword TEXT NOT NULL, json TEXT NOT NULL);"];
            if (success) {
                NSLog(@"Create Table t_property_cache Succeed");
            }else
            {
                NSLog(@"Create Table t_property_cache Failed");
            }
            
            // Create t_id_to_propertydata
            BOOL success1 =  [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_id_to_propertydata (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, property_id TEXT NOT NULL, json TEXT NOT NULL);"];
            if (success1) {
                NSLog(@"Create Table t_id_to_propertydata Succeed");
            }else
            {
                NSLog(@"Create Table t_id_to_propertydata Failed");
            }
            
            BOOL success2 = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_local_hot_word (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, hot_word TEXT NOT NULL);"];
            if (success2) {
                NSLog(@"Create Table t_local_hot_word Succeed");
            }else
            {
                NSLog(@"Create Table t_local_hot_word Failed");
            }
            
            BOOL success3 = [db executeUpdate:@"CREATE TABLE IF NOT EXISTS img_use_time (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, imageName TEXT NOT NULL,lastUseTime TEXT NOT NULL);"];
            if (success3) {
                NSLog(@"Create Table img_use_time Succeed");
            }else
            {
                NSLog(@"Create Table img_use_time Failed");
            }
            [self updateLocalHotWordTableWithDB:db];
        }
        
    }];
    _propertyRequestCacheArray = [NSMutableArray array];
    _dowloadKeywordDict = [NSMutableDictionary dictionary];
        return self;
}

- (void)updateLocalHotWordTableWithDB:(FMDatabase *)db{
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *public = [userDefaults objectForKey:KiChatTime_Public];
    
    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    mgr.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[KiChatTime_Public] = @(0);
    params[@"app_key"] = APP_KEY;

    
    if (public == nil) {
        
        [mgr GET:LIST_URL parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            
            
                NSNumber *time = responseObject[KiChatTime_Public];
                NSMutableDictionary *newParams = [NSMutableDictionary dictionary];
            newParams[KiChatTime_Public] = time;
            newParams[@"app_key"] = APP_KEY;
            if (self.userKey) {
                NSNumber *private = [userDefaults objectForKey:KiChatTime_Private];
                if (private == nil) {
                    private = @0;
                }
                newParams[KiChatTime_Private] = @(private.intValue);
                newParams[@"p_key"] = self.userKey;
            }

            [self getNewListWithMgr:mgr params:newParams DB:db];
            }
         failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
             NSLog(@"error====%@",error);
        }];
        return;
    }
    else{
        params[KiChatTime_Public] = public;
        if (self.userKey) {
            NSNumber *private = [userDefaults objectForKey:KiChatTime_Private];
            if (private == nil) {
                private = @0;
            }
            params[KiChatTime_Private] = @(private.intValue);;

        }
        [self getNewListWithMgr:mgr params:params DB:db];
    }
}

- (void)getNewListWithMgr:(AFHTTPRequestOperationManager *)mgr params:(NSDictionary *)params DB:(FMDatabase *)db {
    
    [mgr GET:LIST_URL parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSArray *data = responseObject[@"data"];
        NSMutableArray *arrayM = [NSMutableArray array];
        for (NSString *tag in data) {
            NSString *hotWord = tag;
            if ([hotWord containsString:@"'"]) {
                hotWord = [hotWord stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
            }
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO t_local_hot_word (hot_word) VALUES('%@')",hotWord];
            [db executeUpdate:sql];
            [arrayM addObject:hotWord];
            
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            NSNumber *time = responseObject[KiChatTime_Public];
            [userDefaults setObject:time forKey:KiChatTime_Public];
            [userDefaults synchronize];
            
            NSNumber *private = responseObject[KiChatTime_Private];
            if (private == nil) {private = @0;};
            [userDefaults setObject:@(private.intValue) forKey:KiChatTime_Private];
            [userDefaults synchronize];
        }
        
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        NSLog(@"error======%@,url=======%@",error,operation.request.URL);
    }];
    return;
    
}
// cache json str with keyword
- (void)updatePropertyCacheWithKeyword:(NSString *)keyword json:(NSString *)json
{

    [self.queue inDatabase:^(FMDatabase *db) {

        FMResultSet *set = [db executeQuery:@"SELECT * FROM t_property_cache WHERE keyword =?",keyword];
        BOOL alreadyCached = NO;
        int times = 0;
        while ([set next]) {
            times += 1;
            alreadyCached = [set stringForColumn:@"keyword"] != nil;
            if (alreadyCached) {
                break;
            }
        }
        if (alreadyCached) {
            return;
        }
        else{
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO t_property_cache(keyword, json) VALUES('%@', '%@')",keyword,json];
            [db executeUpdate:sql];
        }
    }];
}

// cache property_ID with json str
- (void)updateID:(NSString *)property_id json:(NSString *)json
{
    
    if (property_id == nil || json == nil) {
        return;
    }
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:@"SELECT * FROM t_id_to_propertydata WHERE property_id =?",property_id];
        BOOL alreadyCached = NO;
        int times = 0;
        while ([set next]) {
            times += 1;
            alreadyCached = [set stringForColumn:@"property_id"] != nil;
            if (alreadyCached) {
                break;
            }
        }
        if (alreadyCached) {
            return;
        }
        else{
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO t_id_to_propertydata (property_id, json) VALUES('%@', '%@')",property_id,json];
            [db executeUpdate:sql];
        }
    }];
}


- (NSString *)jsonResultWithKeyword:(NSString *)keyword{
    
    if ([_dowloadKeywordDict.allKeys containsObject:keyword]) {
        return _dowloadKeywordDict[keyword];
    }
    __block NSString *jsonStr;

    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:@"SELECT * FROM t_property_cache WHERE keyword=?",keyword];
        while ([set next]) {
            jsonStr = [set stringForColumn:@"json"];
            self->_dowloadKeywordDict[keyword] = jsonStr;
            break;
        }
    }];
    
    return jsonStr;
}


- (void)requestPropertyArrayWithKeyword:(NSString *)keyword isTranslate:(BOOL)tanslate translateDone:(void (^)(BOOL done))translateDone{
    
    
    NSString *json =  [self jsonResultWithKeyword:keyword];
    __block NSMutableArray *totalPropertyDataArray = [NSMutableArray array];
    
    if (json.length) {
        NSDictionary *dict = [NSString dictionaryWithJsonString:json];
        int cand_count = [dict[@"cand_count"] intValue];
        if (cand_count == 0) { // cand_count == 0 no images online
            if (tanslate && translateDone) {
                translateDone(YES);
            }
            return;
        }
        for (int i = 0; i < cand_count; i ++) {
            NSString *key = [NSString stringWithFormat:@"%d",i + 1];
            NSDictionary *testDict = dict[key];
            KCOnlinePropertyData *property = [KCOnlinePropertyData mj_objectWithKeyValues:testDict];
            property.keyword = keyword;
            if (!property) continue;
            [totalPropertyDataArray addObject:property];
        }
        
        if (totalPropertyDataArray.count > 0) {
            [self createRecentEmojiModelArrayWithTotalJsonArray:(NSArray *)totalPropertyDataArray isTranslate:tanslate translateDone:^(BOOL done) {
                if (tanslate && done) {
                    translateDone(done);
                }
            }];
        }
        return;
    }
    
    
    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    mgr.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"q"] = keyword;
    params[@"app_key"] = APP_KEY;
    params[@"text_size"] = @64;
    if (self.userKey) {
        params[@"p_key"] = self.userKey;
    }
    
    [mgr GET:SEARCH_URL parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSDictionary *tmpDict = (NSDictionary *)responseObject;
        NSString *jsonString =  [tmpDict mj_JSONString];
        if ([tmpDict[@"cand_count"] intValue] == 0) { // cand_count == 0 means there's no emoji of this keyword
            if (tanslate && translateDone) {
                translateDone(YES);
            }
            return;
        }
        else{
            [[KCPropertyManager sharePropertyMgr] updatePropertyCacheWithKeyword:keyword json:jsonString];
        }
        int cand_count = [responseObject[@"cand_count"] intValue];
        
        for (int i = 0; i < cand_count; i ++) {
            NSString *key = [NSString stringWithFormat:@"%d",i + 1];
            NSDictionary *testDict = ((NSDictionary *)responseObject)[key];
            KCOnlinePropertyData *property = [KCOnlinePropertyData mj_objectWithKeyValues:testDict];
            property.keyword = keyword;
            
            [[KCPropertyManager sharePropertyMgr] updateID:property.property_id json:[testDict mj_JSONString]];
            if (!property) continue;
            [totalPropertyDataArray addObject:property];
        }
        if (totalPropertyDataArray.count > 0) {
            [self createRecentEmojiModelArrayWithTotalJsonArray:(NSArray *)totalPropertyDataArray isTranslate:tanslate translateDone:^(BOOL done) {
                if (tanslate && done) {
                    translateDone(done);
                }
            }];
            
        }
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        NSLog(@"%@=====error",error);
        // even if occur an error, still consider the work is alreay done
        if (tanslate) {
            translateDone(YES);
        }
    }];
}


- (void)createRecentEmojiModelArrayWithTotalJsonArray:(NSArray *)totalPropertyDataArray isTranslate:(BOOL)tanslate translateDone:(void (^)(BOOL done))translateDone{
    
    NSMutableArray *finalRecentModelArray = [NSMutableArray array];
    NSString *docPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *imagePath = [docPath stringByAppendingPathComponent:@"emojiImage"];
    NSFileManager *myfileMgr = [NSFileManager defaultManager];
    BOOL exist = [myfileMgr fileExistsAtPath:imagePath];
    if (!exist) { // if folder exist judge if the image is exist
        [myfileMgr createDirectoryAtPath:imagePath withIntermediateDirectories:NO attributes:nil error:NULL];
    }
    
    dispatch_group_t group = dispatch_group_create();

    for (int idx = 0; idx < totalPropertyDataArray.count; idx ++) {
        dispatch_group_enter(group);
        KCOnlinePropertyData *property = totalPropertyDataArray[idx];
        NSString *property_id = property.property_id;
        NSString *imageName = [NSString stringWithFormat:@"%@@2x.png",property_id];
        if ([imageName containsString:@":"]) { //@":"is illegal when name a pic, so replace it with @"*"
            imageName = [imageName stringByReplacingOccurrencesOfString:@":" withString:@"*"];
        }
        // Judge the image exist or not with the property_ID
        BOOL imageExist = [myfileMgr fileExistsAtPath:[imagePath stringByAppendingPathComponent:imageName]];
        if (imageExist) {
            dispatch_group_leave(group);
            if (!tanslate) {
                KCEmojiModel *recentEmoji = [KCEmojiModel emojiModelWithOnlineProperty:property];
//                recentEmoji.comeFrom = SMComeFromEscape;
                [finalRecentModelArray addObject:recentEmoji];
            }
        }
        else{
            KCOnlineImageInfo *imageData = property.imageData;
            NSURL *imageUrl = [NSURL URLWithString:imageData.img_id];
            SDWebImageManager *imgMgr = [SDWebImageManager sharedManager];
            [imgMgr downloadImageWithURL:imageUrl options:SDWebImageContinueInBackground progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                if (finished) {
                    NSData *data = UIImagePNGRepresentation(image);
                   BOOL createImageSuccess =  [data writeToFile:[imagePath stringByAppendingPathComponent:imageName] atomically:YES];
                    if (createImageSuccess) {
                        dispatch_group_leave(group);
//                        NSLog(@"dispatch_group_leave--------fnishedfnished=====idx====%d",idx);
                    }
                    if (!tanslate) {
                        KCEmojiModel *recentEmoji = [KCEmojiModel emojiModelWithOnlineProperty:property];
                        [finalRecentModelArray addObject:recentEmoji];
                    }

                }
            }];
            
        }
    }
    
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        NSLog(@"------------nofify--------------------------nofify--------------");
        if (tanslate) {
            if (translateDone) {
                translateDone(YES);
            }
        return;
        }
        else{
            if (self.requestEmojiModelArrayBlk) {
                self.requestEmojiModelArrayBlk(finalRecentModelArray);
            }
            return;
        }
    });
    
}


- (void)requestPropertyArrayWithKeyword:(NSString *)keyword emojiModelBlk:(RequestEmojiModelArrayBlock)requestEmojiModelArrayBlk
{
    self.requestEmojiModelArrayBlk = requestEmojiModelArrayBlk;
    [self requestPropertyArrayWithKeyword:keyword isTranslate:NO translateDone:nil];
}

- (void)clearDownloadKeywordsArray{
    [_dowloadKeywordDict removeAllObjects];
}



+(KCOnlinePropertyData *)localRequestPropertyDataWithPropertyID:(NSString *)property_id{
    
    NSString *json = [[KCPropertyManager sharePropertyMgr] localJsonWithPropertyID:property_id];
    if (!json) {
        return nil;
    }
    else{
        NSDictionary *dict = [NSString dictionaryWithJsonString:json];
        KCOnlinePropertyData *property = [KCOnlinePropertyData mj_objectWithKeyValues:dict];
       return property;
    }
}

- (NSString *)localJsonWithPropertyID:(NSString *)property_id{

    __block NSString *jsonStr;
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:@"SELECT json FROM t_id_to_propertydata WHERE property_id =?",property_id];
        while ([set next]) {
            jsonStr = [set stringForColumn:@"json"];
            break;
        }
    }];
    if (jsonStr) {
        return jsonStr;
    }
    return nil;
}

+(void)onlineRequestPropertyDataWithPropertyArray:(NSArray *)propertyArray{
    __block int doneCount = 0;
    for (NSString *property_id in propertyArray) {
        // Cache
        if ([[KCPropertyManager sharePropertyMgr]->_propertyRequestCacheArray containsObject:property_id]) {
            continue;
        }
        AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
        mgr.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        params[@"id"] = property_id;
        params[@"app_key"] = APP_KEY;
        [mgr GET:PROPERTY_URL parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            if (responseObject) {
                NSDictionary *testDict = ((NSDictionary *)responseObject);
                KCOnlinePropertyData *property = [KCOnlinePropertyData mj_objectWithKeyValues:testDict];
                NSString *json = [testDict mj_JSONString];
                [[KCPropertyManager sharePropertyMgr] updateID:property.property_id json:json];
                KCOnlineImageInfo *imageData = property.imageData;
                NSURL *imageUrl = [NSURL URLWithString:imageData.img_id];
                SDWebImageManager *imgMgr = [SDWebImageManager sharedManager];

                [imgMgr downloadImageWithURL:imageUrl options:SDWebImageContinueInBackground progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                    
                } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                    if (finished) {
                        NSFileManager *myFileMgr = [NSFileManager defaultManager];
                        if (![myFileMgr fileExistsAtPath:ImageCachePath]) {
                            [myFileMgr createDirectoryAtPath:ImageCachePath withIntermediateDirectories:NO attributes:nil error:NULL];
                        }
                        NSData *data = UIImagePNGRepresentation(image);
                        NSString *imageName = [NSString stringWithFormat:@"%@@2x.png",property_id];
                        if ([imageName containsString:@":"]) {
                            imageName = [imageName stringByReplacingOccurrencesOfString:@":" withString:@"*"];
                        }
                        BOOL success = [data writeToFile:[ImageCachePath stringByAppendingPathComponent:imageName] atomically:YES];
                        if (success) {
                            doneCount++;
                        [[KCPropertyManager sharePropertyMgr]->_propertyRequestCacheArray addObject:property_id];
                            if (doneCount == propertyArray.count) {
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"DownloadImageByPropertyIDDoneNotification" object:nil];
                                [[KCPropertyManager sharePropertyMgr]->_propertyRequestCacheArray removeAllObjects];
                            }
                        }
                    }
                }];
            }
            
        } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            NSLog(@"error++==============%@",error);
        }];

    }
    
}


- (NSArray *)requestDownloadedEmojiArrayWithKeyword:(NSString *)keyword comeFrom:(SMComeFrom)comeFrom;{
    // 1.get json
    NSString *json = [self jsonResultWithKeyword:keyword];
    NSDictionary *dict = [NSString dictionaryWithJsonString:json];
    int cand_count = [dict[@"cand_count"] intValue];
    NSMutableArray *emojiArray = [NSMutableArray array];

    for (int i = 0; i < cand_count; i ++) {
        NSString *key = [NSString stringWithFormat:@"%d",i + 1];
        NSDictionary *testDict = dict[key];
        KCOnlinePropertyData *property = [KCOnlinePropertyData mj_objectWithKeyValues:testDict];
        property.keyword = keyword;
        if (!property) continue;
        KCEmojiModel *emoji = [KCEmojiModel emojiModelWithOnlineProperty:property];
        emoji.comeFrom = comeFrom;
        if (emoji) {
            [emojiArray addObject:emoji];
        }
    }
    return emojiArray;
}

- (NSArray *)queryHotWordArrayWithHotWord:(NSString *)hotWord{
    NSMutableArray *arrayM = [NSMutableArray array];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM t_local_hot_word WHERE hot_word LIKE '%@%%';", hotWord];
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:sql];
        while ([set next]) {
            NSString *result = [set stringForColumn:@"hot_word"];
            [arrayM addObject:result];
        }
    }];
    return (NSArray *)arrayM;
}

- (void)clearImageCache{
    NSFileManager *myfileMgr = [NSFileManager defaultManager];
    BOOL exist = [myfileMgr fileExistsAtPath:ImageCachePath];
    NSError *error;
    if (exist) {
        BOOL success =  [myfileMgr removeItemAtPath:ImageCachePath error:&error];
        if (success) {
            NSLog(@"Clear Image cache Success");
            return;
        }
        NSLog(@"Clear Image cache error:%@",error);
    }
    return;
}
- (NSString *)stringFromDate:(NSDate *)date{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    NSString *destDateString = [dateFormatter stringFromDate:date];
    return destDateString;
}

- (NSDate *)dateFromString:(NSString *)dateString{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    NSDate *destDate= [dateFormatter dateFromString:dateString];
    return destDate;
}



- (void)updateImageNameAndUseDateWithEmojiModel:(KCEmojiModel *)emoji{

    NSString *imageName = emoji.emojiImageName;
    if (imageName == nil) {
        return;
    }
    if (![imageName containsString:@"*"]) {
        return;
    }
    NSDate *date = [NSDate date];
    NSString *dateStr = [self stringFromDate:date];
    [self.queue inDatabase:^(FMDatabase *db) {
        
        BOOL exist = NO;
        FMResultSet *set = [db executeQuery:@"SELECT * FROM img_use_time WHERE imageName =?",imageName];
        while ([set next]) {
            NSString *updateSql =[NSString stringWithFormat:@"update img_use_time set lastUseTime = '%@' where imageName = '%@';",dateStr,imageName];
            exist = YES;
            [db executeUpdate:updateSql];
        }
        
        if (!exist) {
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO img_use_time (imageName, lastUseTime) VALUES('%@','%@')",imageName,dateStr];
            [db executeUpdate:sql];
        }
    }];
    

}
- (void)clearImagesIfMoreThan1M{
    
    __block NSMutableArray * array = [NSMutableArray array];
    __block  NSMutableArray *imageNameArray = [NSMutableArray array];
    [self.queue inDatabase:^(FMDatabase *db) {
        FMResultSet *set = [db executeQuery:@"SELECT * FROM img_use_time;"];
        while ([set next]) {
            NSString *imageName = [set stringForColumn:@"imageName"];
            [imageNameArray addObject:imageName];
            NSString *lastUseTime = [set stringForColumn:@"lastUseTime"];
            NSDictionary *tempDict = @{@"imageName":imageName,@"lastUseTime":lastUseTime};
            [array addObject:tempDict];
        }
        
        [db executeUpdate:@"DELETE FROM img_use_time"];
    }];
    

    [array sortUsingComparator:^NSComparisonResult(NSDictionary *dict1, NSDictionary *dict2) {
        NSString *time1 = dict1[@"lastUseTime"];
        NSString *time2 = dict2[@"lastUseTime"];
        NSDate *date1 = [self dateFromString:time1];
        NSDate *date2 = [self dateFromString:time2];
        return [date2 compare:date1];
    }];
    NSMutableArray *newArray = [NSMutableArray array];
    NSFileManager *myfileMgr = [NSFileManager defaultManager];
    BOOL exist = [myfileMgr fileExistsAtPath:ImageCachePath];
    if (!exist) {
        return;
    }
    NSError *error;
    NSArray *filesArray = [myfileMgr directoryContentsAtPath:ImageCachePath];
    for (NSString *fileName in filesArray) {
        NSRange range = [fileName rangeOfString:@"@2x.png"];
        if (range.location != NSNotFound) {
            NSString *tempName = [fileName substringToIndex:range.location];
            if (![imageNameArray containsObject:tempName]) {
                [myfileMgr removeItemAtPath:[ImageCachePath stringByAppendingPathComponent:fileName] error:&error];
            }
        }
        else{
             [myfileMgr removeItemAtPath:[ImageCachePath stringByAppendingPathComponent:fileName] error:&error];
        }
 
    }
    
    for (NSDictionary *dict in array) {
        NSString *imgName = [dict[@"imageName"] stringByAppendingString:@"@2x.png"];
        long long nowImageSize = [self imageCacheFileSize];
        if (nowImageSize > 1000 * 10) {
            if ([myfileMgr fileExistsAtPath:[ImageCachePath stringByAppendingPathComponent:imgName]]) {
                [myfileMgr removeItemAtPath:[ImageCachePath stringByAppendingPathComponent:imgName] error:&error];
                if (error) {
                    NSLog(@"delete Image %@ error",imgName);
                }
            }
        }
        else{
            if ([myfileMgr fileExistsAtPath:[ImageCachePath stringByAppendingPathComponent:imgName]]) {
                [newArray addObject:dict];
            }
        }
        
    }
    
    
    [newArray sortUsingComparator:^NSComparisonResult(NSDictionary *dict1, NSDictionary *dict2) {
        
        NSString *time1 = dict1[@"lastUseTime"];
        NSString *time2 = dict2[@"lastUseTime"];
        NSDate *date1 = [self dateFromString:time1];
        NSDate *date2 = [self dateFromString:time2];
        return [date1 compare:date2];
    }];

    [self.queue inDatabase:^(FMDatabase *db) {
        for (NSDictionary *dict in newArray) {
            NSString *imgName = dict[@"imageName"];
            NSString *lastUseTime = dict[@"lastUseTime"];
            NSString *sql = [NSString stringWithFormat:@"INSERT INTO img_use_time (imageName, lastUseTime) VALUES('%@','%@')",imgName,lastUseTime];
            [db executeUpdate:sql];
        }
       
    }];
}
- (long long)imageCacheFileSize{
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:ImageCachePath]){
        NSError *error;
        
        NSEnumerator *childFilesEnumerator =  [[manager subpathsAtPath:ImageCachePath] objectEnumerator];
        NSString *fileName;
        long long folderSize = 0;
        while ((fileName = [childFilesEnumerator nextObject]) != nil) {
            NSString *fileAbsolutePath = [ImageCachePath stringByAppendingPathComponent:fileName];
            folderSize += [self fileSizeAtPath:fileAbsolutePath];
        }
        if (error) {
            NSLog(@"Get image cache size error:%@",error);
        }
        return folderSize;
    }
    return 0;
}


- (long long)fileSizeAtPath:(NSString *)filePath{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSError *error;
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:&error] fileSize];
    }
    return 0;
}
@end
