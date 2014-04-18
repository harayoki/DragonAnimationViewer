package
{
	import flash.display.InteractiveObject;
	import flash.display.SimpleButton;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	import dragonBones.Armature;
	import dragonBones.animation.WorldClock;
	import dragonBones.factorys.StarlingFactory;
	import dragonBones.objects.SkeletonData;
	
	import harayoki.starling.DropFileDetector;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.utils.AssetManager;
	import starling.utils.RectangleUtil;
	import starling.utils.ScaleMode;
	
	/**
	 * リスト動作サンプル メイン
	 * _startメソッド内がサンプルとして主となる箇所
	 * @author haruyuki.imai
	 */
	public class Main extends starling.display.Sprite
	{
		private static const CONTENTS_WIDTH:int = 640;
		private static const CONTENTS_HEIGHT:int = 960;
		private static var _starling:Starling;
		
		private var _assetManager:AssetManager;
		private var _factory:StarlingFactory;		
		
		private var _catCount:int = 0;
		private var _countTf:TextField;
		private var _targetFile:File;
		private var _inputTf:TextField;
		
		private var _btnCnt:int = 0;
		private var _currentArm:Armature;
		
		/**
		 * ここから動作スタート
		 */
		public static function main(rootSprite:flash.display.Sprite):void
		{
			Objects.rootSprite = rootSprite;;
			Objects.stage = rootSprite.stage;
			
			Objects.stage.align = StageAlign.TOP_LEFT;
			Objects.stage.scaleMode = StageScaleMode.NO_SCALE;
			Starling.handleLostContext = true;
			
			_starling = new Starling(Main,Objects.stage,new Rectangle(0,0,CONTENTS_WIDTH,CONTENTS_HEIGHT));
			_starling.showStats = true;
			_starling.showStatsAt("right","top",2);		
			
		}
		
		public function Main()
		{
			
			_factory = new StarlingFactory();			
			addEventListener(Event.ADDED_TO_STAGE,_handleAddedToStage);
		}
		
		private function _handleAddedToStage():void
		{
			stage.color = Objects.stage.color;
			stage.alpha = 0.999999;
			stage.addEventListener(Event.RESIZE,_handleStageResize);
			_starling.start();		
			
			_handleStageResize();
			
			var self:starling.display.Sprite = this;
			var o:InteractiveObject = DropFileDetector.createStageSizeDropTarget(Objects.stage);
			Objects.rootSprite.addChild(o);
			o.addEventListener(MouseEvent.MOUSE_DOWN,function(ev:MouseEvent):void
			{
				if(!ev.shiftKey) return;
				var xx:Number = ev.stageX;
				var yy:Number = ev.stageY;
				var f1:Function = function(ev:MouseEvent):void{
					self.x += (ev.stageX - xx);
					self.y += (ev.stageY - yy);
					xx = ev.stageX;
					yy = ev.stageY;
				};
				var f2:Function = function(ev:MouseEvent):void{
					Objects.stage.removeEventListener(MouseEvent.MOUSE_MOVE,f1);
					o.removeEventListener(MouseEvent.MOUSE_UP,f2);
				};
				Objects.stage.addEventListener(MouseEvent.MOUSE_MOVE,f1);
				o.addEventListener(MouseEvent.MOUSE_UP,f2);
			});
			var dfd:DropFileDetector = new DropFileDetector(o);
			//dfd.extensionFilter.push("png");
			dfd.extensionFilter.push("dbswf");
			dfd.onDrop.add(function():void{
				_targetFile = dfd.lastDropFiles[0];
				_loadAssets();
			});
			dfd.start();
			
			_inputTf = _createTf("drag & drop png file",24,0xcccccc);
			_inputTf.width = 500;
			_inputTf.type = TextFieldType.DYNAMIC;
			_inputTf.autoSize = TextFieldAutoSize.NONE;
			_inputTf.x = _inputTf.y = 10;			
			Objects.rootSprite.addChild(_inputTf);
			
			var handleFocus:Function = function(ev:FocusEvent):void
			{
				_inputTf.removeEventListener(FocusEvent.FOCUS_IN,handleFocus);
				var tft:TextFormat = _inputTf.defaultTextFormat;
				tft.color = 0x111111;
				_inputTf.defaultTextFormat = tft;
				_inputTf.text = "";
			}
			_inputTf.addEventListener(FocusEvent.FOCUS_IN,handleFocus);
			
			_inputTf.addEventListener(KeyboardEvent.KEY_UP,function(ev:KeyboardEvent):void{
				if(ev.keyCode == Keyboard.ENTER)
				{
					_createArmature(_inputTf.text);
					_inputTf.text = "";
				}
			});
			
			_inputTf.visible = true;
			_inputTf.border = false;
			_inputTf.selectable = false;
			_inputTf.mouseEnabled = false;
			
			var tf:TextField = _createTf("# shift & drag to move stage\n# press up or down to select armature automatically.",24,0xcccccc);
			tf.x = 10;
			tf.y = CONTENTS_HEIGHT - 80;
			tf.mouseEnabled = tf.selectable = false;
			Objects.rootSprite.addChild(tf);
			
			
			function handleEnterFrame(ev:Event):void
			{
				WorldClock.clock.advanceTime(-1);
			}
			stage.addEventListener(Event.ENTER_FRAME,handleEnterFrame);
			
			
		}
		
		private function _handleStageResize(ev:Event=null):void
		{
			var w:int = Objects.stage.stageWidth;
			var h:int = Objects.stage.stageHeight
			_starling.viewPort = RectangleUtil.fit(
				new Rectangle(0, 0, CONTENTS_WIDTH, CONTENTS_HEIGHT),
				new Rectangle(0, 0, w,h),
				ScaleMode.SHOW_ALL);			
			Objects.rootSprite.scaleX = Objects.rootSprite.scaleY = Starling.contentScaleFactor;
		}
		
		private function _loadAssets():void
		{
			_inputTf.visible = false;
			
			_assetManager = new AssetManager();
			_assetManager.verbose = true;
			_assetManager.enqueue(_targetFile);
			_assetManager.loadQueue(function(num:Number):void{
				if(num==1.0)
				{
					_initTest();
				}
			});
			
		}
		
		private function _initTest():void
		{
			
			function handleParseComplete():void
			{
				_startTest();
			}
			
			_factory.addEventListener(Event.COMPLETE, handleParseComplete);
			var skeletonData:SkeletonData = _factory.parseData(_assetManager.getByteArray(_getFileId()));

		}
		
		private function _getFileId():String
		{
			var fileId:String = _targetFile.name.split(".")[0];
			return fileId;
		}
		
		private function _startTest():void
		{
			_btnCnt = -1;
			_inputTf.visible = true;
			_inputTf.text = "Enter armature name here, then press enter.";
			_inputTf.type = TextFieldType.INPUT;
			_inputTf.border = true;
			_inputTf.selectable = true;
			_inputTf.mouseEnabled = true;
		}
		
		private function _createArmature(name:String):void
		{
			
			x = 0;
			y = 0;
			if(_currentArm)
			{
				WorldClock.clock.remove(_currentArm);				
			}
			
			if(_currentArm)
			{
				(_currentArm.display as DisplayObject).removeFromParent(true);
				_currentArm = null;
			}
			
			var arm:Armature = _factory.buildArmature(name);
			if(!arm)
			{
				arm = _factory.buildArmature("_"+_getFileId()+"/"+name);
			}
			
			if(arm)
			{
				_currentArm = arm;
				WorldClock.clock.add(arm);
				var dobj:DisplayObject = arm.display as DisplayObject;
				dobj.x = CONTENTS_WIDTH>>1;
				dobj.y = CONTENTS_HEIGHT>>1;
				addChild(dobj);
				
			}
		}
		
		private function _createTextButton(text:String,handler:Function,xx:int,yy:int):SimpleButton
		{			
			var tf:TextField = _createTf(text);
			tf.border = true;
			tf.background = true;
			tf.backgroundColor = 0xdddddd;
			var btn:SimpleButton = new SimpleButton(tf,tf,tf,tf);
			btn.x = xx - (btn.width>>1);
			btn.y = yy;
			btn.useHandCursor = true;
			btn.addEventListener(MouseEvent.CLICK,handler);
			return btn;
		}
		
		private function _createTf(text:String="",size:int=24,color:uint=0x222222):TextField
		{
			var tf:TextField = new TextField();
			tf.defaultTextFormat = new TextFormat("_sans",size,color);
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.text = text;
			return tf;
		}
		
	}
}