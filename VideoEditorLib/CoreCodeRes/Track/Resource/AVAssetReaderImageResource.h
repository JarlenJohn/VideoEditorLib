//
//  AVAssetReaderImageResource.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/20/21.
//

#import "ImageResource.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVAssetReaderImageResource : ImageResource

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVVideoComposition *videoComposition;

- (instancetype)initWithAsset:(AVURLAsset *)asset;
@end

NS_ASSUME_NONNULL_END
