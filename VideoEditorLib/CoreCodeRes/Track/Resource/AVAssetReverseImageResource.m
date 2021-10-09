//
//  AVAssetReverseImageResource.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/19/21.
//

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreImage/CoreImage.h>
#import "AVAssetReverseImageResource.h"


@interface AVAssetReverseImageResource()

@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetReaderTrackOutput *trackOutput;
@property (nonatomic, strong) NSMutableArray *sampleBuffers;
@property (nonatomic, assign) CMTime lastReaderTime;
@property (nonatomic, assign) CMTime bufferDuration;
@property (nonatomic, copy) dispatch_queue_t loadBufferQueue;
@property (nonatomic, assign) BOOL isPreloading;

@end

@implementation AVAssetReverseImageResource

- (instancetype)initWithAsset:(AVURLAsset *)asset {
    if (self = [super init]) {
        self.asset = asset;
        CMTime duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration), 600);
        self.selectedTimeRange = CMTimeRangeMake(kCMTimeZero, duration);
          
        _lastReaderTime = kCMTimeZero;
        _bufferDuration = CMTimeMakeWithSeconds(0.3, 600);
        _isPreloading = NO;
    }
    return self;
}

#pragma mark - ResourceTrackInfoProvider
- (CIImage *)imageAtTime:(CMTime)time renderSize:(CGSize)renderSize {
    CMTime timelineTime = [self sourceTimeForTimelineTime:time];
    if (!CMTIME_COMPARE_INLINE(self.selectedTimeRange.duration, >, timelineTime)) {
        return nil;
    }
    
    CMTime maximumTime = CMTimeMaximum(kCMTimeZero, CMTimeSubtract(CMTimeRangeGetEnd(self.selectedTimeRange), timelineTime));
    CMTime realTime = CMTimeAdd(maximumTime, self.selectedTimeRange.start);
    
    CMSampleBufferRef sampleBuffer = [self loadSamplebufferForTime:realTime];
    if (sampleBuffer != NULL) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        if (imageBuffer) {
            return [CIImage imageWithCVPixelBuffer:imageBuffer];
        }
    }
    
    return self.image;
}

- (CMSampleBufferRef)loadSamplebufferForTime:(CMTime)time {
    //1.if seeking backward, reset
    __weak typeof(self) weakSelf = self;
    if (CMTIME_COMPARE_INLINE(time, >, self.lastReaderTime)) {
        dispatch_sync(self.loadBufferQueue, ^{
            [weakSelf cleanReader];
            [weakSelf.sampleBuffers removeAllObjects];
        });
    }
    
    self.lastReaderTime = time;
    
    //2.get current samplebuffer
    __block CMSampleBufferRef currentSampleBuffer = [self getCurrentSampleBufferAtTime:time];
    if (currentSampleBuffer != NULL) {
        [self removeUnusedBuffersAtTime:time];
        
        // preload if need
        [self preloadSampleBuffersAtTime:time];
        
        return currentSampleBuffer;
    }
    
    // 3. Not preload yet, force load
    dispatch_sync(self.loadBufferQueue, ^{
        currentSampleBuffer = [self getCurrentSampleBufferAtTime:time];
        if(!currentSampleBuffer) {
            [self forceLoadSampleBufferAtTime:time];
        }
    });
    
    if (currentSampleBuffer) {
        return currentSampleBuffer;
    }
    
    currentSampleBuffer = [self getCurrentSampleBufferAtTime:time];
    [self preloadSampleBuffersAtTime:time];
    [self removeUnusedBuffersAtTime:time];
    
    return currentSampleBuffer;
}

- (void)cleanReader {
    [self.assetReader cancelReading];
    self.assetReader = nil;
    self.trackOutput = nil;
}

- (CMSampleBufferRef _Nullable)getCurrentSampleBufferAtTime:(CMTime)time {
    CMSampleBufferRef currentBuffer = NULL;
    NSArray *sampleBuffers = [[NSArray alloc] initWithArray:self.sampleBuffers];
    for (int i=0; i<sampleBuffers.count; i++) {
        CMSampleBufferRef sampleBuffer = (__bridge CMSampleBufferRef)(sampleBuffers[i]);
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        
        if (fabs(CMTimeGetSeconds(pts) - CMTimeGetSeconds(time)) < 0.05) {
            currentBuffer = sampleBuffer;
            break;
        }
    }
    return currentBuffer;
}

