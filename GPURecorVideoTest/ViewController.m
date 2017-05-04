//
//  ViewController.m
//  GPURecorVideoTest
//
//  Created by yuelixing on 2017/5/4.
//  Copyright © 2017年 Ylx. All rights reserved.
//

#import "ViewController.h"
#import "Logger.h"
#import <GPUImage.h>
#import <AVKit/AVKit.h>
#import <MJRefresh.h>
#import "UIView+Frame.h"
#import "NSDate+Helper.h"

#define AppWidth                         ([[UIScreen mainScreen] bounds].size.width)
#define AppHeight                        ([[UIScreen mainScreen] bounds].size.height)

@interface ViewController () <GPUImageMovieWriterDelegate>

@property (nonatomic, retain) UIButton * recordButton;


//@property (nonatomic,strong) GPUImageCropFilter * cropfilter;
@property (nonatomic,strong) GPUImageFilter * cropfilter;
//@property (nonatomic,strong) GPUImageFilterGroup * filterGroup;
@property (nonatomic,strong) GPUImageView * preImageView;
@property (nonatomic,strong) GPUImageVideoCamera * videoCamera;
// 本地文件写入
@property (nonatomic, retain) GPUImageMovieWriter * movieWriter;

@property (nonatomic, retain) NSURL * movieURL;


@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, retain) NSTimer * countTimer;

@property (nonatomic, copy) NSString * tempVideopath;

@property (nonatomic, assign) BOOL flashOpened;

@property (nonatomic, assign) CGSize videoSize;

@property (nonatomic, assign) BOOL recordFinish;


@property (nonatomic, assign) CGFloat maxDuration;

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.videoCamera) {
        [self.videoCamera resumeCameraCapture];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.videoCamera) {
        [self.videoCamera pauseCameraCapture];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.videoSize = CGSizeMake(400, 400);
    self.maxDuration = 16.0;

    self.isRecording = NO;
    
//    self.tempVideopath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"oring_movie.mp4"];
    self.tempVideopath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"oring_movie.mov"];
    self.movieURL = [NSURL fileURLWithPath:self.tempVideopath];
    
    [self createView];
    [self loadCamera];
    
//    [self compressVideo:self.tempVideopath Finish:^(NSString *targetpath) {
//        NSLog(@"%@", targetpath);
//    }];
}


#pragma mark - buttonClick:

- (void)startRecordVideo {

    [self deleteFilePath:self.tempVideopath];
    
    [self.movieWriter startRecording];
    
    self.recordFinish = NO;
    self.countTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFly) userInfo:nil repeats:YES];
}
- (void)endRecordVideo {
    if (self.recordFinish) {
        NSLog(@"录制已结束");
        return;
    }
    
    
    [self.countTimer invalidate];
    self.countTimer = nil;
    [self.movieWriter finishRecordingWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            CGFloat value = self.movieWriter.duration.value/(CGFloat)self.movieWriter.duration.timescale;
            
            NSLog(@"录制结束 %.2f", value);
            
            AVURLAsset * asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.tempVideopath]];
            value = asset.duration.value*1.0/asset.duration.timescale;
            NSLog(@"录制结束 asset.duration : %.2f", value);
            
            self.recordFinish = YES;
            
            self.movieWriter = nil;
            self.movieWriter = [self getMovieWriter];
            
            [self.cropfilter addTarget:self.movieWriter];
            self.videoCamera.audioEncodingTarget = self.movieWriter;
        });
    }];
}

- (void)timerFly {
    CGFloat value = self.movieWriter.duration.value/(CGFloat)self.movieWriter.duration.timescale;
    NSString * temp = nil;
    if (self.movieWriter.assetWriter.status == AVAssetWriterStatusUnknown) {
        temp = @"Unknown";
    } else if (self.movieWriter.assetWriter.status == AVAssetWriterStatusWriting) {
        temp = @"Writing";
    } else if (self.movieWriter.assetWriter.status == AVAssetWriterStatusCompleted) {
        temp = @"Completed";
    } else if (self.movieWriter.assetWriter.status == AVAssetWriterStatusFailed) {
        temp = @"Failed";
    } else {
        temp = @"Cancelled";
    }
    
    
    NSLog(@"%f %@", value, temp);
    
//    self.progressView.currentValue = value;
    if (value >= self.maxDuration) {
        [self.countTimer invalidate];
        self.countTimer = nil;
        [self endRecordVideo];
    }
}


// MARK: - 加载

// 加载相机
- (void)loadCamera { // 初始化 videoCamera
    [self loadCameraWithPosition:AVCaptureDevicePositionBack];
}

