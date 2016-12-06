package io.callstack.react.opentok;

import android.util.Log;

import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.io.Console;


public class PublisherViewManager extends SessionViewManager<PublisherView> {
    @Override
    public String getName() {
        return "RCTOpenTokPublisherView";
    }

    @ReactProp(name = "publishVideo", defaultBoolean = true)
    public void setPublishVideo(PublisherView view, Boolean publishVideo) {
        view.setPublishVideo(publishVideo);
    }

    @ReactProp(name = "publishAudio", defaultBoolean = true)
    public void setPublishAudio(PublisherView view, Boolean publishAudio) {
        view.setPublishAudio(publishAudio);
    }

    @ReactProp(name = "cameraPosition")
    public void setCameraPosition(PublisherView view, String cameraPosition) {
        view.setCameraPosition(cameraPosition);
    }
    
    @Override
    protected PublisherView createViewInstance(ThemedReactContext reactContext) {
        return new PublisherView(reactContext);
    }
}
