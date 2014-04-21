package
{
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	
	import dragonBones.Armature;
	import dragonBones.animation.WorldClock;
	import dragonBones.factorys.StarlingFactory;
	import dragonBones.objects.SkeletonData;
	
	import fl.data.DataProvider;
	import fl.events.SliderEvent;
	
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
			_ui.comboAnimation.enabled = _state != STATE_INIT;
			_ui.radio1.enabled = 
				_ui.radio2.enabled = 
				_ui.radio3.enabled =  _state != STATE_INIT;
		}
		
		public function Main()
		{
			_ui = new uiAll();
			Objects.rootSprite.addChild(_ui);
			_ui.comboArmature.addEventListener(flash.events.Event.CHANGE,_handleArmatureChange);
			_ui.comboAnimation.addEventListener(flash.events.Event.CHANGE,_handleAnimationChange);
			_ui.radio1.group.addEventListener(flash.events.Event.CHANGE,_handleBaePositionChange);
			_ui.btnReplay.addEventListener(MouseEvent.CLICK,_handleReplayClick);
			_ui.sliderScale.addEventListener(SliderEvent.CHANGE,_handleScaleChange);
			_handleScaleChange();
			
			state = STATE_INIT;
			addEventListener(starling.events.Event.ADDED_TO_STAGE,_handleAddedToStage);
		}
		
		private function _handleAddedToStage():void
		{
			
			stage.color = Objects.stage.color;
			stage.alpha = 0.999999;
			stage.addEventListener(starling.events.Event.RESIZE,_handleStageResize);
			_starling.start();		
			
			_handleStageResize();
			
			var self:starling.display.Sprite = this;
			var o:InteractiveObject = DropFileDetector.createStageSizeDropTarget(Objects.stage);
			Objects.rootSprite.addChildAt(o,0);
			
			var dfd:DropFileDetector = new DropFileDetector(o);
			//dfd.extensionFilter.push("png");
			dfd.extensionFilter.push("dbswf");
			
			dfd.onDrop.add(function():void{
				_targetFile = dfd.lastDropFiles[0];
				_loadAssets();
			});
			dfd.start();
			
			function handleEnterFrame(ev:starling.events.Event):void
			{
				WorldClock.clock.advanceTime(-1);
			}
			stage.addEventListener(starling.events.Event.ENTER_FRAME,handleEnterFrame);
			
		}
		
		private function _handleStageResize(ev:starling.events.Event=null):void
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
			_removeArmature();
			
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
			_factory.addEventListener(flash.events.Event.COMPLETE, handleParseComplete);
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
			var arr:Array = [];
			for(var i:int=0;i<armatureNames.length;i++)
			{
				arr.push(armatureNames[i]);
			}
			_ui.comboArmature.dataProvider = new DataProvider(arr);
			_ui.comboArmature.selectedIndex = 0;
			
			_handleArmatureChange();			
		}
		
		private function _handleArmatureChange(ev:flash.events.Event=null):void
		{
			//trace(_ui.comboArmature.selectedLabel);
			_removeArmature();
			_createArmature(_ui.comboArmature.selectedLabel);
			_updateComboAnimationSelection();
			
			if(_currentArm && _currentArm.animation && _currentArm.animation.animationList.length>0)
			{
				_currentArm.animation.gotoAndPlay(_currentArm.animation.animationList[0]);
			}
			
			//_ui.sliderScale.value = 1.0;
			_handleScaleChange();
			
		}
		
		private function _handleAnimationChange(ev:flash.events.Event=null):void
		{
			trace(_ui.comboAnimation.selectedLabel);
			if(_currentArm && _currentArm.animation)
			{
				_currentArm.animation.stop();
				_currentArm.animation.gotoAndPlay(_ui.comboAnimation.selectedLabel);
			}
		}
		
		private function _handleBaePositionChange(ev:flash.events.Event):void
		{
			trace(_ui.radio1.group.selection.label);
			_locateCurrentArmature();
		}
		
		private function _handleReplayClick(ev:flash.events.Event):void
		{
			_handleAnimationChange();
		}
		
		private function _handleScaleChange(ev:SliderEvent=null):void
		{
			if(_ui.txtScale && _ui.sliderScale)
			{
				_ui.txtScale.text = _ui.sliderScale.value+"";
			}
			if(_currentArm && _currentArm.display is DisplayObject)
			{
				(_currentArm.display as DisplayObject).scaleX = _ui.sliderScale.value;
				(_currentArm.display as DisplayObject).scaleY = _ui.sliderScale.value;
			}
		}
		
		private function _updateComboAnimationSelection():void
		{
			if(_currentArm)
			{
				var arr:Array = [];
				var anims:Vector.<String> = _currentArm.animation.animationList;
				for(var i:int=0;i<anims.length;i++)
				{
					arr.push(anims[i]);
				}
				_ui.comboAnimation.dataProvider = new DataProvider(arr);
				_ui.comboAnimation.selectedIndex = 0;
				_ui.comboAnimation.enabled = true;
			}
			else
			{
				_ui.comboAnimation.dataProvider = new DataProvider([]);
				_ui.comboAnimation.enabled = false;
			}
			
		}
		
		private function _removeArmature():void
		{
			if(_currentArm)
			{
				WorldClock.clock.remove(_currentArm);				
			}
			
			if(_currentArm)
			{
				(_currentArm.display as DisplayObject).removeFromParent(true);
				_currentArm = null;
			}
			
		}
		
		private function _createArmature(name:String):void
		{
			
			x = 0;
			y = 0;
			var arm:Armature = _factory.buildArmature(name);
			if(!arm)
			{
				arm = _factory.buildArmature("_"+_getFileId()+"/"+name);
			}
			
			if(arm)
			{
				_currentArm = arm;
				WorldClock.clock.add(arm);
				var dobj:DisplayObject = _currentArm.display as DisplayObject;
				addChild(dobj);
				_locateCurrentArmature();
			}
		}
		
		private function _locateCurrentArmature():void
		{
			if(_currentArm)
			{
				var dobj:DisplayObject = _currentArm.display as DisplayObject;
				
				dobj.x = CONTENTS_WIDTH >> 1;
				dobj.y = CONTENTS_HEIGHT *0.65;
				
				switch(true)
				{
					case _ui.radio1.selected:
					{
						break;
					}
					case _ui.radio2.selected:
					{
						dobj.x -= (dobj.width >> 1);
						dobj.y -= (dobj.height >> 1);
						break;
					}
					case _ui.radio3.selected:
					{
						dobj.y -= dobj.height;
						break;
					}
				}
			}
		}
		
	}
}