- (void)loadCameraWithPosition:(AVCaptureDevicePosition)position {
    if (self.videoCamera) {
        [self.videoCamera stopCameraCapture];
        [self.videoCamera removeAllTargets];
        self.videoCamera = nil;
    }
    if (self.cropfilter) {
        [self.cropfilter removeAllTargets];
        self.cropfilter = nil;
    }
    //    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:position];
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:position];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.horizontallyMirrorRearFacingCamera  = NO;
//    self.videoCamera.runBenchmark = YES;
    
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(self.videoCamera.inputCamera.activeFormat.formatDescription);
    
    CGSize originSize = CGSizeMake(MIN(dimensions.width, dimensions.height), MAX(dimensions.width, dimensions.height));
    
    self.videoSize = CGSizeMake(originSize.width, originSize.width);
    NSLog(@"originSize : %@", NSStringFromCGSize(originSize));
    NSLog(@"videoSize : %@", NSStringFromCGSize(self.videoSize));
    
    //    CGSize videoSize = CGSizeMake(<#CGFloat width#>, <#CGFloat height#>)
    // 最后的输出视频是 400*400
    //    CGFloat top = (640-self.videoSize.height)/2.0/640.0;
    //    CGFloat width = self.videoSize.width/480.0;
    //    CGFloat height = self.videoSize.height/640.0;
//    CGFloat top = (originSize.height-originSize.width)/2.0/originSize.height;
//    CGFloat width = 1;
//    CGFloat height = originSize.width/originSize.height;
//    self.cropfilter = [[GPUImageCropFilter alloc] initWithCropRegion:CGRectMake(0, top, width, height)];
    
    self.cropfilter = [[GPUImageSepiaFilter alloc] init];
    
    [self.videoCamera addTarget:self.cropfilter];
    [self.cropfilter addTarget:self.preImageView];
    
    // 开始进行相机捕获
    [self.videoCamera startCameraCapture];
    
    self.flashOpened = NO;
    
    if (self.movieWriter) {
        [self.movieWriter cancelRecording];
        self.movieWriter = nil;
    }
    self.movieWriter = [self getMovieWriter];
    
    [self.cropfilter addTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = self.movieWriter;
}



- (void)createView {
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    self.preImageView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 48, AppWidth, AppWidth)];
    [self.preImageView setBackgroundColorRed:0 green:0 blue:0 alpha:1.0];
    [self.view addSubview:self.preImageView];
    
    
    self.recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.recordButton.tag = 13;
    self.recordButton.mj_size = CGSizeMake(87, 87);
    self.recordButton.backgroundColor = [UIColor blackColor];
    self.recordButton.mj_centerX = AppWidth/2.0;
    self.recordButton.mj_y = self.preImageView.max_y+10;
    [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [self.recordButton setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
    [self.recordButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    
    [self.recordButton addTarget:self action:@selector(startRecordVideo) forControlEvents:UIControlEventTouchDown];
    [self.recordButton addTarget:self action:@selector(endRecordVideo) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.view addSubview:self.recordButton];
    
}


// 压缩视频
- (void)compressVideo:(NSString *)videoPath Finish:(void(^)(NSString * targetpath))completion {
    NSURL * originURL = [NSURL fileURLWithPath:videoPath];
    NSLog(@"压缩中");
    //转码配置
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:originURL options:nil];
    NSLog(@"转码前的时长 %.2f", asset.duration.value*1.0/asset.duration.timescale);
    AVAssetExportSession *exportSession= [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.shouldOptimizeForNetworkUse = YES;
    NSString * filename = [NSString stringWithFormat:@"%@.mp4", [[NSDate date] stringWithFormat:@"yyyyMMdd_HH:mm:ss"]];
    NSString * targetPath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    exportSession.outputURL = [NSURL fileURLWithPath:targetPath];
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        int exportStatus = exportSession.status;
        NSLog(@"%d",exportStatus);
        switch (exportStatus) {
            case AVAssetExportSessionStatusFailed: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completion(videoPath);
                });
                NSError *exportError = exportSession.error;
                NSLog (@"压缩失败: %@", exportError);
                break;
            }
            case AVAssetExportSessionStatusCompleted: {
                NSLog(@"视频转码成功");
                dispatch_async(dispatch_get_main_queue(), ^{

                    completion(targetPath);
                });
                break;
            }
            default:{
                NSLog(@"%f", exportSession.progress);
            }
        }
    }];
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for ( AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}



- (GPUImageMovieWriter *)getMovieWriter {
//    GPUImageMovieWriter * movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:self.videoSize fileType:AVFileTypeMPEG4 outputSettings:nil];
    GPUImageMovieWriter * movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:self.videoSize fileType:AVFileTypeQuickTimeMovie outputSettings:nil];
    
    
    movieWriter.delegate = self;
    [movieWriter enableSynchronizationCallbacks];
    movieWriter.hasAudioTrack = YES;
    movieWriter.encodingLiveVideo = YES;
    return movieWriter;
}

#pragma mark - GPUImageMovieWriterDelegate

- (void)movieRecordingCompleted {
    NSLogCMD
}

- (void)movieRecordingFailedWithError:(NSError*)error {
    LogError(@"录制出错");
    LogError(@"%@", error);
}

- (void)deleteFilePath:(NSString *)filePath {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL blHave = [fileManager fileExistsAtPath:filePath];
    if (blHave) {
        NSError * error = nil;
        [fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            NSLog(@"删除失败 %@", error);
        } else {
            NSLog(@"删除成功 %@", [filePath lastPathComponent]);
        }
    } else {
        NSLog(@"文件不存在，无需删除");
    }
}


@end
