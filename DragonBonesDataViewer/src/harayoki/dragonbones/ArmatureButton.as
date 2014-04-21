package harayoki.dragonbones
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.animation.WorldClock;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class ArmatureButton
	{
        
        /**
         * ボタン全てのイベントを送信するDispacher
         * 主にSEの再生を行う為に実装
         * 通常はonTriggeredなどハンドラを用いれば良い
         */
        public static const globalEventDispacher:ArmatureButtonEventDispacher = new ArmatureButtonEventDispacher();
		
		private static const HELPER_POINT:Point = new Point();
		private static const HELPER_ARMATURE_VECTOR:Vector.<Armature> = new Vector.<Armature>();
		private static const HIT_AREA_DISPLAYOBJECT_NAME:String = "hitArea";
		private static const REG_ALL:RegExp = /.*/;
        
		private static const STATE_UP:String = "_up";
		private static const STATE_OVER:String = "_over";
		private static const STATE_DOWN:String = "_down";
		private static const STATE_DISABLED:String = "_disabled";
		private static const STATE_TRIGGER:String = "_trigger";
		private static const STATE_LONGPRESS:String = "_longpress";
	
		private static const SELECTED_ANIMATION:String = "select";
		private static const NON_SELECTED_ANIMATION:String = "noselect";
		
		private var _stateNames:Vector.<String> = new <String> [ STATE_UP, STATE_TRIGGER, STATE_DOWN, STATE_OVER, STATE_DISABLED, STATE_LONGPRESS ];		
		private var _armature:Armature;
		private var _animationInfo:Object;
		private var _hitAreaObject:DisplayObject;		
		private var _freeze:Boolean = false;
		private var _disabled:Boolean = false;
		private var _lastAnimationName:String = null;
		private var _triggered:Boolean = false;
		private var _currentState:String = null;
		private var _invalidateId:uint = 0;		
		private var _debugHitArea:Boolean;
		private var _touchPointID:int = -1;
		private var _autoDestruct:Boolean = false;
		private var _isToggleSelected:Boolean = false;		
		private var _isLongPressEnabled:Boolean = false;
		private var _touchBeginTime:int;
		private var _hasLongPressed:Boolean;
		private var _isShow:Boolean = true;
        private var _parentBone:Bone;
        private var _orgScaleX:Number = 1.0;
        
        public var name:String;
        
		/**
		 * ユーザが自由に使えるデータ
		 */
        public var userData:* = null;

        /**
         * ユーザがサウンド用途で自由に使えるデータ
         */
        public var soundData:* = null;
        
		/**
		 * ボタンを押したままロールアウトしたらupStateに戻すか？
		 */
		public var keepDownStateOnRollOut:Boolean = false;
		
        
        public function toString():String
        {
            return "[ArmatureButton:"+name+"]";
        }
        
		/**
		 * 選択状態か
		 */
		public function get isSelected():Boolean
		{
			return _isSelected;
		}

		/**
		 * @private
		 */
		public function set isSelected(value:Boolean):void
		{
			if(value == _isSelected)
			{
				return;
			}
			_updateSelectedAnimation = true;
			_isSelected = value;
			_draw();
		}
        
        /**
         * アーマーチャー名を得る
         */
        public function getArmatureName():String
        {
            return _armature ? _armature.name : null;
        }
        
        /**
         * ボタン操作時にグローバルイベントを投げるか
         */
        public var dispatchGlobalEvent:Boolean = true;

		/**
		 * タッチダウン時のハンドラ
		 */
		public var onTouchDown:Function;
		
		/**
		 * タッチムーブ時のハンドラ
		 */
		public var onTouchMove:Function;
		
		/**
		 * タッチアップ時のハンドラ
		 */
		public var onTouchUp:Function;
		
		/**
		 * クリック時のハンドラ 
		 */
		public var onTriggered:Function;
		
		/**
		 * トグル時のハンドラ 
		 */
		public var onChange:Function;
		
		/**
		 * 長押し時のハンドラ
		 */
		public var onLongPress:Function;
		
		/**
		 * トグルモードで動かすか 
		 */
		public var isToggleMode:Boolean = false;
		
		
		/**
		 * 選択状態か
		 */
		private var _isSelected:Boolean = false;
		
		/**
		 * 選択状態を表現するか 
		 */
		private var _updateSelectedAnimation:Boolean = true;
		
		/**
		 * 長押しと判定される秒数
		 */
		public var longPressDuration:Number = 0.3;
				
		/**
		 * @param armature ボタン化するアーマーチャー
		 * @param autoDestruct armatureのdisplayObjectがStageから離れた際にこのボタンも廃棄するか
		 * @param userData 任意のユーザが自由に使えるデータ
         * @param 親のBone この情報がない場合、hideしていても親のアニメ中に見えている状態に戻ってしまう事がある
		 */
		public function ArmatureButton(armature:Armature=null,autoDestruct:Boolean=false,userData:*=null,parentBone:Bone=null)
		{			
			_animationInfo = {};
			if(armature)
			{
				applyArmature(armature,autoDestruct);
			}
			this.userData = userData;
            _parentBone = parentBone;
            if(_parentBone)
            {
                _orgScaleX = _parentBone.origin.scaleX;
            }
		}
		
		/**
		 * 廃棄処理 
		 * armature
		 */
		public function dispose(disposeArmature:Boolean=false):void
		{
			//trace("ArmatureButton#destruct");
			if(disposeArmature && _armature)
			{
				WorldClock.clock.remove(_armature);
				_armature.dispose();
			}
            
            _cleanArmature();
			_animationInfo = null;
			_armature = null;
			onTriggered = null;
			onChange = null;
			onLongPress = null;
			_hitAreaObject = null;
			_stateNames = null;
			if(_invalidateId!=0)
			{
				flash.utils.clearTimeout(_invalidateId);
				_invalidateId = 0;
			}
			userData = null;
            soundData = null;
            
            if(_parentBone)
            {
                _parentBone.origin.scaleX = _orgScaleX;
            }
            _parentBone = null;
            
		}

        public function isShow():Boolean
        {
            return _isShow;
        }
        
        public function show():void
        {
            _isShow = true;
            if(baseDisplayObject)
            {
                if(_parentBone)
                {
                    _parentBone.origin.scaleX = _orgScaleX;
                    baseDisplayObject.scaleX = _orgScaleX;
                }
                else
                {
                    baseDisplayObject.visible = _isShow;
                }
            }
        }
		
        public function hide():void
        {
            _isShow  = false;
            if(baseDisplayObject)
            {
                if(_parentBone)
                {
                    _parentBone.origin.scaleX = 0.0;
                    baseDisplayObject.scaleX = 0.0;
                }
                else
                {
                    baseDisplayObject.visible = _isShow;
                }
            }
        }
		
		//取りうるボタンState
		private function get stateNames():Vector.<String>
		{
			return this._stateNames;
		}		
		
		/**
		 * 保持している Armatureを返す
		 */		
		public function get armature():Armature{
			return _armature;
		}

		/**
		 * 保持しているArmatureの中のDisplayObjectを返す
		 */		
		public function get baseDisplayObject():DisplayObject{
			return _armature ? _armature.display as DisplayObject : null;
		}
		
        /**
         * 親Boneを得る
         * ※親Boneは現状コンストラクト時のみに設定できます
         * 直接buildArmatureでボタン対象となるarmatureを作った場合は親Boneは存在しません。
         * 動的にBoneを作成して、ArmatureButtonをそこに差し込んだ場合は親Boneが存在する事になりますが
         * コンストラクト時のみの設定であるため、parentBoneは利用できません
         */
        public function get parentBone():Bone
        {
            return _parentBone;
        }
        
		/**
		 * ボタン処理を無効化する
		 * disabledと異なり見た目に変化は無いので、
		 * アニメーション再生の間ボタンを無効化したい時等に使う
		 */
		public function get freeze():Boolean
		{
			return _freeze;
		}
		
		public function set freeze(value:Boolean):void
		{
			if(_freeze == value) return;
			_freeze = value;			
			var sp:DisplayObject = hitAreaObject;
			if(sp)
			{
				_resetTouchable();
			}
		}
		
		/**
		 * ボタン処理を無効化する
		 * ボタンの見た目も変化する
		 */
		public function get disabled():Boolean
		{
			return _disabled;
		}
		
		public function set disabled(value:Boolean):void
		{
			if(_disabled == value)
			{
				return;
			}
			_disabled = value;
			_resetTouchable();
			currentState = _disabled ? STATE_DISABLED : STATE_UP;
			_draw();
		}
		
		/**
		 * デバッグ用にhitAreaを表示するか
		 * (hitAreaが指定されていない場合は何も起こらない)
		 */
		public function get debugHitArea():Boolean
		{
			return _debugHitArea;
		}
		
		public function set debugHitArea(value:Boolean):void
		{
			if(_debugHitArea == value) return;
			_debugHitArea = value;
			_draw();
		}		
		
		/**
		 * 現在トグル状態で選択中か(トグルモードでのみ有効)
		 */
		public function get isToggleSelected():Boolean
		{
			return _isToggleSelected;
		}
		
		public function set isToggleSelected(value:Boolean):void
		{
			if(_isToggleSelected == value) return;
			_isToggleSelected = value;
			onChange && onChange();
            dispatchGlobalEvent && globalEventDispacher.dispatchEventWith(ArmatureButtonEvent.CHANGE,false,this);
		}

		/**
		 * ボタン長押しモードで動作させるか
		 */
		public function get isLongPressEnabled():Boolean
		{
			return _isLongPressEnabled;
		}
		
		/**
		 * @private
		 */
		public function set isLongPressEnabled(value:Boolean):void
		{
			_isLongPressEnabled = value;
			if(!value && hitAreaObject)
			{
				_removeLongPressEnterFrameHandler();
			}
		}		
		
		private function _removeLongPressEnterFrameHandler():void
		{
			if(hitAreaObject)
			{
				hitAreaObject.removeEventListener(Event.ENTER_FRAME, _handleLongPressEnterFrame);
			}
		}
		
		//現在のState
		private function get currentState():String
		{
			return _currentState;
		}
		
		private function set currentState(value:String):void
		{
			if(_currentState == value)
			{
				return;
			}
			if(stateNames.indexOf(value) < 0)
			{
				throw new ArgumentError("Invalid state: " + value + ".");
			}
			if(_currentState == STATE_TRIGGER && value == STATE_OVER)
			{
				//trrigerの演出がありうるのでこの遷移は認めない
				return;
			}
			_currentState = value;
			_draw();
		}
        
		//描画し直す (1フレームに１回だけの処理にまとめられる)
		private function _draw():void
		{
			if(!_armature) return;
			
			if(_invalidateId==0)
			{
				_invalidateId = flash.utils.setTimeout(function():void{
					_invalidateId = 0;
					var animationName:String;
					animationName = _animationInfo[_currentState];
					
					if(isToggleSelected && (animationName == _animationInfo[STATE_TRIGGER] || animationName == _animationInfo[STATE_UP]))
					{
						animationName =  _animationInfo[STATE_DOWN];
					}
					
					DisplayObject(_armature.display).alpha = 1.0;
					if(_currentState == STATE_DISABLED && !animationName)
					{
						//STATE_DISABLEDのアニメが用意されていない場合は半透明にする
						DisplayObject(_armature.display).alpha = 0.5;
						_armature.animation.stop();
						_lastAnimationName = "";//こうしておかないと別のStateに変化した際に止まったままになる
					}
					else if(animationName != _lastAnimationName)
					{
						_lastAnimationName = animationName;
						//trace(_lastAnimationName);
						_armature.animation.gotoAndPlay(_lastAnimationName);
					}
					
					if(_hitAreaObject && _hitAreaObject != _armature.display)
					{
						_hitAreaObject.alpha = _debugHitArea ? 0.5 : 0.0;
					}
					
					//処理が重そうなので毎回行わないようになっている
					if(_updateSelectedAnimation)
					{
						_updateSelectedAnimation = false;
						HELPER_ARMATURE_VECTOR.length = 0;
						DragonBonesUtil.queryDescendantArmaturesByName(_armature,REG_ALL,HELPER_ARMATURE_VECTOR);
						for each(var arm:Armature in HELPER_ARMATURE_VECTOR)
						{
							arm.animation.gotoAndPlay(_isSelected ? SELECTED_ANIMATION : NON_SELECTED_ANIMATION);
						}
					}
					
				},0);
			}
			
		}
		
		/**
		 * アーマーチャーを登録する
		 * @param armature ボタン化するアーマーチャー
		 * @param autoDestruct armatureのdisplayObjectがStageから離れた際にこのボタンも廃棄するか
		 */
		public function applyArmature(armature:Armature,autoDestruct:Boolean):void
		{
			_cleanArmature();
			_armature = armature;
            DisplayObject(_armature.display).touchable = true;
			_autoDestruct = autoDestruct;
			_initArmature();
		}
		
		/**
		 * ボタンの状態をデフォルトに戻す 
		 * 外部で直接アニメーション処理を制御した際等に使う
		 */
		public function resetButton():void
		{
			_touchPointID = -1;
			_isToggleSelected = false;
			currentState = STATE_UP;
           _draw();
		}
		
		private function _resetTouchState():void
		{
			_touchPointID = -1;
			_removeLongPressEnterFrameHandler();
		}
		
		/**
		 * patternにマッチするボタン内部の子孫Armatureをまとめてアニメさせる
		 * @param slotNamePattern 名前パターン String型またはRegExp型
		 * @param animationName 移動するアニメーション名
		 * 主にテキストラベルを切り替えるような用途で使う事を想定
		 * ※子孫のクエリが重いと思われるので、乱用はしない事
		 */
		public function gotoAndPlayBySlotName(slotNamePattern:*,animationName:String):void
		{
			if(!_armature) return;
			HELPER_ARMATURE_VECTOR.length = 0;
			DragonBonesUtil.gotoAndPlayBySlotName(_armature,slotNamePattern,animationName,HELPER_ARMATURE_VECTOR);
		}
        
        /**
         * TODO
         * @param slotName
         * @param disp
         * 
         */
        public function addDisplayObjectAtSlot(slotName:String,disp:DisplayObject,hideSlot:Boolean=false):void
        {
            var targetArmature:Armature = DragonBonesUtil.findArmatureByName(_armature,slotName);
            if(targetArmature && targetArmature.display)
            {
                var o:DisplayObject = targetArmature.display as DisplayObject;
                disp.x = o.x;
                disp.y = o.y;
                o.parent.addChild(disp);
                if(hideSlot)
                {
                    o.visible = false;
                }
            }
        }
		
		//hit判定に使うdisplayObjectを返す
		private function get hitAreaObject():DisplayObject
		{
			//計算済みの物があればそれを使う
			if(_hitAreaObject) return _hitAreaObject;
				
			if(!_armature) return null;
			
			_hitAreaObject = _armature.display as Sprite;			
			
			//特別な名前のdisplayObjectがあれば、それをヒット領域に使う
			var slot:Slot = _armature.getSlot(HIT_AREA_DISPLAYOBJECT_NAME);
			if(!slot)
			{
				return _hitAreaObject;
			}
			var dobj:DisplayObject = slot.display as DisplayObject;
			if(dobj)
			{				
				//hitAreaオブジェクトが見つかったので最前面に持ってくる
				//他の物はタッチに反応させない
				_hitAreaObject = dobj;
				var slots:Vector.<Slot> = _armature.getSlots();
				var len:int = slots.length;
				for(var i:int=0; i<len;i++)
				{
					var theSlot:Slot = slots[i];
					(theSlot.display as DisplayObject).touchable = false;
				}
				
				//デバッグ処理用に最前面に持ってきておく
				slot.zOrder = len -1 ;
				
				(slot.display as DisplayObject).touchable = true;
				_hitAreaObject.alpha = 0.0;//validateに透明度制御を任せるだけだと一瞬見えてしまうので、ここでいったん消す
				if(_hitAreaObject as Image) 
				{
					//デバッグ処理用に赤くしておく
					(_hitAreaObject as Image).color = 0xff00ff;
				}
			}
			return _hitAreaObject;
		}
		
		private function _initArmature():void
		{
			var dobj:DisplayObject = hitAreaObject;//ここでhitAreaObjectが作られる
			if(!dobj) return;
			
			dobj.addEventListener(TouchEvent.TOUCH,_handleTouch);
			_resetTouchable();
			
			if(_autoDestruct)
			{
				dobj.addEventListener(Event.REMOVED_FROM_STAGE,_handleRemoveFromStage);
			}
			
			//アニメーションラベルを解析して、足りない物は良い感じに割り当てる
			var animations:Vector.<String> = _armature.animation.animationList;
			for(var i:int=0;i<animations.length;i++)
			{
				var animation:String = animations[i];
				_animationInfo[animation] = animation;
				//trace("--",animation);
			}
						
			//upが見当たらない場合は最初のラベルを使う
			if(!_animationInfo[STATE_UP])
			{
				_animationInfo[STATE_UP] = animations[0];
			}
			//triggerが見当たらない場合はupを使う
			if(!_animationInfo[STATE_TRIGGER])
			{
				_animationInfo[STATE_TRIGGER] = _animationInfo[STATE_UP]
			}
			//overが見当たらない場合はnormalを使う
			if(!_animationInfo[STATE_OVER])
			{
				_animationInfo[STATE_OVER] = _animationInfo[STATE_UP]
			}
			//downが見当たらない場合はnormalを使う
			if(!_animationInfo[STATE_DOWN])
			{
				_animationInfo[STATE_DOWN] = _animationInfo[STATE_UP]
			}
			//longpressが見当たらない場合はdownを使う
			if(!_animationInfo[STATE_LONGPRESS])
			{
				_animationInfo[STATE_LONGPRESS] = _animationInfo[STATE_DOWN];
			}
			
			resetButton();
			
		}
		
		private function _handleRemoveFromStage(ev:Event):void
		{
			dispose(true);
		}
		
		private function _handleLongPressEnterFrame(ev:Event):void
		{
			var accumulatedTime:Number = (flash.utils.getTimer() - _touchBeginTime) / 1000;
			if(accumulatedTime >= longPressDuration)
			{
				_removeLongPressEnterFrameHandler();
				_hasLongPressed = true;
				currentState = STATE_LONGPRESS;
				onLongPress && onLongPress();
                dispatchGlobalEvent && globalEventDispacher.dispatchEventWith(ArmatureButtonEvent.LONG_PRESS,false,this);
			}
		}
		
		private function _resetTouchable():void
		{
			_touchPointID = -1;
			hitAreaObject.touchable = (!_freeze && !_disabled);
		}
		
		private function _cleanArmature():void
		{
			_animationInfo = {};
			if(_armature)
			{
				if(_autoDestruct) DisplayObject(_armature.display).removeEventListener(Event.REMOVED_FROM_STAGE,_handleRemoveFromStage);				
				hitAreaObject.removeEventListener(TouchEvent.TOUCH,_handleTouch);
				_removeLongPressEnterFrameHandler();
			}			
		}

		private function _handleTouch(ev:TouchEvent):void
		{
			var touch:Touch;
            
            if(_disabled || _freeze)
            {
                //押したボタン自らdisableになるとここに来る事があり得る
                return;
            }
            
			if(_touchPointID<0)
			{
				touch = ev.getTouch(hitAreaObject, TouchPhase.BEGAN);
				if(touch)
				{
					currentState = STATE_DOWN;
					_touchPointID = touch.id;
					if(_isLongPressEnabled)
					{
						_touchBeginTime = flash.utils.getTimer();
						_hasLongPressed = false;
						hitAreaObject.addEventListener(Event.ENTER_FRAME, _handleLongPressEnterFrame);
					}
					onTouchDown && onTouchDown(touch);
                    dispatchGlobalEvent && globalEventDispacher.dispatchEventWith(ArmatureButtonEvent.TOUCH_DOWN,false,this);
					return;
				}
				touch = ev.getTouch(hitAreaObject, TouchPhase.HOVER);
				if(touch)
				{
					currentState = STATE_OVER;
					return;
				}
				
				currentState = STATE_UP;
				
				return;
				
			}
			
			touch = ev.getTouch(hitAreaObject, null, _touchPointID);
			if(!touch)
			{
				//起こりえる
				return;
			}
			//trace(touch.phase);
			const isHit:Boolean = _hitTest(touch);
			if(touch.phase == TouchPhase.MOVED)
			{
				if(_isLongPressEnabled)
				{
					if(!isHit)
					{
						_removeLongPressEnterFrameHandler();
						currentState = keepDownStateOnRollOut ? STATE_DOWN : STATE_UP;
					}
				} else if(isHit || keepDownStateOnRollOut)
				{
					currentState = STATE_DOWN;
				}
				else
				{
					currentState = STATE_UP;
				}
				onTouchMove && onTouchMove(touch);
                dispatchGlobalEvent && globalEventDispacher.dispatchEventWith(ArmatureButtonEvent.TOUCH_MOVE,false,this);
			}
			else if(touch.phase == TouchPhase.ENDED)
			{
				_resetTouchState();
				if(!_hasLongPressed && isHit)
				{
					if(isToggleMode)
					{
						isToggleSelected = !isToggleSelected;
					}
					currentState = isLongPressEnabled || isToggleMode ? STATE_UP : STATE_TRIGGER;
					onTriggered && onTriggered();
                    dispatchGlobalEvent && globalEventDispacher.dispatchEventWith(ArmatureButtonEvent.TRIGGERED,false,this);
				}
				else
				{
					currentState = STATE_UP;
				}
				onTouchUp && onTouchUp(touch);
                dispatchGlobalEvent && globalEventDispacher.dispatchEventWith(ArmatureButtonEvent.TOUCH_UP,false,this);
			}
		}
		
		private function _hitTest(touch:Touch):Boolean
		{
			//stageが実際にクリックされる時まで存在するかわからないのと
			//対象DisplayObjectの大きさがどうもただしくとれないのでここで毎回rectを取得する スピード的には遅いかもしれないが hitAreaObjectの移動にも耐えられる。。
			var rect:Rectangle = hitAreaObject.getBounds(hitAreaObject.stage);
			touch.getLocation(hitAreaObject.stage,HELPER_POINT);
			//trace(rect,HELPER_POINT);
			return rect.containsPoint(HELPER_POINT);
		}

	}
}