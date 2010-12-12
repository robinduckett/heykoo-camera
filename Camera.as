package {
  [SWF(width=320, height=240, backgroundColor='#ffffff', frameRate=30)]
  
  import flash.external.ExternalInterface;

  import flash.display.Sprite;
  import flash.media.Camera;
  import flash.media.Video;
  import flash.media.Microphone;
  import flash.system.SecurityPanel;
  import flash.system.Security;
  import flash.events.StatusEvent;
  import flash.events.NetStatusEvent;
  import flash.events.Event;
  import flash.net.NetStream;
  import flash.net.NetConnection;
  
  import flash.display.BlendMode;
  
  import flash.text.TextField;
  import flash.text.TextFieldAutoSize;
  import flash.text.TextFormat;
  
  import flash.utils.Dictionary;

  public class Camera extends Sprite {
    private var cam:flash.media.Camera;
    private const CirrusAddress:String = "rtmfp://p2p.rtmfp.net";
    private const DeveloperKey:String = "5ff6df986d31e0ca82e07130-7993e76f875c";
  
    private var netConnection:NetConnection;
  
    private var _log:Array;
    private var _logDict:Dictionary;
  
    private var sendNearID:String;
    private var recieveNearID:String;
  
    private var recvStream:NetStream;
    private var sendStream:NetStream;
  
    private var remoteVideo:Video;
    private var localVideo:Video;
  
    private var jsCallbacks:Object;

    public function Camera():void {
      _log = new Array();
      _logDict = new Dictionary();
      
      flash.system.Security.allowDomain('http://localhost');
      
      addEventListener(Event.ADDED_TO_STAGE, function(e:Event):void {
        stage.scaleMode = "noScale";
        stage.align = "TL";
        stage.stageWidth = 320;
        stage.stageHeight = 240;
        
        if (ExternalInterface.available) {
          ExternalInterface.addCallback('startRecieve', startRecieve);
          ExternalInterface.addCallback('startSend', startSend);
          ExternalInterface.addCallback('init', init);
          ExternalInterface.addCallback('log', log);
          
          ExternalInterface.call('event_loaded', 'test');
        } else {
          log('not available');
        }
        
        removeEventListener(Event.ADDED_TO_STAGE, arguments.callee);
      });
    }
    
    private function init(test:Object):void {
      log(typeof test.callback1);
      
      ExternalInterface.call(test.callback1);
      
      jsCallbacks = new Object();
      
      jsCallbacks.gotKey = 'event_gotKey';
      jsCallbacks.startedPublishing = 'event_startedPublishing';
      jsCallbacks.ncClosed = 'event_ncClosed';
      jsCallbacks.nsSuccess = 'event_nsSuccess';
      jsCallbacks.ncFailed = 'event_ncFailed';
      jsCallbacks.nsClosed = 'event_nsClosed';
      
      cam = flash.media.Camera.getCamera();
      cam.setMode(320, 240, 30);
      
      if (cam.muted) {
        Security.showSettings(SecurityPanel.PRIVACY);
        cam.addEventListener(StatusEvent.STATUS, function(e:StatusEvent):void {
          if (e.code == "Camera.Unmuted") {
            startCamera();
            cam.removeEventListener(StatusEvent.STATUS, arguments.callee);
          }
        });
      } else {
        startCamera();
      }
    }

    private function netConnectionHandler(e:NetStatusEvent):void {
      log(e.info.code);
      
      switch (e.info.code) {
        case "NetConnection.Connect.Success":
          sendNearID = netConnection.nearID;
          ExternalInterface.call(jsCallbacks.gotKey, sendNearID);
        break;
        
        case "NetConnection.Connect.Closed":
          ExternalInterface.call(jsCallbacks.ncClosed);
        break;
        
        case "NetStream.Connect.Success":
          ExternalInterface.call(jsCallbacks.nsSuccess);
        break;
        
        case "NetConnection.Connect.Failed":
          ExternalInterface.call(jsCallbacks.ncFailed);
        break;
        
        case "NetStream.Connect.Closed":
          ExternalInterface.call(jsCallbacks.nsClosed);
        break;
        
        case "NetStream.Publish.Start":
          ExternalInterface.call(jsCallbacks.startedPublishing);
        break;
      }
    }
    
    private function startSend():void {
      sendStream = new NetStream(netConnection, NetStream.DIRECT_CONNECTIONS);
      sendStream.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
      sendStream.publish("media");
      sendStream.attachAudio(Microphone.getMicrophone());
      sendStream.attachCamera(cam);
    }
    
    private function startRecieve(id:String):void {
      recvStream = new NetStream(netConnection, id);
      recvStream.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
      recvStream.play("media");
      
      recvStream.receiveVideo(true);
      recvStream.receiveAudio(true);
      
      remoteVideo = new Video(320, 240);
      remoteVideo.attachNetStream(recvStream);
      stage.addChildAt(remoteVideo, 1);
      remoteVideo.x = 0;
      remoteVideo.y = 0;
    }
    
    private function startCamera():void {
      netConnection = new NetConnection();
      netConnection.addEventListener(NetStatusEvent.NET_STATUS, netConnectionHandler);
      netConnection.connect(CirrusAddress + "/" + DeveloperKey);
      
      localVideo = new Video(64, 48);
      localVideo.attachCamera(cam);
      stage.addChildAt(localVideo, 2);
      localVideo.x = 10;
      localVideo.y = 240-74;
    }
    
    private function log(s:String):void {
      _log.push(s);
      
      for (var i:String in _logDict) {
        removeChild(_logDict[i]);
      }
      
      _log.reverse();
      
      for (var o:uint = 0; o < _log.length; o++) {
        var log:String = 'log_' + o;
        _logDict[log] = createText(_log[o]);
        stage.addChildAt(_logDict[log], 3);
        _logDict[log].x = 10;
        _logDict[log].y = 240-((o+1)*24);
      }
      
      _log.reverse();
    }
    
    private function createText(text:String):TextField {
      var res:TextField = new TextField();
      var tf:TextFormat = new TextFormat();
      tf.font = 'Trebuchet MS';
      tf.size = 12;
      //tf.color = 0xFFFFFF;
    
      res.autoSize = TextFieldAutoSize.LEFT;
      res.blendMode = BlendMode.INVERT;
      res.selectable = false;
      res.text = text;
      res.setTextFormat(tf);
      return res;
    }
  }
}