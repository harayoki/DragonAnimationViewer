package harayoki.dragonbones
{
	import dragonBones.Armature;
	import dragonBones.Bone;
	import dragonBones.Slot;
	import dragonBones.factorys.StarlingFactory;
	import dragonBones.objects.DBTransform;
	import dragonBones.objects.ObjectDataParser;
	import dragonBones.objects.SkeletonData;
	import dragonBones.objects.XMLDataParser;
	import dragonBones.textures.StarlingTextureAtlas;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.utils.AssetManager;

	public class DragonBonesUtil
	{
        private static const HELPER_ARMATURE_VECTOR:Vector.<Armature> = new Vector.<Armature>(); 
        private static const HELPER_BONES_VECTOR:Vector.<Bone> = new Vector.<Bone>(); 
        private static const ESCAPE_REG:RegExp = /(?=(\(|\)|\^|\$|\\|\.|\*|\+|\?|\[|\]|\{|\}|\|))/g;
        private static const ALL_REG:RegExp = /.*/;
        private static function string2RegExpString(str:String):String
        {
            return "^"+str.replace(ESCAPE_REG, "\\")+"$";
        }
        
		/**
		 * アーマーチャーの内部構成をtraceする
		 * @param a 対象アーマーチャー
		 */
		public static function traceArmature(a:Armature,recursive:Boolean=true):void
		{
			if(!a)
			{
				trace("no armature : ",a);
				return;
			}
			
			traceArmatureSlots(a);
			traceArmatureBones(a);
			traceArmatureAnimations(a);
			
		}
		
		public static function traceArmatureSlots(a:Armature,recursive:Boolean=true):void
		{
			if(!a)
			{
				trace("no armature : ");
			}
			trace(a.name + " slots __________");
			
			function traceSlot(a:Armature,tab:String=""):void
			{				
				if(!a) return;
				var slots:Vector.<Slot> = a.getSlots(true);
				for each(var slot:Slot in slots)
				{
					trace(tab+slot.name);
					if(recursive)
					{
						traceSlot(slot.childArmature,tab+"*");
					}
				}	
			}
			traceSlot(a);
		}
		
		public static function traceArmatureBones(a:Armature,recursive:Boolean=true):void
		{
			if(!a)
			{
				trace("no armature : ");				
			}
			trace(a.name + " bones __________");
			
			function traceBone(a:Armature,tab:String=""):void
			{				
				if(!a) return;
				var bones:Vector.<Bone> = a.getBones(true);
				for each(var bone:Bone in bones)
				{
					trace(tab+bone.name);
					if(recursive)
					{
						traceBone(bone.childArmature,tab+"*");
					}
				}	
			}
			traceBone(a);
		}
		
		public static function traceDisplayTree(a:Armature):void
		{
			var d:DisplayObject;
			d = a.display as DisplayObject;
			var s:String = ""+d;
			while(d.parent)
			{
				d = d.parent;
				s = d + " > " + s;
			}
			trace(a.name+" : "+s);
		}
		
		/**
		 * アーマーチャーから名前をキーに内部に保持するアーマーチャーの一覧を得る
		 * @param armature 対象アーマーチャー
		 * @param slotNamePattern 名前がマッチするパターン String型またはRegExp型
		 * @param vec 任意の引数 あらたにVectorをインスタンス化したく無い時などに使う
		 * @return アーマーチャーの参照が詰まったベクター
		 * ※子孫のクエリが重いと思われるので、乱用はしない事
		 */
		public static function queryDescendantArmaturesByName(armature:Armature,slotNamePattern:*,vec:Vector.<Armature>=null,traceTree:Boolean=false):Vector.<Armature>
		{
			
			if(!vec) vec = new Vector.<Armature>();
			
			var re:RegExp = slotNamePattern is RegExp ? slotNamePattern as RegExp : new RegExp(string2RegExpString(slotNamePattern+""));
			
			function q(a:Armature,v:Vector.<Armature>,tab:String=""):void
			{
				var slots:Vector.<Slot> = a.getSlots();
				var child:Armature;
				for each(var slot:Slot in slots)
				{
                    child = slot.childArmature;
                    if(child)
                    {
						if(re.test(slot.name))
						{
                            if(traceTree)
                            {
                                trace(tab+slot.name+"("+child+")");
                            }
							v.push(child);
						}
						if(child)
                        {
                            q(child,v,tab+"-");
                        }
					}
				}
			}
			
			q(armature,vec);
			
			return vec;
		}
        
        public static function queryDescendantSlotsByName(armature:Armature,slotNamePattern:*,onlySlotWithChildArmature:Boolean=false,vec:Vector.<Slot>=null):Vector.<Slot>
        {
            
            if(!vec) vec = new Vector.<Slot>();
            var re:RegExp = slotNamePattern is RegExp ? slotNamePattern as RegExp : new RegExp(string2RegExpString(slotNamePattern+""));
            
            function q(a:Armature,v:Vector.<Slot>,tab:String=""):void
            {
                var slots:Vector.<Slot> = a.getSlots();
                var child:Armature;
                for each(var slot:Slot in slots)
                {
                    child = slot.childArmature;
                    if(!onlySlotWithChildArmature || (onlySlotWithChildArmature && child))
                    {
                        if(re.test(slot.name))
                        {
                            v.push(slot);
                        }
                        if(child)
                        {
                            q(child,v,tab+" ");
                        }
                    }
                }
            }
            
            q(armature,vec);
            
            return vec;
        }
        
        public static function queryDescendantBonesByName(armature:Armature,boneNamePattern:*,onlyBoneWithChildArmature:Boolean=false,vec:Vector.<Bone>=null):Vector.<Bone>
        {
            
            if(!vec) vec = new Vector.<Bone>();
            var re:RegExp = boneNamePattern is RegExp ? boneNamePattern as RegExp : new RegExp(string2RegExpString(boneNamePattern+""));
            
            function q(a:Armature,v:Vector.<Bone>,tab:String=""):void
            {
                var bones:Vector.<Bone> = a.getBones();
                var child:Armature;
                for each(var bone:Bone in bones)
                {
                    child = bone.childArmature;
                    if(!onlyBoneWithChildArmature || (onlyBoneWithChildArmature && child))
                    {
                        if(re.test(bone.name))
                        {
                            v.push(bone);
                        }
                        if(child)
                        {
                            q(child,v,tab+" ");
                        }
                    }
                }
            }
            
            q(armature,vec);
            
            return vec;
        }
        
        /**
         * 名前をキーに最初に見つかったアーマーチャーを得る
         * @param armature 対象アーマーチャー
         * @param slotNamePattern 名前がマッチするパターン String型またはRegExp型
         * @return 見つかったアーマーチャー
         */
        public static function findArmatureByName(armature:Armature,slotNamePattern:*):Armature
        {
            var re:RegExp = slotNamePattern is RegExp ? slotNamePattern as RegExp : new RegExp(string2RegExpString(slotNamePattern+""));
            
            var found:Armature;
            function q(a:Armature):void
            {
                var slots:Vector.<Slot> = a.getSlots();
                var child:Armature;
                var slot:Slot;
                for each(slot in slots)
                {
                    if(found) return;
                    child = slot.childArmature;
                    if(child)
                    {
                        if(re.test(slot.name))
                        {
                            found = child;
                            return;
                        }
                        else
                        {
                            q(child);
                        }
                    }
                }
            }
            q(armature);
            
            return found;
        }
        
        public static function findSlotByName(armature:Armature,slotNamePattern:*):Slot
        {
            var re:RegExp = slotNamePattern is RegExp ? slotNamePattern as RegExp : new RegExp(string2RegExpString(slotNamePattern+""));
            
            var found:Slot;
            function q(a:Armature):void
            {
                var slots:Vector.<Slot> = a.getSlots();
                var child:Armature;
                var slot:Slot;
                for each(slot in slots)
                {
                    if(found) return;
                    child = slot.childArmature;
                    if(re.test(slot.name))
                    {
                        found = slot;
                        return;
                    }
                    if(child) q(child);
                }
            }
            q(armature);
            
            return found;
        }

        public static function findBoneByName(armature:Armature,boneNamePattern:*):Bone
        {
            var re:RegExp = boneNamePattern is RegExp ? boneNamePattern as RegExp : new RegExp(string2RegExpString(boneNamePattern+""));
            
            var found:Bone;
            function q(a:Armature):void
            {
                var bones:Vector.<Bone> = a.getBones();
                var child:Armature;
                var bone:Bone;
                for each(bone in bones)
                {
                    if(found) return;
                    child = bone.childArmature;
                    //trace(bone.name);
                    if(re.test(bone.name))
                    {
                        found = bone;
                        return;
                    }
                    if(child) q(child);
                }
            }
            q(armature);
            
            return found;
        }
        
        public static function insertDisplayObjectAtBone(armature:Armature,dobj:DisplayObject,pattern:*,attachInner:Boolean=false):Boolean
        {
            var reg:RegExp;
            if(pattern is RegExp)
            {
                reg = pattern;
            }
            else
            {
                reg = new RegExp(string2RegExpString(pattern+""));
            }
            var bone:Bone = DragonBonesUtil.findBoneByName(armature,reg);
            if(bone && bone.display)
            {
                var origin:DBTransform = bone.origin;
                var location:DisplayObject = bone.display as DisplayObject;
                if(attachInner && location is DisplayObjectContainer)
                {
                    dobj.x = 0;
                    dobj.y = 0;
                    DisplayObjectContainer(location).addChild(dobj);
                }
                else
                {
                    dobj.x = origin.x;
                    dobj.y = origin.y;
                    location.parent.addChild(dobj);
                }
                return true;
            }
            else
            {
                trace("can not find insert target Bone:"+pattern);
            }
            return false;
        }
        
        public static function traceArmatureAnimations(a:Armature,recursive:Boolean=true):void
		{
			if(!a)
			{
				trace("no armature : ");
			}
			trace(a.name + " animations __________");
			
			function traceAnimations(a:Armature,tab:String=""):void
			{				
				if(!a) return;
				var anims:Vector.<String> = a.animation.animationList
				trace(tab+anims);
				var bones:Vector.<Bone> = a.getBones();
				if(recursive)
				{
					for each(var bone:Bone in bones)
					{
						traceAnimations(bone.childArmature,tab+"*");
					}
				}	
			}
			traceAnimations(a);
		}		
		
		/**
		 * patternにマッチするボタン内部の子孫Armatureをまとめてアニメさせる
		 * @param slotNamePattern 名前パターン String型またはRegExp型
		 * @param animationName 移動するアニメーション名
		 * @param vec 任意の引数 あらたにVectorをインスタンス化したく無い時などに使う
		 */
		public static function gotoAndPlayBySlotName(armature:Armature,slotNamePattern:*,animationName:String,vec:Vector.<Armature>=null):void
		{
			if(!armature) return;
			
			if(!vec)
			{
				vec = new Vector.<Armature>();
			}
			vec.length = 0;
			DragonBonesUtil.queryDescendantArmaturesByName(armature,slotNamePattern,vec);
			for each(var a:Armature in vec)
			{
				a.animation && a.animation.gotoAndPlay(animationName);
			}			
		}		
		
		/**
		 * patternにマッチするボタン内部の子孫ArmatureのアニメをまとめてStopさせる
		 * @param pattern 名前パターン String型またはRegExp型
		 * @param animationName 移動するアニメーション名
		 * @param vec 任意の引数 あらたにVectorをインスタンス化したく無い時などに使う
		 */
		public static function stopAnimationBySlotName(armature:Armature,pattern:*,vec:Vector.<Armature>=null):void
		{
			if(!armature) return;
			
			if(!vec)
			{
				vec = new Vector.<Armature>();
			}
			vec.length = 0;
			DragonBonesUtil.queryDescendantArmaturesByName(armature,pattern,vec);
			for each(var a:Armature in vec)
			{
				a.animation && a.animation.stop();
			}			
		}
        
        /**
         * xml*２ファイル + 画像ファイルで書き出されたDragonBonesのデータをStarlingFactoryに登録する
         * @param assetmanager assetmanager参照
         * @param factory factory参照
         * @param atlasName アトラスのファイル名の拡張子を除いた部分 (ex "asset/hoge.png"の場合、"hoge")
         * @param skeletonName スケルトンのファイル名の拡張子を除いた部分 (ex "asset/hoge_skeleton.xml"の場合、"hoge_skeleton")
         * @param disposeData 初期化後に必要なくなったリソースをassetmanagerがら削除するか
         */
        public static function setUpFactoryByXmlData(assetmanager:AssetManager,factory:StarlingFactory,atlasName:String,skeletonName:String,disposeData:Boolean=true):void
        {
            var atlas:TextureAtlas;
            var xml:XML = assetmanager.getXml(skeletonName);
            var skeleton:SkeletonData;
            skeleton = XMLDataParser.parseSkeletonData(xml);
            atlas = assetmanager.getTextureAtlas(atlasName);
            if(disposeData)
            {
                assetmanager.removeXml(skeletonName,true);
            }
            
            factory.addTextureAtlas(atlas,atlasName);
            factory.addSkeletonData(skeleton,atlasName);

        }
        
        /**
         * json*２ファイル + 画像ファイルで書き出されたDragonBonesのデータをStarlingFactoryに登録する
         * @param assetmanager assetmanager参照
         * @param factory factory参照
         * @param atlasName アトラスのファイル名の拡張子を除いた部分 (ex "asset/hoge.png"の場合、"hoge")
         * @param skeletonName スケルトンのファイル名の拡張子を除いた部分 (ex "asset/hoge_skeleton.xml"の場合、"hoge_skeleton")
         * @param disposeData 初期化後に必要なくなったリソースをassetmanagerがら削除するか
         */
        public static function setUpFactoryByJsonData(assetmanager:AssetManager,factory:StarlingFactory,atlasName:String,skeletonName:String,disposeData:Boolean=true):void
        {
            var atlas:TextureAtlas;
            var json:Object = assetmanager.getObject(skeletonName);
            var texture:Texture;
            var skeleton:SkeletonData;
            var rawData:Object;
            
            skeleton = ObjectDataParser.parseSkeletonData(json);
            texture = assetmanager.getTexture(atlasName);
            rawData = assetmanager.getObject(atlasName)
            atlas = new StarlingTextureAtlas(texture,rawData);
            
            if(disposeData)
            {
                assetmanager.removeObject(skeletonName);
                assetmanager.removeObject(atlasName);
                assetmanager.removeTexture(atlasName,false);
            }
            
            factory.addTextureAtlas(atlas,atlasName);
            factory.addSkeletonData(skeleton,atlasName);

        }
        
        /**
         * jsonかxmlかどちらか自動判別してDragonBonesのデータをStarlingFactoryに登録する
         * @see setUpFactoryByXmlData
         * @see setUpFactoryByJsonData
         */
        public static function setUpFactoryAutoDetect(assetmanager:AssetManager,factory:StarlingFactory,atlasName:String,skeletonName:String,disposeData:Boolean=true):void
        {
            var json:Object = assetmanager.getObject(skeletonName);
            if(json)
            {
                setUpFactoryByJsonData(assetmanager,factory,atlasName,skeletonName,disposeData);
                return;
            }
            var xml:XML = assetmanager.getXml(skeletonName);
            if(xml)
            {
                setUpFactoryByXmlData(assetmanager,factory,atlasName,skeletonName,disposeData);
                return;
            }
        }
        
        public static function setAllDisplayObjectTouchable(armature:Armature,touchable:Boolean,applyRoot:Boolean=false):void
        {
            if(applyRoot)
            {
                DisplayObjectContainer(armature.display).touchable = touchable;
            }
            
            function q(a:Armature,tab:String=""):void
            {
                var slots:Vector.<Slot> = a.getSlots();
                var child:Armature;
                var dobj:DisplayObject;
                for each(var slot:Slot in slots)
                {
                    dobj = slot.display as DisplayObject;
                    if(dobj)
                    {
                        dobj.touchable = false;
                    }
                    child = slot.childArmature;
                    if(child)
                    {
                        q(child,tab+"-");
                    }
                }
            }
            
            q(armature);
        }
        
        /**
         * Armature内の子孫Armatureをボタン化する
         * @param armature 対象親Armature
         * @param pattern ボタン化させるArmatureの命名ルール
         * @param returnVector 任意 戻り値のVectorを新規で内部で生成させたくない場合に渡す
         * @return ボタンの配列(Vector)
         */
        public static function makeInnerArmatureButton(armature:Armature,pattern:RegExp,returnVector:Vector.<ArmatureButton>=null):Vector.<ArmatureButton>
        {
            returnVector = returnVector ? returnVector : new Vector.<ArmatureButton>();
            var bones:Vector.<Bone> = queryDescendantBonesByName(armature,pattern,true);
            for each(var bone:Bone in bones)
            {
                var arm:Armature = bone.childArmature;
                var btn:ArmatureButton = new ArmatureButton(arm,false,null,bone);
                btn.name = bone.name;
                returnVector.push(btn);
            }
            return returnVector;
        }
        
        /**
         * Armature内の子孫BoneをDisplayObject差し込み用オブジェクト化する
         * @param armature 対象親Armature
         * @param pattern Holder化させるBoneの命名ルール
         * @param returnVector 任意 戻り値のVectorを新規で内部で生成させたくない場合に渡す
         * @return DisplayObjectsHolderの配列(Vector)
         */
        public static function makeInnerDisplayObjectsHolder(
                armature:Armature,pattern:RegExp,
                returnVector:Vector.<DisplayObjectsHolder>=null,
                hideInitilaDisplayObject:Boolean=true
        ):Vector.<DisplayObjectsHolder>
        {
            var onlyBoneWithChildArmature:Boolean = true;
            
            returnVector = returnVector ? returnVector : new Vector.<DisplayObjectsHolder>();
            var bones:Vector.<Bone> = queryDescendantBonesByName(armature,pattern,onlyBoneWithChildArmature);
            for each(var bone:Bone in bones)
            {
                var arm:Armature = bone.childArmature;
                if(arm)
                {
                    var holder:DisplayObjectsHolder = new DisplayObjectsHolder(bone,hideInitilaDisplayObject);
                    holder.name = bone.name;
                    returnVector.push(holder);
                }
            }
            return returnVector;
        }
        
        /**
         * ある命名規則のboneを削除する
         * @param armature 対象Armature
         * @param pattern ボーン名 正規表現
         */
        public static function removeBonesByName(armature:Armature,pattern:RegExp):void
        {
            
            function q(a:Armature,v:Vector.<Bone>,tab:String=""):void
            {
                var bones:Vector.<Bone> = a.getBones();
                var child:Armature;
                for each(var bone:Bone in bones)
                {
                    if(pattern.test(bone.name))
                    {
                        trace("remove bone : " + bone.name);
                        a.removeBone(bone);
                    }
                    child = bone.childArmature;
                    if(child)
                    {
                        q(child,v,tab+" ");
                    }
                }
            }
            
            HELPER_BONES_VECTOR.length = 0;
            q(armature,HELPER_BONES_VECTOR);
            
        }
        
        /**
         * あるBoneにあるArmatureの子供Boneを移植する
         * (armature.addChild(armature)というような感覚)
         */
        public static function insertChildBonesIntoBone(parentBone:Bone,armature:Armature):void
        {
            armature.getBones().forEach(function(bone:Bone,index:int,v:Vector.<Bone>):void{
                //parentBone.addChild(bone);//この処理だと中にあるアニメーションがうまくうごかなくなる。。
                parentBone.childArmature.addBone(bone);
            });
        }
        
        
    }
}