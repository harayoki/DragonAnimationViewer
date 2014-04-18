package harayoki.starling
{
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import org.osflash.signals.natives.NativeSignal;
	
	import starling.core.Starling;
	import starling.utils.RectangleUtil;
	import starling.utils.ScaleMode;

	/**
	 * 様々なデバイスの解像度の合わせてコンテンツの内容を伸縮させる
	 * FlashのSpriteとstarlingのViewPortどちらにも対応 どちらかだけを制御させても良い
	 * starlingのViewPort調整は内部でStarlingのRectangleUtilを利用していて、処理はそれに移譲している
	 * @author haruyuki.imai
	 */
	public class ContentCenterizer
	{
		private var _stage:Stage;
		private var _contentsWidth:int;
		private var _contentsHeight:int;
		private var _starling:Starling;
		private var _targetSprites:Vector.<Sprite>;
		private var _resizeSignal:NativeSignal;
		
		public function ContentCenterizer()
		{
		}
		
		/**
		 * 初期化する 
		 * @param stage ステージ参照
		 * @param starling Starling参照
		 * @param targetSprite 伸縮させるスプライト参照(not Starling)
		 * @param contentWidth コンテンツのデフォルトの横幅
		 * @param contentHeight コンテンツのデフォルトの縦幅
		 */
		public function initialize(stage:Stage,starling:Starling=null,targetSprite:Sprite=null,contentWidth:int=0,contentHeight:int=0):void
		{
			_stage = stage;
			_starling = starling;
			_targetSprites = new Vector.<Sprite>();
			if(targetSprite)
			{
				_targetSprites.push(targetSprite);
			}
			_contentsWidth = contentWidth > 0 ? contentWidth : _stage.stageWidth;
			_contentsHeight = contentHeight > 0 ? contentHeight : _stage.stageHeight;
			
			_stage.align = StageAlign.TOP_LEFT;
			_stage.scaleMode = StageScaleMode.NO_SCALE;
			
			_resizeSignal = new NativeSignal(_stage,Event.RESIZE,Event);
			_resizeSignal.add(onFlashStageResize);
			
			onFlashStageResize();

		}
		
		/**
		 * 廃棄処理 
		 */
		public function clean():void
		{
			if(_resizeSignal)
			{
				_resizeSignal.removeAll();
			}
			_resizeSignal = null;
			_stage = null;
			_targetSprites = null;
			_starling = null;
		}
		
		/**
		 * Starling参照 
		 */
		public function get starling():Starling
		{
			return _starling;
		}
		
		public function set starling(value:Starling):void
		{
			_starling = value;
		}
		
		/**
		 * 伸縮対象のスプライトを追加する
		 * @param targetSprite スプライト参照(not Starling)
		 */
		public function addTargetSprite(targetSprite:Sprite):void
		{
			if(targetSprite)
			{
				_targetSprites.push(targetSprite);
				onFlashStageResize();
			}
		}
		
		/**
		 * 伸縮対象のスプライトを削除する
		 * @param targetSprite スプライト参照(not Starling)
		 */
		public function removeTargetSprite(targetSprite:Sprite):void
		{
			var index:int = _targetSprites.indexOf(targetSprite);
			if(index>=0)
			{
				_targetSprites.splice(index,1);
			}
		}
		
		private function onFlashStageResize(ev:Event=null):void
		{
			var w:int = _stage.stageWidth;
			var h:int = _stage.stageHeight
			var scale:Number = Math.min(w/_contentsWidth, h/_contentsHeight);
			
			if(_starling)
			{
				_starling.viewPort = RectangleUtil.fit(
					new Rectangle(0, 0, _contentsWidth, _contentsHeight),
					new Rectangle(0, 0, w,h),
					ScaleMode.SHOW_ALL);
			}
			
			_targetSprites.forEach(function(sp:Sprite,index:int,arr:Vector.<Sprite>):void{
				sp.scaleX = sp.scaleY = scale;
				sp.x = (w - _contentsWidth*scale) >> 1;
				sp.y = (h - _contentsHeight*scale) >> 1;
			});
		}		
	}
}