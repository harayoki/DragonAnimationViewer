package
{
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
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
		
		private var _currentArm:Armature;
		
		private var _ui:uiAll;
		
		private var _state:int = -1;
		private static const STATE_INIT:int = 0;
		private static const STATE_ARMATURE_VIEW:int = 1;
		
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
			_starling.showStatsAt("right","bottom",2);		
			
		}
		
		private function get state():int
		{
			return _state;
		}
		private function set state(value:int):void
		{
			if(_state == value) return;
			_state = value;
			_updateView();
		}
		
		private function _updateView():void
		{
			if(!_ui) return;
			
			_ui.comboArmature.enabled = _state != STATE_INIT;
		}
		
		public function Main()
		{
			_ui = new uiAll();
			Objects.rootSprite.addChild(_ui);
			
			state = STATE_INIT;
			
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
			
			var dfd:DropFileDetector = new DropFileDetector(o);
			//dfd.extensionFilter.push("png");
			dfd.extensionFilter.push("dbswf");
			
			dfd.onDrop.add(function():void{
				_targetFile = dfd.lastDropFiles[0];
				_loadAssets();
			});
			dfd.start();
			
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
			if(!_assetManager)
			{
				_assetManager = new AssetManager();
				_assetManager.verbose = true;
			}
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
			if(_factory)
			{
				_factory.dispose(true);
			}
			_factory = new StarlingFactory();			
			_factory.addEventListener(Event.COMPLETE, handleParseComplete);
			_factory.parseData(_assetManager.getByteArray(_getFileId()));

		}
		
		private function _getFileId():String
		{
			var fileId:String = _targetFile.name.split(".")[0];
			return fileId;
		}
		
		private function _startTest():void
		{
			state = STATE_ARMATURE_VIEW;
			var skeletonData:SkeletonData = _factory.getSkeletonData(_getFileId());
			var armatureNames:Vector.<String> = skeletonData.armatureNames;
			
			
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
		
	}
}