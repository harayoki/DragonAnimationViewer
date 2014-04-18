package harayoki.starling
{
	import flash.errors.IllegalOperationError;
	import flash.utils.Dictionary;
	
	import starling.animation.Juggler;
	import starling.events.Event;
	import starling.extensions.ParticleSystem;

	/**
	 *Prticleを再利用するためのプール 
	 * @author haruyuki.imai
	 * テストはかいてないよ
	 */
	public class ParticlePool
	{
		private var _types:Dictionary
		
		
		/**
		 * 自動でjugglerへの登録や登録解除を行う場合は設定する
		 * 使わなくても良い
		 */
		public var juggler:Juggler;
		
		
		/**
		 * @param juggler 自動でjugglerへの登録や登録解除を行う場合は設定する
		 */
		public function ParticlePool(juggler:Juggler=null)
		{
			_types = new Dictionary();
			this.juggler = juggler;
		}
		
		/**
		 * パーティクルを管理下におくため登録する
		 * プール制御前にはじめに登録しておく必用がある
		 * @param type パーティクルのタイプ(グループ)名
		 * @param particleSystem 登録するパーティクル
		 * @param poolImediate 自動でプールするか
		 * @return メソッドチェーン用の自身の参照
		 */
		public function registerParticleSystem(type:String,particleSystem:ParticleSystem,poolImediate:Boolean=true):ParticlePool
		{
			unregisterParticleSystem(particleSystem);
			_types[particleSystem] = type;
			if(poolImediate)
			{
				poolParticleSystem(particleSystem);
			}
			return this;
		}
		
		/**
		 * パーティクルの登録を解除する 
		 * @param particleSystem 登録解除するパーティクル
		 */
		public function unregisterParticleSystem(particleSystem:ParticleSystem):void
		{
			var type:String = _types[particleSystem];
			if(type)
			{
				ActualPool.getPoolByType(type).removeParticle(particleSystem);
				delete _types[particleSystem];
			}
		}
		
		/**
		 * パーティクルが登録済みか確認する 
		 * @param particleSystem 対象パーティクル
		 */
		public function isParticleSystemRegistered(particleSystem:ParticleSystem):Boolean
		{
			return _types[particleSystem] != null;
		}
		
		/**
		 * あるタイプ(グループ)のパーティクルを全て登録解除する 
		 * @param type タイプ名
		 */
		public function unregisterAllParticleSystem(type:String):void
		{
			_unregisterAllParticleSystem(type,false);
		}
		
		/**
		 * あるタイプ(グループ)のパーティクルを全て登録解除し、
		 * さらにインスタンスの破棄も行う
		 * @param type タイプ名
		 */
		public function disposeAllParticleSystem(type:String):void
		{
			_unregisterAllParticleSystem(type,true);
		}
		
		//登録解除用共通処理
		private function _unregisterAllParticleSystem(type:String,dispose:Boolean):void
		{			
			var pool:ActualPool = ActualPool.getPoolByType(type);
			while(pool.getLength()>0)
			{
				var ptcl:ParticleSystem = pool.takeParticle();
				unregisterParticleSystem(ptcl);
				if(dispose)
				{
					_resetParticleSystem(ptcl);
					ptcl.dispose();
				}
			}
		}
		
		//パーティクルを再利用するまえにクリーンな状態にする
		private function _resetParticleSystem(particleSystem:ParticleSystem):void
		{
			juggler && juggler.remove(particleSystem);
			particleSystem.removeEventListeners(Event.COMPLETE);//COMPLETE以外のイベントはStarling1.4.1現在ない認識
			particleSystem.stop(true);
			particleSystem.removeFromParent();			
		}
		
		/**
		 * パーティクルをプールする 
		 * パーティクルは事前に登録しておく必用がある、登録されてない場合は例外をはきます
		 * @param particleSystem 対象パーティクル
		 * @throws IllegalOperationError
		 */
		public function poolParticleSystem(particleSystem:ParticleSystem):void
		{
			var type:String = _types[particleSystem];
			if(!type)
			{
				throw(new IllegalOperationError("Register particleSystem before pooling"));
			}
			_resetParticleSystem(particleSystem);
			ActualPool.getPoolByType(type).addParticle(particleSystem);
		}
		
		/**
		 * プール済みのパーティクルを得る プール状態は解除される
		 * @param type タイプ名
		 * @return プールされていたパーティクル(プールされた物が無い場合、nullを返す)
		 */
		public function getParticleSystem(type:String):ParticleSystem
		{
			var particleSystem:ParticleSystem = ActualPool.getPoolByType(type).takeParticle();
			particleSystem && juggler && juggler.add(particleSystem);
			return particleSystem;
		}
				
		/**
		 * プール中のパーティクルがあるかどうか調べる 
		 * @param type タイプ名
		 */
		public function hasParticleSystemPooled(type:String):Boolean
		{
			return ActualPool.hasParticleSystem(type);
		}
		
	}
}

import starling.extensions.ParticleSystem;

/**
 * タイプ別プール用の内部クラス
 * @author haruyuki.imai
 */
internal class ActualPool
{
	private static var _pools:Object = {};
	
	public static function getPoolByType(type:String):ActualPool
	{
		var pool:ActualPool = _pools[type] as ActualPool;
		if(!pool)
		{
			pool = _pools[type] = new ActualPool();
		}
		return pool;
	}
	
	public static function hasParticleSystem(type:String):Boolean
	{
		var pool:ActualPool = _pools[type] as ActualPool;
		if(!pool) return false;
		return pool.getLength()>0;
	}
	
	private var _pool:Vector.<ParticleSystem>;
	public function ActualPool()
	{
		_pool = new Vector.<ParticleSystem>();
	}
	
	public function addParticle(particleSystem:ParticleSystem):void
	{
		if(_pool.indexOf(particleSystem)==-1)
		{
			_pool.push(particleSystem);
		}
	}
	
	public function takeParticle():ParticleSystem
	{
		if(_pool.length==0) return null;
		return _pool.pop();
	}
	
	public function removeParticle(particleSystem:ParticleSystem):void
	{
		var index:int = _pool.indexOf(particleSystem);
		if(index>=0)
		{
			_pool.splice(index,1);
		}
	}
	
	public function getLength():int
	{
		return _pool.length;
	}
		
}