//
//  Timeline.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/8/21.
//

#import "Timeline.h"


@implementation Timeline


- (instancetype)init {
    if (self = [super init]) {
        self.renderSize = CGSizeMake(960, 540);
        self.backgroundColor = [CIColor colorWithRed:0 green:0 blue:0];
    }
    return self;
}

@end

@implementation Timeline (SortTime)
+ (void)reloadVideoStartTimeWithProviders:(NSArray <id<TransitionableVideoProvider>>*)providers {
    [self reloadStartTimeWithProviders:providers transitionTime:^CMTime(NSInteger index) {
        if (providers[index].videoTransition) {
            return providers[index].videoTransition.duration;
        }
        return kCMTimeZero;
    }];
}

+ (void)reloadAudioStartTimeWithProviders:(NSArray <id<TransitionableAudioProvider>>*)providers {
    [self reloadStartTimeWithProviders:providers transitionTime:^CMTime(NSInteger index) {
        if (providers[index].audioTransition) {
            return providers[index].audioTransition.duration;
        }
        return kCMTimeZero;
    }];
}

+ (void)reloadStartTimeWithProviders:(NSArray <id <CompositionTimeRangeProvider>>*)providers transitionTime:(CMTime (^)(NSInteger index))transitionTime {
    CMTime position = kCMTimeZero;
    CMTime previousTransitionDuration = kCMTimeZero;
    
    //存放CMTimeRange
    NSMutableArray *timeRangeStack = [[NSMutableArray alloc] init];
    for (int index=0; index<providers.count; index++) {
        id <CompositionTimeRangeProvider> provider = providers[index];
        
        //优先级:前一个转场具有优先级。如果剪辑没有足够的时间进行开始转场和结束转场，那么将首先考虑开始转场。
        CMTime transitionDuration = kCMTimeZero;
        if (CMTIME_IS_VALID(transitionTime(index))) {
            transitionDuration = transitionTime(index);
        }
        
        CMTime providerDuration = provider.timeRange.duration;
        if (CMTIME_COMPARE_INLINE(providerDuration, <, transitionDuration)) {
            transitionDuration = kCMTimeZero;
        }else {
            if (index < providers.count-1) {
                id <CompositionTimeRangeProvider> nextProvider = providers[index+1];
                if (CMTIME_COMPARE_INLINE(nextProvider.timeRange.duration, <, transitionDuration)) {
                    transitionDuration = kCMTimeZero;
                }
            }else {
                transitionDuration = kCMTimeZero;
            }
        }
        
        position = CMTimeSubtract(position, previousTransitionDuration);
        provider.startTime = position;
        
        /*
         Check whether the position is correct.
         This scenario can't support
         track1 --------
         track2     ------
         track3       ---------
         */
        if (timeRangeStack.count > 1) {
            CMTimeRange timeRange = [timeRangeStack[0] CMTimeRangeValue];
            if (CMTIME_COMPARE_INLINE(CMTimeRangeGetEnd(timeRange), >, position)) {
                NSString *t1 = [NSString stringWithFormat:@"%.2f-%.2f", CMTimeGetSeconds(timeRange.start), CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange))];
                
                CMTimeRange timeRange2 =  [timeRangeStack[1] CMTimeRangeValue];
                NSString *t2 = [NSString stringWithFormat:@"%.2f-%.2f", CMTimeGetSeconds(timeRange2.start), CMTimeGetSeconds(CMTimeRangeGetEnd(timeRange2))];
                
                NSString *t3 = [NSString stringWithFormat:@"%.2f-%.2f", CMTimeGetSeconds(provider.startTime), CMTimeGetSeconds(CMTimeAdd(provider.startTime, providerDuration))];
                
                NSString *localizedStr = [NSString stringWithFormat:@"Provider don't have enough time for transition. t1:\(%@), t2:\(%@), t3:\(%@)", t1, t2, t3];
                NSError *error = [NSError errorWithDomain:@"com.videoeditor.position" code:0 userInfo:@{NSLocalizedDescriptionKey:localizedStr}];
                @throw error;
            }
            [timeRangeStack removeObjectAtIndex:0];
        }
        [timeRangeStack addObject:[NSValue valueWithCMTimeRange:CMTimeRangeMake(position, providerDuration)]];
        previousTransitionDuration = transitionDuration;
        position = CMTimeAdd(position, providerDuration);
    }
}

@end
