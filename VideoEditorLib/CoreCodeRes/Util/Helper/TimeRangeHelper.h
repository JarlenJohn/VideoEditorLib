//
//  CMTimeHelper.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/11/21.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimeRangeHelper : NSObject

+ (NSString *)vf_identifierFromTimeRange:(CMTimeRange)timeRange;


/// Slice two time tanges into multiple time ranges, base on their intersection part
/// They maybe have 3 cases:
/// 1.one timeRange contains another.
/// 2.They have intersection timeRange partly
/// 3. They are same value
///
/// @param timeRange1 timeRange 1
/// @param timeRange2 timeRange 2
/// @return sliced time range array
+ (NSArray <NSValue *>*)sliceTimeRangesForTimeRange:(CMTimeRange)timeRange1 timeRange2:(CMTimeRange)timeRange2;

+ (NSArray<NSValue *> *)substructTimeRange:(CMTimeRange)timeRange from:(CMTimeRange)fromTimeRange;

@end

NS_ASSUME_NONNULL_END
