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
	import flash.utils.setTimeout;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.animation.AnimationState;
	import dragonBones.animation.WorldClock;
	import dragonBones.factorys.StarlingFactory;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.SkeletonData;
	
	import fl.data.DataProvider;
	import fl.events.ColorPickerEvent;
	import fl.events.SliderEvent;
	
	import harayoki.dragonbones.DragonBonesUtil;
	import harayoki.starling.DropFileDetector;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Quad;
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
		private static const CONTENTS_WIDTH:int = 1280;
		private static const CONTENTS_HEIGHT:int = 960;
		private static const BG_WIDTH:int = 640;
		private static const BG_HEIGHT:int = 960;
		private static var _starling:Starling;
		
		private var _assetManager:AssetManager;
		private var _factory:MyStarlingFactory;		
		
		private var _catCount:int = 0;
		private var _countTf:TextField;
		private var _targetFile:File;
		
		private var _currentArm:Armature;
		
		private var _ui:uiAll;
		private var _bgQuad:Quad;
		private var _borderQuad:Quad;
		private var _centerQuad:Quad;
		private var _armatureHolder:starling.display.Sprite;
		
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
			_starling.showStatsAt("left","bottom",2);		
			
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
		}
		
		public function Main()
		{
			_ui = new uiAll();
			Objects.rootSprite.addChild(_ui);
			_ui.comboArmature.addEventListener(flash.events.Event.CHANGE,_handleArmatureChange);
			_ui.comboAnimation.addEventListener(flash.events.Event.CHANGE,_handleAnimationChange);
			_ui.btnReplay.addEventListener(MouseEvent.CLICK,_handleReplayClick);
			_ui.sliderScale.addEventListener(SliderEvent.CHANGE,_handleScaleChange);
			_handleScaleChange();
			_ui.pickerBgColor.addEventListener(ColorPickerEvent.CHANGE,_handleBgColorChange);
			_ui.cbLowercaseHide.addEventListener(flash.events.Event.CHANGE,_handleLowercaseCheckChange)
			_ui.cbBorderShow.addEventListener(flash.events.Event.CHANGE,_handleBorderVisibleChange);
			_ui.cbCenterShow.addEventListener(flash.events.Event.CHANGE,_handleCenterPointVisibleChange);
			_ui.cbHideSysObj.addEventListener(flash.events.Event.CHANGE,_handleHideSysObjChange);
			_ui.radio1.group.addEventListener(flash.events.Event.CHANGE,_locateCurrentArmature);
			_ui.sliderSpeed.addEventListener(SliderEvent.CHANGE,_handleSpeedChange);
			
			_hideErrorAndCaution();
			
			state = STATE_INIT;
			addEventListener(starling.events.Event.ADDED_TO_STAGE,_handleAddedToStage);
		}
		
		private function _handleAddedToStage():void
		{
			
			stage.color = Objects.stage.color;
			stage.alpha = 0.999999;
			stage.addEventListener(starling.events.Event.RESIZE,_handleStageResize);
			_starling.start();
			
			_bgQuad = new Quad(BG_WIDTH,BG_HEIGHT,0xffffff);
			_bgQuad.x = 640;
			_bgQuad.y = 0;
			addChild(_bgQuad);
			
			_armatureHolder = new starling.display.Sprite();
			_armatureHolder.x = 0;
			_armatureHolder.y = 0;
			_armatureHolder.clipRect = _bgQuad.getBounds(_bgQuad.parent);
			addChild(_armatureHolder);
			
			_centerQuad = new Quad(4,4,0x333399);
			_centerQuad.x = 0;
			_centerQuad.y = 0;
			_centerQuad.pivotX = -_centerQuad.width*0.5;
			_centerQuad.pivotY = -_centerQuad.height*0.5;
			_centerQuad.rotation = Math.PI*0.25;
			_armatureHolder.addChild(_centerQuad);			
			_handleStageResize();
			
			var self:starling.display.Sprite = this;
			var o:InteractiveObject = DropFileDetector.createStageSizeDropTarget(Objects.stage);
			Objects.rootSprite.addChildAt(o,0);
			
			var dfd:DropFileDetector = new DropFileDetector(o);
			dfd.extensionFilter.push("png");
			dfd.extensionFilter.push("dbswf");
			
			_clearInfo();
			
			dfd.onDrop.add(function():void{
				_targetFile = dfd.lastDropFiles[0];
				_clearInfo();
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
			_factory = new MyStarlingFactory();			
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
			
			var skeletonData:SkeletonData;
			var skeletonName:String;
			
			skeletonName = _getFileId();
			skeletonData = _factory.getSkeletonData(skeletonName);
			if(!skeletonData)
			{
				_showCaution("can not find skeleton data id : "+_getFileId());
				skeletonName = _factory.xGetSkeletonDataNames()[0];
				skeletonData = _factory.getSkeletonData(skeletonName);
			}
			
			if(skeletonData)
			{
				var armatureNames:Vector.<String> = skeletonData.armatureNames;
				var arr:Array = [];
				_addInfo("armatures len:"+armatureNames.length);
				for(var i:int=0;i<armatureNames.length;i++)
				{
					var armatureName:String = armatureNames[i];
					var temp:Array = armatureName.split("/");
					var name:String = temp[temp.length-1];//ライブラリパスのディレクトリを除いたもの
					_addInfo(armatureName);
					if(_ui.cbLowercaseHide.selected)
					{
						var lc:Boolean = _hasLowerCase(name);
						if(!lc)
						{
							arr.push(armatureName);
						}
					}
					else
					{
						arr.push(armatureName);
					}
				}
				
				if(arr.length>0)
				{
					_ui.comboArmature.dataProvider = new DataProvider(arr);
					_ui.comboArmature.selectedIndex = 0;
				}
				else
				{
					_ui.comboArmature.dataProvider = new DataProvider([]);
					_ui.comboArmature.selectedIndex = 0;
				}
				
				_handleArmatureChange();			
			}
			else
			{
				_showError("ERROR - can not create armature");
			}
		}
		
		private function _hasLowerCase(str:String):Boolean
		{
			var i:int = str.length;
			while(i--)
			{
				///a ... 97, x ... 120
				if(str.charCodeAt(i)>=97 && str.charCodeAt(i)<=120)
				{
					return true;
				}
			}
			return false;
		}
		
		private function _handleArmatureChange(ev:flash.events.Event=null):void
		{
			//trace(_ui.comboArmature.selectedLabel);
			_removeArmature();
			_createArmature(_ui.comboArmature.selectedLabel);
			var defAnim:String = _updateComboAnimationSelection();
			
			if(defAnim && _currentArm && _currentArm.animation && _currentArm.animation.animationList.length>0)
			{
				_currentArm.animation.gotoAndPlay(defAnim);
			}
			
			//_ui.sliderScale.value = 1.0;
			_handleScaleChange();
			_handleHideSysObjChange();
			
		}
		
		private function _handleAnimationChange(ev:flash.events.Event=null,showLog:Boolean=true):void
		{
			//trace(_ui.comboAnimation.selectedLabel);
			if(_currentArm && _currentArm.animation)
			{
				_currentArm.animation.stop();
				_currentArm.animation.gotoAndPlay(_ui.comboAnimation.selectedLabel)
				var state:AnimationState = _currentArm.animation.getState(_ui.comboAnimation.selectedLabel);
				var duration:Number = state.totalTime * _ui.sliderSpeed.value * 0.01;
				_currentArm.animation.gotoAndPlay(_ui.comboAnimation.selectedLabel,-1,duration);
				
				if(showLog)
				{
					_addInfo("animation totalTime : "+(Math.floor(state.totalTime*1000)/1000)+" sec loop : "+(state.loop==0));
				}
			}
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
				
				_locateCurrentArmature();
				
			}
		}
		
		private function _handleSpeedChange(ev:SliderEvent=null):void
		{
			_ui.txtSpeed.text = _ui.sliderSpeed.value +"";
			_handleAnimationChange(null,false);
		}
		
		private function _handleBgColorChange(ev:ColorPickerEvent):void
		{
			var color:uint = _ui.pickerBgColor.selectedColor;
			_bgQuad.color = color;
		}
		
		private function _handleLowercaseCheckChange(ev:flash.events.Event=null):void
		{
			_startTest();
		}
		
		private function _handleBorderVisibleChange(ev:flash.events.Event=null):void
		{
			_updateBorderQuad();
		}
		
		private function _handleCenterPointVisibleChange(ev:flash.events.Event=null):void
		{
			_centerQuad.visible = _ui.cbCenterShow.selected;
		}
		
		private function _handleHideSysObjChange(ev:flash.events.Event=null):void
		{
			var visibility:Boolean = !_ui.cbHideSysObj.selected;
			if(_currentArm)
			{
				var bones:Vector.<Bone> = DragonBonesUtil.queryDescendantBonesByName(_currentArm,/^_+.+$/);
				var i:int = bones.length;
				//trace("bones",bones);
				while(i--)
				{
					if(!bones[i].userData)
					{
						var trans:DBTransform = new DBTransform();
						trans.copy(bones[i].origin);
						bones[i].userData = trans;
					}
					if(visibility)
					{
						bones[i].origin.scaleX = DBTransform(bones[i].userData).scaleX;
					}
					else
					{
						bones[i].origin.scaleX = 0;
					}
				}
				_handleAnimationChange(null,false);
			}
		}
		
		private function _updateComboAnimationSelection():String
		{
			var defAnim:String = "";
			if(_currentArm)
			{
				var arr:Array = [];
				var maxTime:Number = -1;
				var anims:Vector.<String> = _currentArm.animation.animationList;
				var index:int = 0;
				
				for(var i:int=0;i<anims.length;i++)
				{
					_currentArm.animation.gotoAndPlay(anims[i]);//一度再生しないとstateが取れない
					_currentArm.animation.stop();					
					var state:AnimationState = _currentArm.animation.getState(anims[i]);
					//trace(anims[i],state);
					if(state && maxTime < state.totalTime)
					{
						maxTime = state.totalTime;
						defAnim = anims[i];
						index = i;
					}
					arr.push(anims[i]);
				}
				_ui.comboAnimation.dataProvider = new DataProvider(arr);
				_ui.comboAnimation.selectedIndex = index;
				_ui.comboAnimation.enabled = true;
			}
			else
			{
				_ui.comboAnimation.dataProvider = new DataProvider([]);
				_ui.comboAnimation.enabled = false;
			}
			
			return defAnim;
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
				_armatureHolder.addChild(dobj);
				_locateCurrentArmature();
			}
		}
		
		private function _locateCurrentArmature(ev:flash.events.Event=null):void
		{
			if(_currentArm)
			{
				var dobj:DisplayObject = _currentArm.display as DisplayObject;
				dobj.x = 0;
				dobj.y = 0;
				
				if(_ui.radio1.selected)
				{				
					var rect:Rectangle = dobj.getBounds(dobj.parent);
					dobj.x = _bgQuad.x +  ((BG_WIDTH - dobj.width) >> 1);
					dobj.y = _bgQuad.y + ((BG_HEIGHT - dobj.height) >> 1);
					dobj.x -= rect.x;
					dobj.y -= rect.y;
				}
				else
				{
					dobj.x = _bgQuad.x;
					dobj.y = _bgQuad.y;
				}
				
				_updateBorderQuad();
				
				_centerQuad.x = dobj.x;
				_centerQuad.y = dobj.y;
				
				_handleCenterPointVisibleChange();
				_armatureHolder.addChild(_centerQuad);
			}
		}
		
		private function _updateBorderQuad():void
		{
			
			if(_borderQuad)
			{
				_borderQuad.removeFromParent(true);
			}
			
			var dobj:DisplayObject = _currentArm.display as DisplayObject;
			
			if(!dobj) return;
			if(!_ui.cbBorderShow.selected) return;
			
			var rect:Rectangle = dobj.getBounds(dobj.parent);
			
			_borderQuad = new Quad(rect.width,rect.height,0xff0000);
			_borderQuad.alpha = 0.1;
			
			_armatureHolder.addChildAt(_borderQuad,_armatureHolder.getChildIndex(dobj));
			
			_borderQuad.x = rect.x;
			_borderQuad.y = rect.y;
			
		}
		
		private function _clearInfo():void
		{
			_ui.tfInfo.text = "";
		}
		
		private function _addInfo(str:String):void
		{
			_ui.tfInfo.appendText(str+"\n");
			_ui.tfInfo.scrollV = _ui.tfInfo.maxScrollV;
		}
		
		private function _hideErrorAndCaution():void
		{
			_ui.cautionView.visible = false;
			_ui.errorView.visible = false;
		}
		
		private function _showCaution(txt:String):void
		{
			_ui.cautionView.txt.text = txt;
			_ui.cautionView.visible = true;
			setTimeout(function():void{
				_ui.cautionView.visible = false;
			},5000);
		}
		private function _showError(txt:String):void
		{
			_ui.errorView.txt.text = txt;
			_ui.errorView.visible = true;
			setTimeout(function():void{
				_ui.errorView.visible = false;
			},5000);
		}
		
	}
}
import dragonBones.factorys.StarlingFactory;

internal class MyStarlingFactory extends StarlingFactory
{
	public function MyStarlingFactory()
	{
		super();
	}
	
	public function xGetSkeletonDataNames():Vector.<String>
	{
		var v:Vector.<String> = new Vector.<String>();
		for(var name:String in _dataDic)
		{
			v.push(name);
		}
		return v;
	}
}

