package io.callstack.react.opentok;

import android.util.Log;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.opentok.android.Connection;
import com.opentok.android.OpentokError;
import com.opentok.android.Publisher;
import com.opentok.android.PublisherKit;
import com.opentok.android.Session;
import com.opentok.android.Stream;

/**
 * PublisherView
 *
 * React Component extending SessionView that publishes stream of video and audio to the stream
 */
public class PublisherView extends SessionView implements PublisherKit.PublisherListener, Session.ConnectionListener {

    /** {Publisher} active instance of a publisher **/
    private Publisher mPublisher;


    public void setPublishVideo(Boolean publishVideo ) {
        Log.d("","PublishVideo:" + (publishVideo ? "true": "false"));
        if (mPublisher != null) {
            mPublisher.setPublishVideo(publishVideo);
        }
    }

    public void setPublishAudio(Boolean publishAudio) {
        Log.d("","PublishAudio:" + (publishAudio ? "true": "false"));
        if (mPublisher != null) {
            mPublisher.setPublishAudio(publishAudio);
        }
    }

    public void setCameraPosition(String cameraPosition) {
        Log.d("","CameraPosition: " + cameraPosition);
        if (mPublisher != null) {
            mPublisher.cycleCamera();
        }
    }

//    public Boolean getPublishVideo() {
//        return mPublisher.getPublishVideo();
//    }
//
//    public Boolean getPublishAudio() {
//        return mPublisher.getPublishAudio();
//    }


    public PublisherView(ThemedReactContext reactContext) {
        super(reactContext);
    }

    private void startPublishing() {
        mPublisher = new Publisher(getContext());
        mPublisher.setPublisherListener(this);

        mSession.publish(mPublisher);

        attachPublisherView();
    }

    private void attachPublisherView() {
        addView(mPublisher.getView(), new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
    }

    private void cleanUpPublisher() {
        removeView(mPublisher.getView());
        mPublisher = null;
    }

    @Override
    protected void onSessionCreated(Session session) {
        session.setConnectionListener(this);
    }

    /** Session listener **/

    @Override
    public void onConnected(Session session) {
        startPublishing();
    }

    /** Publisher listener **/

    @Override
    public void onStreamCreated(PublisherKit publisherKit, Stream stream) {
        sendEvent(Events.EVENT_PUBLISH_START, Arguments.createMap());
    }

    @Override
    public void onStreamDestroyed(PublisherKit publisherKit, Stream stream) {
        sendEvent(Events.EVENT_PUBLISH_STOP, Arguments.createMap());
        cleanUpPublisher();
    }

    @Override
    public void onError(PublisherKit publisherKit, OpentokError opentokError) {
        onError(opentokError);
        cleanUpPublisher();
    }

    /** Connection listener **/
    @Override
    public void onConnectionCreated(Session session, Connection connection) {
        WritableMap payload = Arguments.createMap();

        payload.putString("connectionId", connection.getConnectionId());
        payload.putString("creationTime", connection.getCreationTime().toString());
        payload.putString("data", connection.getData());

        sendEvent(Events.EVENT_CLIENT_CONNECTED, payload);
    }

    @Override
    public void onConnectionDestroyed(Session session, Connection connection) {
        WritableMap payload = Arguments.createMap();

        payload.putString("connectionId", connection.getConnectionId());

        sendEvent(Events.EVENT_CLIENT_DISCONNECTED, payload);
    }

}
