import QtQuick 2.4
import Ubuntu.Web 0.2
import Ubuntu.Components 1.3
import com.canonical.Oxide 1.19 as Oxide
import Ubuntu.Content 1.1
import QtMultimedia 5.0
import QtFeedback 5.0
import QtQuick.Window 2.2

import "."
import "../config.js" as Conf

MainView {
    objectName: "mainView"

anchors {
            fill: parent
        }

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
          color: "#000000"
          width: parent.width
          height: units.dp(0)
          z: 1
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

        WebContext {
            id: webcontext
            userAgent: myUA
            userScripts: [
              Oxide.UserScript {
                context: "oxide://"
                url: Qt.resolvedUrl("../userscripts/userscript.js")
                matchAllFrames: true
              }
            ]
        }

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

              if (Conf.hapticLinks) {
                  vibration.start()
              }

              if (Conf.audibleLinks) {
                  clicksound.play()
              }

              if(isValid(url) == false) {
                  console.warn("Opening remote: " + url);
                  Qt.openUrlExternally(url)
                  request.action = Oxide.NavigationRequest.ActionReject
              }
          }

          Component.onCompleted: {
                preferences.localStorageEnabled = true
                if (Qt.application.arguments[2] != undefined ) {
                    console.warn("got argument: " + Qt.application.arguments[1])
                    if(isValid(Qt.application.arguments[1]) == true) {
                        url = Qt.application.arguments[1]
                    }
                }
                console.warn("url is: " + url)
            }
//        onGeolocationPermissionRequested: { request.accept() }

           Loader {
                id: downloadLoader
                source: "Downloader.qml"
                asynchronous: true
            }

            Loader {
                id: filePickerLoader
                source: "ContentPickerDialog.qml"
                asynchronous: true
            }
            function isValid (url){
                var pattern = myPattern.split(',');
                for (var i=0; i<pattern.length; i++) {
                    var tmpsearch = pattern[i].replace(/\*/g,'(.*)')
                    var search = tmpsearch.replace(/^https\?:\/\//g, '(http|https):\/\/');
                    if (url.match(search)) {
                       return true;
                    }
                }
                return false;
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
