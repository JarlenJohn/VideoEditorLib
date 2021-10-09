//
//  AVAssetTrackResource.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/9/21.
//

#import "AVAssetTrackResource.h"

@implementation AVAssetTrackResource

- (instancetype)initWithAsset:(AVAsset *)asset {
    if (self = [super init]) {
        self.asset = asset;
        CMTime duration = CMTimeMakeWithSeconds(CMTimeGetSeconds(asset.duration), 600);
        self.duration = duration;
        self.selectedTimeRange = CMTimeRangeMake(kCMTimeZero, duration);
    }
    return self;
}


#pragma mark - Load Media before use resource
- (ResourceTask *)prepareWithProgressHandler:(void (^)(double))progressHandler
                                  completion:(void (^)(ResourceStatus, NSError * _Nonnull))completionHandler {
    if (self.asset) {
        __weak typeof(self) weakSelf = self;
        [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks", @"duration"] completionHandler:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            
            void (^finished)(void) = ^{
                if(self.asset.tracks.count > 0) {
                    AVAssetTrack *videoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
                    if (videoTrack) {
                        strongSelf.size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
                    }
                    strongSelf.status = ResourceStatusAvaliable;
                    strongSelf.duration = self.asset.duration;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completionHandler) {
                        completionHandler(strongSelf.status, strongSelf.statusError);
                    }
                });
            };
            
            NSError *error = nil;
            AVKeyValueStatus trackStatus = [self.asset statusOfValueForKey:@"tracks" error:&error];
            if (trackStatus != AVKeyValueStatusLoaded) {
                strongSelf.statusError = error;
                strongSelf.status = ResourceStatusUnavaliable;
                NSLog(@"Failed to load tracks, error:%@", error);
                
                finished();
                return;
            }
            
            AVKeyValueStatus durationStatus = [self.asset statusOfValueForKey:@"duration" error:&error];
            if (durationStatus != AVKeyValueStatusLoaded) {
                strongSelf.statusError = error;
                strongSelf.status = ResourceStatusUnavaliable;
                NSLog(@"Failed to load duration, error:%@", error);

                finished();
                return;
            }
            finished();
        }];
        
        return [[ResourceTask alloc] initWithCancelHandler:^{
            [self.asset cancelLoading];
        }];
    }else {
        completionHandler(self.status, self.statusError);
    }
    return nil;
}



#pragma mark - Content provider
- (NSArray<AVAssetTrack *> *)tracksForType:(AVMediaType)type {
    if (self.asset) {
        return [self.asset tracksWithMediaType:type];
    }
    
    return @[];
}


#pragma mark - ResourceTrackInfoProvider
- (ResourceTrackInfo *)trackInfoForType:(AVMediaType)type atIndex:(NSUInteger)index {
    AVAssetTrack *track = [self tracksForType:type][index];
    
    ResourceTrackInfo *info = (ResourceTrackInfo *)malloc(sizeof(ResourceTrackInfo));
    info->track = track;
    info->selectedTimeRange = self.selectedTimeRange;
    info->scaleToDuration = self.scaledDuration;
    return info;
}

#pragma mark - Coping
- (id)copyWithZone:(NSZone *)zone {
    AVAssetTrackResource *resource = [super copyWithZone:zone];
    resource.asset = self.asset;
    return resource;
}

@end
