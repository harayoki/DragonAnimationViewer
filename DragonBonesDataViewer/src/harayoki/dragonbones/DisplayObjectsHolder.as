package harayoki.dragonbones
{
    import flash.geom.Rectangle;
    
    import dragonBones.Armature;
    import dragonBones.Bone;
    
    import starling.display.DisplayObject;
    import starling.display.DisplayObjectContainer;
    import starling.display.Quad;
    import starling.display.Sprite;
    import starling.utils.HAlign;
    import starling.utils.VAlign;

    public class DisplayObjectsHolder
    {
        private var _orgBounds:Rectangle;
        private var _bone:Bone;
        private var _orgScaleY:Number = 1.0;
        private var _altDisplay:DisplayObjectContainer;
        private var _container:DisplayObjectContainer;
        private var _insertedList:Vector.<DisplayObject>;
        private var _isShow:Boolean = true;
        private var _color:uint = 0xffffff;
        
        public var name:String = "";
        
        public function DisplayObjectsHolder(bone:Bone,hideInitilaDisplayObject:Boolean=true)
        {
            _bone = bone;
            _orgScaleY = _bone.origin.scaleY;
            if(!_bone.childArmature)
            {
                throw(new ArgumentError("bone must have child armature."));
            }
            var dobj:DisplayObject = _bone.childArmature.display as DisplayObject;
            
            if(dobj is DisplayObjectContainer)
            {
                _orgBounds = new Rectangle();
                dobj.getBounds(dobj.parent,_orgBounds);
                _container = dobj as DisplayObjectContainer;
                
                _bone.childArmature.getBones().forEach(
                    function(childBone:Bone,index:int,v:Vector.<Bone>):void{
                        if(childBone.display is Quad)
                        {
                            _color = Quad(childBone.display).color;
                        }
                        if(hideInitilaDisplayObject)
                        {
                            //親Bone中にアニメーションが仕込まれていると、このパーツは見えてしまうが仕様としてアニメーションはしこまない事とする
                            DisplayObject(childBone.display).alpha = 0;
                        }
                    },null
                );
            }
            else
            {
                trace("CAUTION : child armature should be display object container.");
                //※ 下記、動作未検証
                _altDisplay = new Sprite();
                _container = _altDisplay;
                _altDisplay.x = _bone.origin.x;
                _altDisplay.y = _bone.origin.y;
                _altDisplay.scaleX = _bone.origin.scaleX;
                _altDisplay.scaleY = _bone.origin.scaleY;
                dobj.parent.addChild(_altDisplay);
                _color = 0x000000;
            }
            _insertedList = new Vector.<DisplayObject>();
        }
        
        public function toString():String
        {
            return "[DisplayObjectsHolder:"+name+(armature ? "("+armature.name+")" : "" ) +"]"
        }
        
        public function get armature():Armature
        {
            return _bone ? _bone.childArmature : null;
        }
        
        public function get display():DisplayObject
        {
            return (armature ? armature.display : null) as DisplayObject;
        }
        
        public function get bone():Bone
        {
            return _bone;
        }
        
        public function show():void
        {
            _isShow = true;
            _bone.origin.scaleY = _orgScaleY;
        }
        
        public function hide():void
        {
            _isShow = false;
            _bone.origin.scaleY = 0.0;
        }
        
        public function isShow():Boolean
        {
            return _isShow;
        }
        
        public function clearInserted(dispose:Boolean=true):void
        {
            var i:int = _insertedList.length;
            while(i--)
            {
                _insertedList[i].removeFromParent(dispose);
            }
        }
        
        public function getOriginalContainerWidth():Number
        {
            return _orgBounds ? _orgBounds.width : 0;
        }
        
        public function getOriginalContainerHeight():Number
        {
            return _orgBounds ? _orgBounds.height : 0;
        }
        
        public function getOriginalContainerColor():uint
        {
            return _color;
        }
        public function dispose():void
        {
            clearInserted(true);
            
            if(_bone)
            {
                _bone.origin.scaleY = _orgScaleY;
                if(_altDisplay)
                {
                    _altDisplay.dispose();
                }
            }
            
            _altDisplay = null;
            _bone = null;
            _insertedList = null;
            _container = null;
        }
        
        /**
         * displayObjectをインサートする
         * halignやvalignを指定した場合はpivotX,pivotYの値が変更されます
         */
        public function insertDisplay(display:DisplayObject,halign:String=null,valign:String=null):void
        {
            _container.addChild(display);
            _insertedList.push(display);
            //trace(display.x,display.y,display.width,display.height,display.pivotX,display.pivotY);
            if(halign)
            {
                display.pivotX = 0;
                if(halign == HAlign.CENTER)
                {
                    display.x = -(display.width*0.5);
                }
                else if(halign == HAlign.LEFT)
                {
                    display.x = 0;
                }
                else if(halign == HAlign.RIGHT)
                {
                    display.x = - display.width;
                }
            }
            if(valign)
            {
                display.pivotY = 0;
                if(valign == VAlign.BOTTOM)
                {
                    display.y = - display.height;
                }
                else if(valign == VAlign.CENTER)
                {
                    display.y = - (display.height*0.5);
                }
                else if(valign == VAlign.TOP)
                {
                    display.y = 0;
                }
            }
            //trace(display.x,display.y,display.width,display.height,display.pivotX,display.pivotY);
        }
        
        public function insertDisplayFit(display:DisplayObject):void
        {
            _container.addChild(display);
            _insertedList.push(display);
            if(_orgBounds && _orgBounds.width > 0 && _orgBounds.height > 0)
            {
                display.pivotX = 0;
                display.pivotY = 0;
                display.width = _orgBounds.width;
                display.height = _orgBounds.height;
                display.x = 0;
                display.y = 0;
            }
        }
    }
}