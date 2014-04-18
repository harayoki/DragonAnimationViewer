package harayoki.starling
{
	import flash.geom.Matrix;
	
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.textures.RenderTexture;
	import starling.textures.Texture;
	
	/**
	 * Starlingにてピクセル単位でのマスクを実現する
	 * アニメ処理も可能(アニメーションのアップデートは外部でmaskTargetやmaskObjectを直接制御する事で行います)	
	 * @author haruyuki.imai
	 */
	public class DynamicMaskedImage
	{
		
		/* samplecode
		
		var background:Image = new Image(HogeTexture);//背景画像(MovieClip等でもよい)
		var maskObject:Image = new Image(MogeTexture);//マスク形状画像(MovieClip等でもよい)
		var maskedImage:DynamicMaskedImage = new DynamicMaskedImage(256,256);	
		maskedImage.maskTarget = background;
		maskedImage.maskObject = maskObject;
		
		Starling.current.stage.addEventListener(starling.events.EnterFrameEvent.ENTER_FRAME, function(ev:starling.events.EnterFrameEvent):void{
		maskObject.rotarion += 0.1;//毎フレーム回転させてみる
		maskedImage.update();
		});
		
		Starling.current.stage.addChild(maskedImage.resutImage);
		
		*/
		
		//作業用Texture drawCallの回数には影響しない
		private static var _workTexture:Texture;
		
		//作業用ImageとRenderTexture
		private var _renderImage1:Image;
		private var _renderImage2:Image;
		private var _renderTexture1:RenderTexture;
		private var _renderTexture2:RenderTexture;
		
		private var _maskObject:DisplayObject;
		private var _maskTarget:DisplayObject;
		
		//作業用Image
		private var _defaultWorkBg:Image;
		
		//ユーザによる作業用Imageの設定 マスクの縁取りがぼける場合等におおきな物を与えて使う事を想定 未検証
		public var userWorkBg:DisplayObject;		
		
		/**
		 * 自由に使えるユーザデータ 
		 */
		public var userData:*;
		
		private var _drawMatrix:Matrix;
		
		private static function _changeChildrenBlendModeAsAuto(dobj:DisplayObject,recursive:Boolean=true):void
		{
			var container:DisplayObjectContainer = dobj as DisplayObjectContainer;
			if(container)
			{
				var i:int = container.numChildren;
				var child:DisplayObject;
				while(i--)
				{
					child = container.getChildAt(i);
					child.blendMode = BlendMode.AUTO;
					if(recursive) _changeChildrenBlendModeAsAuto(child);
				}
			}
		}
		
		/**
		 * @param width 最終イメージの横幅
		 * @param height 最終イメージの縦幅
		 * @param maskTarget マスクされるDisplayObject
		 * @param maskObject マスクするDisplayObject
		 * 
		 */
		public function DynamicMaskedImage(width:int,height:int,maskTarget:DisplayObject=null,maskObject:DisplayObject=null)
		{
			
			if(!_workTexture)
			{
				_workTexture = Texture.fromColor(256,256,0xffff0000);
			}
			
			_renderTexture1 = new RenderTexture(width,height,false);
			_renderTexture2 = new RenderTexture(width,height,false);
			
			_renderImage1 = new Image(_renderTexture1);
			_renderImage1.blendMode = BlendMode.ERASE;
			
			_renderTexture2 = new RenderTexture(width,height,false);
			_renderImage2 = new Image(_renderTexture2);
			
			_defaultWorkBg = new Image(_workTexture);
			_defaultWorkBg.width = width;
			_defaultWorkBg.height = height;
			
			_drawMatrix = new Matrix();
			
			this.maskTarget = maskTarget;
			this.maskObject = maskObject;
			
		}
		
		/**
		 *マスク対象となるDisplayObject
		 */
		public function get maskTarget():DisplayObject
		{
			return _maskTarget;
		}
		
		public function set maskTarget(value:DisplayObject):void
		{
			_maskTarget = value;
		}
		
		/**
		 * マスク設定用DisplayObject
		 */
		public function get maskObject():DisplayObject
		{
			return _maskObject;
		}
		
		public function set maskObject(value:DisplayObject):void
		{
			if(_maskObject == value) return;
			_maskObject = value;
			
			if(_maskObject)
			{
				_maskObject.blendMode = BlendMode.ERASE;
				_changeChildrenBlendModeAsAuto(_maskObject);
			}
		}
		
		/**
		 * 廃棄処理 
		 * 使わなくなったら呼ぶ
		 */
		public function clean():void
		{
			_renderTexture1 && _renderTexture1.dispose();
			_renderImage1 && _renderImage1.dispose();
			_renderTexture1 = null;
			_renderImage1 = null;
			
			_renderTexture2 && _renderTexture2.dispose();
			_renderImage2 && _renderImage2.dispose();
			_renderTexture2 = null;
			_renderImage2 = null;
			
			_defaultWorkBg && _defaultWorkBg.dispose();
			
			maskTarget = null;
			_maskObject = null;
			userWorkBg = null;
			
			_drawMatrix = null;
			
			userData = null;
			
		}
		
		/**
		 * マスク演算処理を行う 
		 * @param clipPosX 背景クリップの起点x座標
		 * @param clipPosY 背景クリップの起点y座標
		 */
		public function update(clipPosX:int=0,clipPosY:int=0):void
		{
			if(maskObject && maskTarget && _renderTexture1 && _renderTexture2)
			{
				_renderTexture1.drawBundled(function():void
				{
					_renderTexture1.draw(userWorkBg || _defaultWorkBg, null);
					_renderTexture1.draw(maskObject, null);	
				});
				
				_drawMatrix.tx = - clipPosX;
				_drawMatrix.ty = - clipPosY;
				
				_renderTexture2.drawBundled(function():void
				{
					_renderTexture2.draw(maskTarget, _drawMatrix);
					_renderTexture2.draw(_renderImage1, null);	
				});			
			}
		}
		
		/**
		 * マスク演算結果のImageを得る
		 */
		public function get resultImage():Image
		{
			return _renderImage2;
		}
	}
}