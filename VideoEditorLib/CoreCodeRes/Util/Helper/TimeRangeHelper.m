//
//  CMTimeHelper.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/11/21.
//

#import "TimeRangeHelper.h"
#import <AVFoundation/AVFoundation.h>

@implementation TimeRangeHelper

+ (NSString *)vf_identifierFromTimeRange:(CMTimeRange)timeRange {
    return [NSString stringWithFormat:@"%.3f,%.3f", CMTimeGetSeconds(timeRange.start), CMTimeGetSeconds(timeRange.duration)];
}


/// Slice two time tanges into multiple time ranges, base on their intersection part
/// They maybe have 3 cases:
/// 1.one timeRange contains another.
/// 2.They have intersection timeRange partly
/// 3. They are same value
///
/// @param timeRange1 timeRange 1
/// @param timeRange2 timeRange 2
/// @return sliced time range array
+ (NSArray <NSValue *>*)sliceTimeRangesForTimeRange:(CMTimeRange)timeRange1 timeRange2:(CMTimeRange)timeRange2 {
    NSMutableArray <NSValue *>*timeRanges = [[NSMutableArray alloc] init];//CMTimeRange
    CMTimeRange instersectionTimeRange = CMTimeRangeGetIntersection(timeRange1, timeRange2);
    if (!CMTIMERANGE_IS_EMPTY(instersectionTimeRange)) {
        if (CMTimeRangeContainsTimeRange(timeRange2, timeRange1) ||
            (CMTIME_COMPARE_INLINE(timeRange1.start, <, timeRange2.start) && CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(timeRange1), <, CMTimeRangeGetEnd(timeRange2)))) {
            timeRanges = [self mixTimeRangesWithMinTimeRange:timeRange1 instersectionTimeRange:instersectionTimeRange maxTimeRange:timeRange2];
        }else {
            timeRanges = [self mixTimeRangesWithMinTimeRange:timeRange2 instersectionTimeRange:instersectionTimeRange maxTimeRange:timeRange1];
        }
    }else {
        [timeRanges addObject:[NSValue valueWithCMTimeRange:timeRange1]];
        [timeRanges addObject:[NSValue valueWithCMTimeRange:timeRange2]];
    }
    
    return timeRanges;
}

+ (NSMutableArray <NSValue *>*)mixTimeRangesWithMinTimeRange:(CMTimeRange)minTimeRange
                               instersectionTimeRange:(CMTimeRange)instersectionTimeRange
                                         maxTimeRange:(CMTimeRange)maxTimeRange {
    if (CMTimeRangeContainsTimeRange(maxTimeRange, minTimeRange)) {
        NSMutableArray <NSValue *>*timeRanges = [[NSMutableArray alloc] init];
        CMTime leftTimeRangeDuration = CMTimeSubtract(instersectionTimeRange.start, maxTimeRange.start);
        if (CMTimeGetSeconds(leftTimeRangeDuration) > 0) {
            CMTimeRange leftTimeRange = CMTimeRangeMake(maxTimeRange.start, leftTimeRangeDuration);
            [timeRanges addObject:[NSValue valueWithCMTimeRange:leftTimeRange]];
        }
        [timeRanges addObject:[NSValue valueWithCMTimeRange:instersectionTimeRange]];
        
        CMTime rightTimeRangeDuration = CMTimeSubtract(CMTimeRangeGetEnd(maxTimeRange), CMTimeRangeGetEnd(instersectionTimeRange));
        if (CMTimeGetSeconds(rightTimeRangeDuration) > 0) {
            CMTimeRange rightTimeRange = CMTimeRangeMake(CMTimeRangeGetEnd(instersectionTimeRange), rightTimeRangeDuration);
            [timeRanges addObject:[NSValue valueWithCMTimeRange:rightTimeRange]];
        }
        return timeRanges;
    }
    
    if (CMTimeRangeEqual(minTimeRange, maxTimeRange)) {
        return @[[NSValue valueWithCMTimeRange:instersectionTimeRange]].mutableCopy;
    }
    
    NSMutableArray <NSValue *>*timeRanges = [[NSMutableArray alloc] init];
    CMTime duration1 = CMTimeSubtract(minTimeRange.duration, instersectionTimeRange.duration);
    CMTimeRange timeRange1SubstructRange = CMTimeRangeMake(minTimeRange.start, duration1);
    if (!CMTIMERANGE_IS_EMPTY(timeRange1SubstructRange)) {
        [timeRanges addObject:[NSValue valueWithCMTimeRange:timeRange1SubstructRange]];
    }
    
    [timeRanges addObject:[NSValue valueWithCMTimeRange:instersectionTimeRange]];
    
    CMTime duration2 = CMTimeSubtract(CMTimeRangeGetEnd(maxTimeRange), CMTimeRangeGetEnd(instersectionTimeRange));
    CMTimeRange timeRange2SubstructRange = CMTimeRangeMake(CMTimeRangeGetEnd(instersectionTimeRange), duration2);
    if (!CMTIMERANGE_IS_EMPTY(timeRange2SubstructRange)) {
        [timeRanges addObject:[NSValue valueWithCMTimeRange:timeRange2SubstructRange]];
    }
    return timeRanges;
}

+ (NSArray<NSValue *> *)substructTimeRange:(CMTimeRange)timeRange from:(CMTimeRange)fromTimeRange {
    CMTimeRange intersectionTimeRange = CMTimeRangeGetIntersection(fromTimeRange, timeRange);
    if (CMTIMERANGE_IS_EMPTY(intersectionTimeRange)) {
        return @[[NSValue valueWithCMTimeRange:fromTimeRange]];
    }
    
    NSMutableArray <NSValue *>*timeRanges = [[NSMutableArray alloc] init];
    CMTimeRange leftTimeRange = CMTimeRangeFromTimeToTime(fromTimeRange.start, intersectionTimeRange.start);
    if (!CMTIMERANGE_IS_EMPTY(leftTimeRange)) {
        [timeRanges addObject:[NSValue valueWithCMTimeRange:leftTimeRange]];
    }
    
    CMTimeRange rightTimeRange = CMTimeRangeFromTimeToTime(CMTimeRangeGetEnd(intersectionTimeRange), CMTimeRangeGetEnd(fromTimeRange));
    if (!CMTIMERANGE_IS_EMPTY(rightTimeRange)) {
        [timeRanges addObject:[NSValue valueWithCMTimeRange:rightTimeRange]];
    }
    
    return timeRanges;
}

@end
