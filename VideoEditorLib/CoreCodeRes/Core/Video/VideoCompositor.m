//
//  VideoCompositor.m
//  VideoEditor
//
//  Created by zhuzhanlong on 8/11/21.
//

#import "VideoCompositor.h"
#import "VideoCompositionInstruction.h"

static CIContext *ciContext;

@interface VideoCompositor ()

@property (nonatomic, strong) dispatch_queue_t renderContextQueue;
@property (nonatomic, strong) dispatch_queue_t renderingQueue;
@property (nonatomic, assign) BOOL renderContextDidChange;
@property (nonatomic, assign) BOOL shouldCancelAllRequests;
@property (nonatomic, strong) AVVideoCompositionRenderContext *renderContext;

//AVVideoCompositing
@property (nonatomic, strong, nullable) NSDictionary<NSString *, id> *sourcePixelBufferAttributes;
@property (nonatomic, strong) NSDictionary<NSString *, id> *requiredPixelBufferAttributesForRenderContext;

@end


@implementation VideoCompositor
@synthesize sourcePixelBufferAttributes = _sourcePixelBufferAttributes;
@synthesize requiredPixelBufferAttributesForRenderContext = _requiredPixelBufferAttributesForRenderContext;

+ (void)initialize {
    [super initialize];
    
    ciContext = [[CIContext alloc] init];
}

- (instancetype)init {
    if (self = [super init]) {
        _renderContextQueue = dispatch_queue_create("videoeditor.videocore.rendercontextqueue", NULL);
        _renderingQueue = dispatch_queue_create("videoeditor.videocore.renderingqueue", NULL);
        _renderContextDidChange = NO;
        _shouldCancelAllRequests = NO;
        
        _sourcePixelBufferAttributes = @{
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
            (id)kCVPixelBufferOpenGLESCompatibilityKey: @YES,
            (id)kCVPixelBufferMetalCompatibilityKey : @YES
        };
        _requiredPixelBufferAttributesForRenderContext = @{
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
            (id)kCVPixelBufferOpenGLESCompatibilityKey: @YES,
            (id)kCVPixelBufferMetalCompatibilityKey : @YES
        };
    }
    return self;
}

#pragma mark - AVVideoCompositing
- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext {
    __weak typeof(self)weakSelf = self;
    dispatch_sync(self.renderContextQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        
        strongSelf.renderContext = newRenderContext;
        strongSelf.renderContextDidChange = YES;
    });
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request {
    __weak typeof(self)weakSelf = self;
    dispatch_async(self.renderingQueue, ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.shouldCancelAllRequests) {
            [request finishCancelledRequest];
        } else {
            @autoreleasepool {
                CVPixelBufferRef resultPixels = [strongSelf newRenderedPixelBufferForRequest:request];
                if (resultPixels) {
                    [request finishWithComposedVideoFrame:resultPixels];
                } else {
                    NSError *error = [NSError errorWithDomain:@"com.Digiarty.videoEditor" code:0 userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(@"Composition request new pixel buffer failed.", nil)}];
                    [request finishWithError:error];
                    NSLog(@"%@", error);
                }
            }
        }
    });
}

- (void)cancelAllPendingVideoCompositionRequests {
    self.shouldCancelAllRequests = YES;
    __weak typeof(self)weakSelf = self;
    dispatch_barrier_async(self.renderingQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.shouldCancelAllRequests = NO;
    });
}

- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request {
    CVPixelBufferRef outputPixels = [self.renderContext newPixelBuffer];
    if (!outputPixels) {
        return NULL;
    }

    VideoCompositionInstruction *instruction = request.videoCompositionInstruction;;
    if (![instruction isKindOfClass:[VideoCompositionInstruction class]]) {
        return NULL;
    }

    CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:outputPixels];

    // Background
    CIImage *backgroundImage = [[CIImage imageWithColor:instruction.backgroundColor] imageByCroppingToRect:image.extent];
    image = backgroundImage;

    CIImage *destinationImage = [instruction applyRequest:request];
    if (destinationImage) {
        image = [destinationImage imageByCompositingOverImage:image];
    }

    [ciContext render:image toCVPixelBuffer:outputPixels];
    
    return outputPixels;
}

@end
