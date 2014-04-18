package harayoki.util
{
	import flash.display.Shape;
	import flash.events.Event;
	
	/**
	 * フレーム数ベースで遅延コールバック処理を行います 
	 * (時間ベースの場合はsetTimeoutを使えばいい)
	 * @author haruyuki.imai
	 */
	public class DelayCallbacker
	{
		
		private static var idCnt:uint;
		
		private static var shape:Shape;
		
		private static var infoAll:Array;
		
		public function DelayCallbacker()
		{			
			shape = new Shape();
			shape.addEventListener(Event.ENTER_FRAME, _handleEnterFrame);
			infoAll = [];
		}
		
		/**
		 * 遅延処理を登録する
		 * @param frame 待ちフレーム数
		 * @param handler 遅延コールバック
		 * @param args 任意の引数
		 * @return キャンセル時に使うID番号
		 */
		public static function executeAfter(frame:int, handler:Function, ... args):uint
		{
			
			var info:Info = Info.getOne();
			info.leftFrame = frame;
			info.handler = handler;
			info.args = args;
			info.id = ++idCnt;
			info.cancel = false;
			
			infoAll.push(info);
			infoAll.sortOn("leftFrame", Array.NUMERIC);
			
			return info.id;
		}
		
		/**
		 * 遅延処理をキャンセルする
		 * @param id 処理の登録時に渡されたID番号
		 */
		public static function cancel(id:uint):void
		{
			for each (var info:Info in infoAll)
			{
				if (info.id == id)
				{
					info.cancel = true;
				}
			}
		}
		
		private function _handleEnterFrame(e:Event):void
		{
			var len:int = infoAll.length;
			if (len > 0)
			{
				var completeCnt:int = 0;
				var info:Info;
				for (var i:int = 0; i < len; i++)
				{
					info = infoAll[i];
					if (--info.leftFrame <= 0)
					{
						completeCnt++;
					}
				}
				for (i = 0; i < completeCnt; i++)
				{
					info = infoAll.shift();
					if (!info.cancel)
					{
						info.handler.apply(null, info.args);
					}
					Info.addOne(info);
				}
			}
		}
		
	}
}

/**
 * コールバック情報オブジェクト 
 */
class Info {
	
	private static var _pool:Vector.<Info>;
	
	public static function getOne():Info
	{
		
		if(!_pool)
		{
			_pool = new Vector.<Info>();
			prepare(32);
		}
		
		if(_pool.length>0)
		{
			return _pool.pop();
		}		
		return new Info();
	}
	
	public static function addOne(callback:Info):void
	{
		callback.handler = null;
		callback.args = null;
		callback.cancel = false;
		callback.leftFrame = 0;
		callback.name = "";
		callback.id = 0;
		_pool.push(callback);
	}
	
	public static function prepare(numInstance:int):void
	{
		while(numInstance--)
		{
			addOne(new Info());
		}
	}
	
	public var handler:Function;
	public var args:*;
	public var leftFrame:int;
	public var name:String;
	public var cancel:Boolean;
	public var id:uint;
	public function Info()
	{
	}
}