-(void)removeUnusedBuffersAtTime:(CMTime)time {
    dispatch_async(self.loadBufferQueue, ^{
        NSMutableArray *deleteSamBf = [[NSMutableArray array] init];
        for (int i=0; i<self.sampleBuffers.count; i++) {
            CMSampleBufferRef sampleBuffer = (__bridge CMSampleBufferRef)(self.sampleBuffers[i]);
            CGFloat pts = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
            if (pts > CMTimeGetSeconds(time) ||
                (pts < (CMTimeGetSeconds(self.selectedTimeRange.start) - CMTimeGetSeconds(self.bufferDuration) * 2))) {
                [deleteSamBf addObject:(__bridge id _Nonnull)(sampleBuffer)];
            }
        }
        
        [self.sampleBuffers removeObjectsInArray:deleteSamBf];
    });
}

//[AVAssetReader, AVAssetReaderTrackOutput]
- (NSArray *)createAssetReaderForTimeRange:(CMTimeRange)timeRange {
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:self.asset error:nil];
    AVAssetTrack *track = [self.asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (!self.asset || !reader || !track) {
        return @[[NSNull null], [NSNull null]];
    }

    CGSize size = track.naturalSize;
    size = CGSizeApplyAffineTransform(size, track.preferredTransform);
    
    NSDictionary *outputSettings = @{
        (id)kCVPixelBufferWidthKey : @(size.width),
        (id)kCVPixelBufferHeightKey : @(size.height)
    };
    AVAssetReaderTrackOutput *trackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:outputSettings];
    trackOutput.alwaysCopiesSampleData = NO;
    trackOutput.supportsRandomAccess = YES;
    
    if (![reader canAddOutput:trackOutput]) {
        return @[[NSNull null], [NSNull null]];
    }
    [reader addOutput:trackOutput];
    reader.timeRange = timeRange;
    
    return @[reader, trackOutput];
}

- (void)forceLoadSampleBufferAtTime:(CMTime)time {
    CMTime endTime = time;
    CMSampleBufferRef sampleBuffer = (__bridge CMSampleBufferRef)(self.sampleBuffers.lastObject);
    if (sampleBuffer) {
        endTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    }
    
    double startSeconds = MAX(CMTimeGetSeconds(endTime) - CMTimeGetSeconds(self.bufferDuration), CMTimeGetSeconds(self.selectedTimeRange.start));
    CMTime startTime = CMTimeMakeWithSeconds(startSeconds, 600);
    CMTimeRange timeRange = CMTimeRangeFromTimeToTime(startTime, endTime);
    NSArray *reader = [self createAssetReaderForTimeRange:timeRange];
    
    AVAssetReader *assetReader = [reader objectAtIndex:0];
    AVAssetReaderTrackOutput *trackOutput = [reader objectAtIndex:1];
    if (assetReader && trackOutput) {
        [assetReader startReading];
        
        CMSampleBufferRef sampleBuffer = trackOutput.copyNextSampleBuffer;
        while (sampleBuffer) {
            if (!CMSampleBufferGetImageBuffer(sampleBuffer)) {
                [self.sampleBuffers insertObject:(__bridge id _Nonnull)(sampleBuffer) atIndex:0];
            }
            
            sampleBuffer = trackOutput.copyNextSampleBuffer;
        }
        
        [self.sampleBuffers sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            CMSampleBufferRef sampleBuffer1 = (__bridge CMSampleBufferRef)(obj1);
            CMSampleBufferRef sampleBuffer2 = (__bridge CMSampleBufferRef)obj2;
            
            CMTime sampleTime1 = CMSampleBufferGetPresentationTimeStamp(sampleBuffer1);
            CMTime sampleTime2 = CMSampleBufferGetPresentationTimeStamp(sampleBuffer2);
            if (CMTIME_COMPARE_INLINE(sampleTime1, <, sampleTime2)) {
                return NSOrderedDescending;
            }else if(CMTIME_COMPARE_INLINE(sampleTime1, >, sampleTime2)) {
                return NSOrderedAscending;
            }else {
                return NSOrderedSame;
            }
        }];
        
        [assetReader cancelReading];
    }
}

