/**
 * Copyright (c) 2015-present, Callstack Sp z o.o.
 * All rights reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import UIKit;
#import "RCTOpenTokPublisherView.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import <OpenTok/OpenTok.h>

@interface RCTOpenTokPublisherView () <OTSessionDelegate, OTPublisherDelegate>

@end

@implementation RCTOpenTokPublisherView {
    OTSession *_session;
    OTPublisher *_publisher;
}

/**
 * Mounts component after all props were passed
 */
- (void)didMoveToWindow {
    [super didMoveToSuperview];
    [self mount];
}

/**
 * Creates a new session with a given apiKey, sessionID and token
 *
 * Calls `onStartFailure` in case an error happens during initial creation.
 *
 * Otherwise, `onSessionCreated` callback is called asynchronously
 */
- (void)mount {
    _session = [[OTSession alloc] initWithApiKey:_apiKey sessionId:_sessionId delegate:self];

    OTError *error = nil;
    [_session connectWithToken:_token error:&error];

    if (error) {
        _onPublishError(RCTJSErrorFromNSError(error));
    }
}

/**
 * Creates an instance of `OTPublisher` and publishes stream to the current
 * session
 *
 * Calls `onPublishError` in case of an error, otherwise, a camera preview is inserted
 * inside the mounted view
 */
- (void)startPublishing {
    _publisher = [[OTPublisher alloc] initWithDelegate:self];

    OTError *error = nil;

    [_session publish:_publisher error:&error];

    if (error) {
        _onPublishError(RCTJSErrorFromNSError(error));
        return;
    }

    [self attachPublisherView];
}

/**
 * Attaches publisher preview
 */
- (void)attachPublisherView {
    [_publisher.view setFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    [self addSubview:_publisher.view];
}

/**
 * Cleans up publisher
 */
- (void)cleanupPublisher {
    if (_publisher) {
        id videoView = _publisher.view;
        if ([videoView respondsToSelector:@selector(setDelegate:)]) {
            [videoView setDelegate:nil];
        }
        [videoView removeFromSuperview];
        [_session unsubscribe:_publisher error:nil];
        _publisher.delegate = nil;
        _publisher = nil;
    }
}

- (void) setPublishAudio:(BOOL)publishAudio {
    [_publisher setPublishAudio:publishAudio];
}

- (BOOL) publishAudio {
    return _publisher.publishAudio;
}

- (void)setPublishVideo:(BOOL)publishVideo {
    [_publisher setPublishVideo:publishVideo];
}

- (BOOL) publishVideo {
    return _publisher.publishVideo;
}

- (void) setCameraPosition:(NSString *)cameraPosition {
    if ([cameraPosition containsString:@"front"]) {
        [_publisher setCameraPosition:AVCaptureDevicePositionFront];
        return;
    }
    if ([cameraPosition containsString:@"back"]) {
        [_publisher setCameraPosition:AVCaptureDevicePositionBack];
        return;
    }
    [_publisher setCameraPosition:AVCaptureDevicePositionUnspecified];
}

- (NSString*) cameraPosition {
    if (_publisher.cameraPosition == AVCaptureDevicePositionBack) {
        return @"back";
    }
    if (_publisher.cameraPosition == AVCaptureDevicePositionFront) {
        return @"front";
    }
    return @"unspecified";
}


#pragma mark - OTSession delegate callbacks

/**
 * When session is created, we start publishing straight away
 */
- (void)sessionDidConnect:(OTSession*)session {
    [self startPublishing];
}

- (void)sessionDidDisconnect:(OTSession*)session {}

/**
 * @todo multiple streams in a session are out of scope
 * for our use-cases. To be implemented later.
 */
- (void)session:(OTSession*)session streamCreated:(OTStream *)stream {}
- (void)session:(OTSession*)session streamDestroyed:(OTStream *)stream {}

/**
 * Called when another client connects to the session
 */
- (void)session:(OTSession *)session connectionCreated:(OTConnection *)connection {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZ yyyy"];

  [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
      NSString *creationTimeString = [dateFormatter stringFromDate:connection.creationTime];
    NSMutableDictionary * dic = @{@"connectionId": connection.connectionId,
                                  @"creationTime": creationTimeString}.mutableCopy;
    dic[@"data"] = connection.data ? connection.data : [[NSData alloc] init];
    _onClientConnected(dic);

}

/**
 * Called when client disconnects from the session
 */
- (void)session:(OTSession *)session connectionDestroyed:(OTConnection *)connection {
    _onClientDisconnected(@{
        @"connectionId": connection.connectionId,
    });
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error {
    _onPublishError(RCTJSErrorFromNSError(error));
}

#pragma mark - OTPublisher delegate callbacks

- (void)publisher:(OTPublisherKit*)publisher streamCreated:(OTStream *)stream {
    _onPublishStart(@{});
}

- (void)publisher:(OTPublisherKit*)publisher streamDestroyed:(OTStream *)stream {
    _onPublishStop(@{});
    [self cleanupPublisher];
}

- (void)publisher:(OTPublisherKit*)publisher didFailWithError:(OTError*)error {
    _onPublishError(RCTJSErrorFromNSError(error));
    [self cleanupPublisher];
}

/**
 * Remove session when this component is unmounted
 */
- (void)dealloc {
    [self cleanupPublisher];
    [_session setDelegate:nil];
    [_session disconnect:nil];
}

@end
