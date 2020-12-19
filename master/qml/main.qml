import QtQuick 2.9
import QtQuick.Window 2.2
import Morph.Web 0.1
import QtWebEngine 1.7
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3
import Ubuntu.Content 1.1
import QtMultimedia 5.8
import QtSystemInfo 5.0
import Qt.labs.settings 1.0
import "components"
import "actions" as Actions
import "."

MainView {
  id: root
  objectName: "mainView"
  theme.name: "Ubuntu.Components.Themes.Ambiance"

  focus: true

  anchors {
    fill: parent
  }

  applicationName: "outlook-office365.ste-kal"
  anchorToKeyboard: false
  automaticOrientation: true
  property bool blockOpenExternalUrls: false
  property bool runningLocalApplication: false
  property bool openExternalUrlInOverlay: false
  property bool popupBlockerEnabled: true
  property bool fullscreen: false

  property var myScreenPixelDensity: Screen.pixelDensity

  Page {
    id: page

  
    header: Rectangle {
      color: "#0078D7"
      width: parent.width
      height: units.dp(.5)
      z: 1
    }

    anchors {
      fill: parent
      bottom: parent.bottom
    }

    WebEngineView {
      id: webview

      property var currentWebview: webview

      settings.fullScreenSupportEnabled: false
      settings.pluginsEnabled: true
      property string myUrl: "https://outlook.office365.com/owa"

      property string test: writeToLog("DEBUG","my URL:", myUrl);
      property string test2: writeToLog("DEBUG","DevicePixelRatio:", Screen.devicePixelRatio);
      property string test3: writeToLog("DEBUG","PixelDensity:", Screen.pixelDensity);
      property string test4: writeToLog("DEBUG","Screen model:", Screen.model);
      property string test5: writeToLog("DEBUG","Screen manufacturer:", Screen.manufacturer);

      function writeToLog(mylevel,mytext, mymessage){
        console.log("["+mylevel+"]  "+mytext+" "+mymessage)
        return(true);
      }

      profile: WebEngineProfile {
        id: webContext
        persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        property alias userAgent: webContext.httpUserAgent
        property alias dataPath: webContext.persistentStoragePath
        property string myTabletUA: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36"
        property string myMobileUA: "Mozilla/5.0 (Windows Phone 10.0; Android 6.0.1; Microsoft; RM-1152) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/52.0.2743.116 Mobile Safari/537.36 Edge/15.15254"
        property string myUA: (Screen.devicePixelRatio == 1.625 && Screen.pixelDensity == 5.469444444444444) ? myTabletUA : myMobileUA
        property string test: console.log("[DEBUG] myUA "+myUA)

        dataPath: dataLocation

        httpUserAgent: myUA

      }

      anchors {
        fill: parent
        right: parent.right
        bottom: parent.bottom
        margins: units.gu(0)
        bottomMargin: units.gu(4)
      }

      property var myFriezaZOOM: 1.5
      property var myMobileZOOM: .95
      property var myZOOM: (Screen.devicePixelRatio == 1.625 && Screen.pixelDensity == 5.469444444444444) ? myFriezaZOOM : myMobileZOOM
      property string test6: writeToLog("DEBUG","my Zoom:", myZOOM);
      zoomFactor: myZOOM
      url: myUrl

      onJavaScriptDialogRequested: function(request) {

        switch (request.type){
          case JavaScriptDialogRequest.DialogTypeAlert:
            request.accepted = true;
            var alertDialog = PopupUtils.open(Qt.resolvedUrl("AlertDialog.qml"));
            alertDialog.message = request.message;
            alertDialog.accept.connect(request.dialogAccept);
            break;

          case JavaScriptDialogRequest.DialogTypeConfirm:
            request.accepted = true;
            var confirmDialog = PopupUtils.open(Qt.resolvedUrl("ConfirmDialog.qml"));
            confirmDialog.message = request.message;
            confirmDialog.accept.connect(request.dialogAccept);
            confirmDialog.reject.connect(request.dialogReject);
            break;

          case JavaScriptDialogRequest.DialogTypePrompt:
            request.accepted = true;
            var promptDialog = PopupUtils.open(Qt.resolvedUrl("PromptDialog.qml"));
            promptDialog.message = request.message;
            promptDialog.defaultValue = request.defaultText;
            promptDialog.accept.connect(request.dialogAccept);
            promptDialog.reject.connect(request.dialogReject);
            break;

          case 3:
            request.accepted = true;
            var beforeUnloadDialog = PopupUtils.open(Qt.resolvedUrl("BeforeUnloadDialog.qml"));
            beforeUnloadDialog.message = request.message;
            beforeUnloadDialog.accept.connect(request.dialogAccept);
            beforeUnloadDialog.reject.connect(request.dialogReject);
            break;
        }

      }

      onFileDialogRequested: function(request) {
        switch (request.mode) {
          case FileDialogRequest.FileModeOpen:
            request.accepted = true;
            var fileDialogSingle = PopupUtils.open(Qt.resolvedUrl("ContentPickerDialog.qml"));
            fileDialogSingle.allowMultipleFiles = false;
            fileDialogSingle.accept.connect(request.dialogAccept);
            fileDialogSingle.reject.connect(request.dialogReject);
            break;

          case FileDialogRequest.FileModeOpenMultiple:
            request.accepted = true;
            var fileDialogMultiple = PopupUtils.open(Qt.resolvedUrl("ContentPickerDialog.qml"));
            fileDialogMultiple.allowMultipleFiles = true;
            fileDialogMultiple.accept.connect(request.dialogAccept);
            fileDialogMultiple.reject.connect(request.dialogReject);
            break;

          case FilealogRequest.FileModeUploadFolder:
          case FileDialogRequest.FileModeSave:
            request.accepted = false;
            break;
        }
      }

      onAuthenticationDialogRequested: function(request) {
        switch (request.type)
        {
        //case WebEngineAuthenticationDialogRequest.AuthenticationTypeHTTP:
        case 0:
          request.accepted = true;
          var authDialog = PopupUtils.open(Qt.resolvedUrl("HttpAuthenticationDialog.qml"), webview.currentWebview);
          authDialog.host = UrlUtils.extractHost(request.url);
          authDialog.realm = request.realm;
          authDialog.accept.connect(request.dialogAccept);
          authDialog.reject.connect(request.dialogReject);
          break;

        //case WebEngineAuthenticationDialogRequest.AuthenticationTypeProxy:
        case 1:
          request.accepted = false;
          break;
        }
      }

      onNewViewRequested: function(request) {
        Qt.openUrlExternally(request.requestedUrl);
      }

      Loader {
        anchors {
          fill: popupWebview
        }
        active: webProcessMonitor.crashed || (webProcessMonitor.killed && !popupWebview.currentWebview.loading)
        sourceComponent: SadPage {
          webview: popupWebview
          objectName: "overlaySadPage"
        }
        WebProcessMonitor {
          id: webProcessMonitor
          webview: popupWebview
        }
        asynchronous: true
      }
    }

    Loader {
      id: contentHandlerLoader
      source: "ContentHandler.qml"
      asynchronous: true
    }

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

    Loader {
      id: downloadDialogLoader
      source: "ContentDownloadDialog.qml"
      asynchronous: true
    }

    BottomMenu {
      id: bottomMenu
      width: parent.width
    }
  }
}
