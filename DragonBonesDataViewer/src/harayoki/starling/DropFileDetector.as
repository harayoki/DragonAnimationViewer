package harayoki.starling
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeDragManager;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	
	import org.osflash.signals.Signal;

	/**
	 * 汎用的にファイルのドラッグアンドドロップをさばく 
	 * @author haruyuki.imai
	 */
	public class DropFileDetector
	{
		
		/**
		 * ステージサイズのファイルのドロップ受け先になるInteractiveObjectを作成して返す
		 * @param stage ステージ参照
		 * @param autoStretch ステージの伸縮に自動で大きさを追従させる場合trueを渡す
		 */
		public static function createStageSizeDropTarget(stage:Stage,autoStretch:Boolean=true):InteractiveObject
		{
			var sp:Sprite = new Sprite();
			function redraw(ev:Event=null):void
			{
				sp.graphics.clear();
				sp.graphics.beginFill(0xff0000,0.0);
				sp.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
				sp.graphics.endFill();
			}
			redraw();
			
			if(autoStretch)
			{
				stage.addEventListener(Event.RESIZE,redraw);
			}
			
			return sp;
		}
		
		/**
		 * 最後にファイルがドロップされた座標を返す 
		 */
		public function get lastDropGlobalPosition():Point
		{
			return _lastDropGlobalPosition;
		}

		/*public function set lastDropGlobalPosition(value:Point):void
		{
			_lastDropGlobalPosition = value;
		}*/

		/**
		 * 拡張子でドロップを受け付けるファイルの一覧
		 * フィルタリングを行う場合ここに直接拡張子を追加して行く
		 * ("."はいらない) 
		 */
		public function get extensionFilter():Vector.<String>
		{
			return _extensionFilter;
		}

		/**
		 * 最後にドロップされたファイルの一覧を得る
		 */
		public function get lastDropFiles():Vector.<File>
		{
			return _lastDropFiles;
		}

		
		public var onDrop:Signal = new Signal();		
		private var _interactiveObject:InteractiveObject;
		private var _lastDropFiles:Vector.<File>;		
		private var _extensionFilter:Vector.<String>;
		private var _lastDropGlobalPosition:Point;
		
		/**
		 * ファイルのドロップ受け先になるInteractiveObject
		 * (createStageSizeDropTargetメソッドで作成すれば良い)
		 */
		public function DropFileDetector(interactiveObject:InteractiveObject)
		{
			_interactiveObject = interactiveObject;
			_extensionFilter = new Vector.<String>();
			_lastDropFiles = new Vector.<File>();
			_lastDropGlobalPosition = new Point(NaN,NaN);
		}
		
		/**
		 * ファイルのドロップ検知を開始する
		 */
		public function start():void
		{
			_interactiveObject.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, handleDragEnter);
			_interactiveObject.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, handleDrop);
			_lastDropFiles.length = 0;
		}
		
		/**
		 * ファイルのドロップ検知を停止する
		 */
		public function stop():void
		{
			_interactiveObject.removeEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, handleDragEnter);
			_interactiveObject.removeEventListener(NativeDragEvent.NATIVE_DRAG_DROP, handleDrop);
			_lastDropFiles.length = 0;
		}
		
		private function handleDragEnter(ev:NativeDragEvent):void
		{
			var clipboard:Clipboard = ev.clipboard;
			
			var isOk:Boolean = false;
			var formats:Array = clipboard.formats;
			formats.forEach(function(format:String,index:int,arr:Array):void{
				if(format == ClipboardFormats.FILE_LIST_FORMAT)
				{
					isOk = true;
				}
			});
			
			if(!isOk) return;
			
			isOk = false;
			
			if(_extensionFilter.length>0)
			{
				var fileList:Array = clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
				fileList.forEach(function(file:File,index:int,arr:Array):void{
					isOk = isOk || _checkExtension(file);
				});
			}
			else
			{
				isOk = true;
			}
			
			if(isOk)
			{
				NativeDragManager.acceptDragDrop(_interactiveObject);			
			}
			/*
			ClipboardFormats.BITMAP_FORMAT;
			ClipboardFormats.FILE_LIST_FORMAT;
			ClipboardFormats.FILE_PROMISE_LIST_FORMAT;
			ClipboardFormats.HTML_FORMAT;
			ClipboardFormats.RICH_TEXT_FORMAT;
			ClipboardFormats.TEXT_FORMAT;
			ClipboardFormats.URL_FORMAT;
			*/

		}
		
		private function handleDrop(ev:NativeDragEvent):void
		{
			_lastDropFiles.length = 0;
			
			_lastDropGlobalPosition.x = ev.stageX;
			_lastDropGlobalPosition.y = ev.stageY;
			
			var clipboard:Clipboard = ev.clipboard;
			var fileList:Array = clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT) as Array;
			fileList.forEach(function(file:File,index:int,arr:Array):void{
				
				if(_extensionFilter.length>0)
				{
					if(_checkExtension(file))
					{
						_lastDropFiles.push(file);
					}
				}
				else
				{
					_lastDropFiles.push(file);
				}
			});
			
			if(_lastDropFiles.length>0)
			{
				onDrop.dispatch();				
			}
		}
		
		private function _checkExtension(file:File):Boolean
		{
			if(_extensionFilter.length == 0) return true;
			var a:Array = file.name.split(".");
			var ext:String = a[a.length-1];
			return (_extensionFilter.indexOf(ext)>=0);
		}
	}
}