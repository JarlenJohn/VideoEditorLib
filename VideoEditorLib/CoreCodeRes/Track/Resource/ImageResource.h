//
//  ImageResource.h
//  VideoEditor
//
//  Created by zhuzhanlong on 8/16/21.
//

#import "Resource.h"

NS_ASSUME_NONNULL_BEGIN

@interface ImageResource : Resource

@property (nonatomic, strong) CIImage *image;

- (instancetype)initWithImage:(CIImage *)image duration:(CMTime)duration;

@end

NS_ASSUME_NONNULL_END