-(void)preloadSampleBuffersAtTime:(CMTime)time {
    if (self.isPreloading) {
        return;
    }
    
    BOOL needPreload = NO;
    CMSampleBufferRef sampleBuffer = (__bridge CMSampleBufferRef)(self.sampleBuffers.lastObject);
    if (sampleBuffer) {
        CGFloat pts = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer));
        needPreload = pts > 0 && pts > CMTimeGetSeconds(time) - CMTimeGetSeconds(self.bufferDuration);
    }else {
        needPreload = YES;
    }
    if (!needPreload) {
        return;
    }
    
    self.isPreloading = YES;
    dispatch_async(self.loadBufferQueue, ^{
        if (!self.assetReader || !self.trackOutput) {
            [self createAssetReaderOutputAtTime:time];
        }else {
            [self resetReaderAtTime:time];
        }
        
        if (!self.assetReader || !self.trackOutput) {
            return;
        }
        
        CMSampleBufferRef sampleBuffer = self.trackOutput.copyNextSampleBuffer;
        while (sampleBuffer) {
            if (!CMSampleBufferGetImageBuffer(sampleBuffer)) {
                [self.sampleBuffers addObject:(__bridge id _Nonnull)(sampleBuffer)];
            }
            
            sampleBuffer = self.trackOutput.copyNextSampleBuffer;
        }
        
        [self.sampleBuffers sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            CMSampleBufferRef sampleBuffer1 = (__bridge CMSampleBufferRef)(obj1);
            CMSampleBufferRef sampleBuffer2 = (__bridge CMSampleBufferRef)obj2;
            
            CMTime sampleTime1 = CMSampleBufferGetPresentationTimeStamp(sampleBuffer1);
            CMTime sampleTime2 = CMSampleBufferGetPresentationTimeStamp(sampleBuffer2);
            if (CMTIME_COMPARE_INLINE(sampleTime1, <, sampleTime2)) {
                return NSOrderedDescending;
            }else if(CMTIME_COMPARE_INLINE(sampleTime1, >, sampleTime2)) {
                return NSOrderedAscending;
            }else {
                return NSOrderedSame;
            }
        }];
        
        self.isPreloading = NO;
    });
}

- (void)createAssetReaderOutputAtTime:(CMTime)time {
    double startSeconds = MAX(CMTimeGetSeconds(time)-CMTimeGetSeconds(self.bufferDuration), CMTimeGetSeconds(self.selectedTimeRange.start));
    CMTime startTime = CMTimeMakeWithSeconds(startSeconds, 600);
    CMTimeRange timeRange = CMTimeRangeFromTimeToTime(startTime, time);
    NSArray *reader = [self createAssetReaderForTimeRange:timeRange];
    self.assetReader = [reader objectAtIndex:0];
    self.trackOutput = [reader objectAtIndex:1];
    
    [self.assetReader startReading];
}

- (void)resetReaderAtTime:(CMTime)time {
    if (!self.trackOutput) {
        return;
    }
    
    CMTime endTime = time;
    
    CMSampleBufferRef sampleBuffer = (__bridge CMSampleBufferRef)(self.sampleBuffers.lastObject);
    if (sampleBuffer) {
        endTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    }
    double startSeconds = MAX(CMTimeGetSeconds(endTime)-CMTimeGetSeconds(self.bufferDuration), CMTimeGetSeconds(self.selectedTimeRange.start));
    CMTime startTime = CMTimeMakeWithSeconds(startSeconds, 600);
    
    CMTimeRange timeRange = CMTimeRangeFromTimeToTime(startTime, endTime);
    [self.trackOutput resetForReadingTimeRanges:@[[NSValue valueWithCMTimeRange:timeRange]]];
}


#pragma mark - Lazy load
- (dispatch_queue_t)loadBufferQueue {
    if (!_loadBufferQueue) {
        _loadBufferQueue = dispatch_queue_create("com.digiarty.mobilegroup.loadbuffer", NULL);
    }
    return _loadBufferQueue;
}

- (NSMutableArray *)sampleBuffers {
    if (!_sampleBuffers) {
        _sampleBuffers = [[NSMutableArray alloc] init];
    }
    return _sampleBuffers;
}

#pragma mark - Load Media before use resource
- (ResourceTask *)prepareWithProgressHandler:(void (^)(double))progressHandler completion:(void (^)(ResourceStatus status, NSError * _Nonnull error))completionHandler {
    NSLog(@"");
    return nil;
}

#pragma mark - NSCopy
- (id)copyWithZone:(NSZone *)zone {
    AVAssetReverseImageResource *resource = [[super class] allocWithZone:zone];
    resource.asset = self.asset;
    resource.bufferDuration = self.bufferDuration;
    return resource;
}

@end
