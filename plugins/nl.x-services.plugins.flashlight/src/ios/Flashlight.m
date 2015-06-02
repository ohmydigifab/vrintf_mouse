#import "Flashlight.h"
#import <AVFoundation/AVFoundation.h>
#import <Cordova/CDV.h>

#import <mach/mach_time.h>

int is_initialized = 0;
int on_delay_ms = 0;
int off_delay_ms = 0;
int no_toggle_delay_ms = 0;

@implementation Flashlight

- (void)available:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:[self deviceHasFlashlight]];
    NSString *callbackId = command.callbackId;
    [self writeJavascript:[pluginResult toSuccessCallbackString:callbackId]];
}

- (void)switchOn:(CDVInvokedUrlCommand*)command {
    // Check command.arguments here.
    [self.commandDelegate runInBackground:^{
        if ([self deviceHasFlashlight]) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            [device lockForConfiguration:nil];
            [device setTorchMode:AVCaptureTorchModeOn];
            [device setFlashMode:AVCaptureFlashModeOn];
            [device unlockForConfiguration];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Device is not capable of using the flashlight. Please test with flashlight.available()"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void)switchOff:(CDVInvokedUrlCommand*)command {
    // Check command.arguments here.
    [self.commandDelegate runInBackground:^{
        if ([self deviceHasFlashlight]) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            [device lockForConfiguration:nil];
            [device setTorchMode:AVCaptureTorchModeOff];
            [device setFlashMode:AVCaptureFlashModeOff];
            [device unlockForConfiguration];
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Device is not capable of using the flashlight. Please test with flashlight.available()"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

- (void)sendData:(CDVInvokedUrlCommand*)command {
    int c = [[command argumentAtIndex:0] intValue];
    int bits = [[command argumentAtIndex:1] intValue];
    int pulse_width_ms = [[command argumentAtIndex:2] intValue];
    // Check command.arguments here.
    
    [self.commandDelegate runInBackground:^{
        if ([self deviceHasFlashlight]) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            [device lockForConfiguration:nil];
            [device setFlashMode:AVCaptureFlashModeOn];
            if(is_initialized == 0)
            {
                is_initialized = 1;
                int on = 1;
                float on_time_ms = 0;
                float off_time_ms = 0;
                float on_time_ms2 = 0;
                float off_time_ms2 = 0;
                float on_time_ms_min = 999999;
                float off_time_ms_min = 999999;
                float on_time_ms_max = 0;
                float off_time_ms_max = 0;
                [device setTorchMode:AVCaptureTorchModeOn];
                int count = 10;
                for(int i=0;i<count;i++)
                {
                    NSDate *started = [NSDate date];
                    on = on?0:1;
                    if(on)
                    {
                        [device setTorchMode:AVCaptureTorchModeOn];
                        float elapsed = -[started timeIntervalSinceNow]*1000;
                        on_time_ms += elapsed;
                        on_time_ms2 += elapsed*elapsed;
                        on_time_ms_min = MIN(on_time_ms_min, elapsed);
                        on_time_ms_max = MAX(on_time_ms_max, elapsed);
                    }
                    else
                    {
                        [device setTorchMode:AVCaptureTorchModeOff];
                        float elapsed = -[started timeIntervalSinceNow]*1000;
                        off_time_ms += elapsed;
                        off_time_ms2 += elapsed*elapsed;
                        off_time_ms_min = MIN(off_time_ms_min, elapsed);
                        off_time_ms_max = MAX(off_time_ms_max, elapsed);
                    }
                }
                on_time_ms /= count/2;
                off_time_ms /= count/2;
                on_time_ms2 = sqrt(on_time_ms2/(count/2) - on_time_ms*on_time_ms);
                off_time_ms2 = sqrt(off_time_ms2/(count/2) - off_time_ms*off_time_ms);
                no_toggle_delay_ms = (int)MAX(on_time_ms, off_time_ms);
                on_delay_ms = (int)(MAX(on_time_ms, off_time_ms) - on_time_ms);
                off_delay_ms = (int)(MAX(on_time_ms, off_time_ms) - off_time_ms);
                NSLog(@"on_time_ms: %d", on_delay_ms);
                NSLog(@"off_time_ms: %d", off_delay_ms);
                NSLog(@"on_time_ms2: %f", on_time_ms2);
                NSLog(@"off_time_ms2: %f", off_time_ms2);
                NSLog(@"on_time_ms_min: %f", on_time_ms_min);
                NSLog(@"off_time_ms_min: %f", off_time_ms_min);
                NSLog(@"on_time_ms_max: %f", on_time_ms_max);
                NSLog(@"off_time_ms_max: %f", off_time_ms_max);
            }
            NSDate *started = [NSDate date];
            int on = 1;
            for(int i=0;i<c*2;i++)
            {
                if(i%2)
                {
                    usleep(on_delay_ms*1000);
                    [device setTorchMode:AVCaptureTorchModeOn];
                }
                else
                {
                    usleep(off_delay_ms*1000);
                    [device setTorchMode:AVCaptureTorchModeOff];
                }
                
                NSTimeInterval elapsed = -[started timeIntervalSinceNow]*1000;
                NSLog(@"Elapsed: %.2fms", elapsed);
                NSLog(@"wait:%dms", (int)(pulse_width_ms*(i+1) - elapsed));
                NSLog(@"on: %d", on);
                usleep(1000*(int)(pulse_width_ms*(i+1) - elapsed));
            }
            [device unlockForConfiguration];
            usleep(1000*pulse_width_ms*2);
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Device is not capable of using the flashlight. Please test with flashlight.available()"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

-(BOOL)deviceHasFlashlight {
    if (NSClassFromString(@"AVCaptureDevice")) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        return [device hasTorch] && [device hasFlash];
    }
    return false;
}

@end
