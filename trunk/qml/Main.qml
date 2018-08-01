import QtQuick 2.4
import QtQuick.Window 2.0
import Ubuntu.Web 0.2
import Ubuntu.Components 1.3
import com.canonical.Oxide 1.19 as Oxide
import "UCSComponents"
import Ubuntu.Content 1.1
import "actions" as Actions
import QtMultimedia 5.0
import QtFeedback 5.0
import Ubuntu.Unity.Action 1.1 as UnityActions
import "."
import "../config.js" as Conf

MainView {
    objectName: "mainView"

    applicationName: "outlook-office365.ste-kal"

    anchorToKeyboard: true
    automaticOrientation: true

    property string myUrl: Conf.webappUrl
    property string myPattern: Conf.webappUrlPattern
    property string myUA: setUA();

    function setUA(){
      if(Screen.pixelDensity > 9){
        var tmpUA = "Mozilla/5.0 (Linux; Android 5.0; Nexus 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.102 Mobile Safari/537.36"
      }
      else{
        var tmpUA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/67.0.3396.99 Chrome/67.0.3396.99 Safari/537.36"
      }
      return tmpUA
    }



    Page {
        id: page

        header: Rectangle {
          color: UbuntuColors.orange
          width: parent.width
          height: units.gu(0)
        }

        anchors {
            fill: parent
            bottom: parent.bottom
        }
        width: parent.width
        height: parent.height

        HapticsEffect {
            id: vibration
            attackIntensity: 0.0
            attackTime: 50
            intensity: 1.0
            duration: 10
            fadeTime: 50
            fadeIntensity: 0.0
        }

        SoundEffect {
            id: clicksound
            source: "../sounds/Click.wav"
        }

        WebContext {
            id: webcontext
            userAgent: myUA
        }
        Rectangle{
          id: contentview
          anchors{
            top: parent.top
          }
          width: parent.width
          height: parent.height - units.gu(0)

          WebView {
              id: webview
              anchors {
                  fill: parent
                  bottom: parent.bottom
              }
              width: parent.width
              height: parent.height

              context: webcontext
              url: myUrl
              preferences.localStorageEnabled: true
              preferences.allowFileAccessFromFileUrls: true
              preferences.allowUniversalAccessFromFileUrls: true
              preferences.appCacheEnabled: true
              preferences.javascriptCanAccessClipboard: true
              filePicker: filePickerLoader.item

              function navigationRequestedDelegate(request) {

                  var url = request.url.toString();
                  var pattern = myPattern.split(',');
                  var isvalid = false;

                  if (Conf.hapticLinks) {
                      vibration.start()
                  }

                  if (Conf.audibleLinks) {
                      clicksound.play()
                  }

                  for (var i=0; i<pattern.length; i++) {
                      var tmpsearch = pattern[i].replace(/\*/g,'(.*)')
                      var search = tmpsearch.replace(/^https\?:\/\//g, '(http|https):\/\/');
                      if (url.match(search)) {
                         isvalid = true;
                         break
                      }
                  }
                  if(isvalid == false) {
                      console.warn("Opening remote: " + url);
                      Qt.openUrlExternally(url)
                      request.action = Oxide.NavigationRequest.ActionReject
                  }
              }
              Component.onCompleted: {
                  preferences.localStorageEnabled = true
                  if (Qt.application.arguments[1].toString().indexOf(myUrl) > -1) {
                      console.warn("got argument: " + Qt.application.arguments[1])
                      url = Qt.application.arguments[1]
                  }
                  var x = Screen.width
                  console.log("Screen width:"+x);

                  var x = Screen.devicePixelRatio
                  console.log("Screen PixelRatio:"+x);
                  var x = Screen.name
                  console.log("Screen Name:"+x);
                  var x = Screen.pixelDensity
                  console.log("Screen PixelDensity:"+x);

                  console.log("UA:"+myUA);


                  console.warn("url is: " + url)
              }
              onGeolocationPermissionRequested: { request.accept() }
              Loader {
                  id: filePickerLoader
                  source: "ContentPickerDialog.qml"
                  asynchronous: true
              }
          }
        }
        ThinProgressBar {
            webview: webview
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
        }



    }
    Connections {
        target: Qt.inputMethod
        onVisibleChanged: nav.visible = !nav.visible
    }
    Connections {
        target: webview
        onFullscreenChanged: nav.visible = !webview.fullscreen
    }
    Connections {
        target: UriHandler
        onOpened: {
            if (uris.length === 0 ) {
                return;
            }
            webview.url = uris[0]
            console.warn("uri-handler request")
        }
    }
}
