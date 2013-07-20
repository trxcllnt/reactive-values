package trxcllnt
{
	import asx.array.compact;
	import asx.array.head;
	import asx.array.map;
	import asx.fn.callFunction;
	import asx.fn.noop;
	
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	use namespace flash_proxy
	
	public dynamic class Store extends Proxy
	{
		public function Store()
		{
			super();
		}
		
		protected var properties:Object = {};
		protected var propNames:Array = [];
		
		public function clone():Store {
			
			const store:Store = new Store();
			
			const bytes:ByteArray = new ByteArray();
			bytes.writeObject(properties);
			bytes.position = 0;
			
			store.propNames = propNames.concat();
			store.properties = bytes.readObject();
			
			return store;
		}
		
		public function get keys():Array {
			return propNames.concat();
		}
		
		override flash_proxy function getProperty(name:*):*
		{
			return properties[name];
		}
		
		override flash_proxy function hasProperty(name:*):Boolean
		{
			return propNames.indexOf(name) != -1;
		}
		
		override flash_proxy function callProperty(name:*, ... parameters):*
		{
			const method:String = name.toString(); 
			
			if(method == 'processName') return processName.apply(this, parameters);
			if(method == 'processValue') return processValue.apply(this, parameters);
			if(method == 'getBase') return getBase.apply(this, parameters);
			if(method == 'setPropertyPlain') return setPropertyPlain.apply(this, parameters);
			if(method == 'setProperty') return setProperty.apply(this, parameters);
			
			if(hasProperty(method) == false) return null;
			
			const val:* = properties[method];
			
			return (val is Function) ? val.apply(this, parameters) : val;
		}
		
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			const val:* = properties[name];
			
			if(delete properties[name])
			{
				propNames.splice(propNames.indexOf(name.toString()), 1);
				
				return true;
			}
			
			return false;
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			(value is String) == false ?
				setPropertyPlain(name, value) :
				(processName(name, value) || processValue(name, value)) == false ?
					setPropertyPlain(name, value) :
					noop();
		}
		
		protected function setPropertyPlain(name:*, value:*):void {
			if(!properties.hasOwnProperty(name))
				propNames.push(name.toString());
			
			properties[name] = value;
		}
		
		override flash_proxy function nextName(index:int):String
		{
			return propNames[index - 1];
		}
		
		override flash_proxy function nextNameIndex(index:int):int
		{
			return index < propNames.length ? index + 1 : 0;
		}
		
		override flash_proxy function nextValue(index:int):*
		{
			return properties[propNames[index - 1]];
		}
		
		protected static const nameProcessors:Array = [];
		protected static const valueProcessors:Array = [];
		protected static const screenDPI:Number = Capabilities.screenDPI;
		
		public static function addNameProcessor(func:Function):void {
			nameProcessors.push(func);
		}
		
		public static function addValueProcessor(func:Function):void {
			valueProcessors.push(func);
		}
		
		protected static function findNameProcessor(name:String):Function {
			return head(compact(map(nameProcessors, callFunction(name)))) as Function;
		}
		
		protected static function findValueProcessor(value:String):Function {
			return head(compact(map(valueProcessors, callFunction(value)))) as Function;
		}
		
		protected function processName(name:String, value:String):Boolean {
			
			const processor:Function = findNameProcessor(name);
			
			if(processor == null) return false;
			
			processor.call(this, name, value);
			
			return true;
		}
		
		protected function processValue(name:String, value:String):Boolean {
			
			const processor:Function = findValueProcessor(value);
			
			if(processor == null) return false;
			
			processor.call(this, name, value);
			
			return true;
		}
		
		protected function getBase(name:String):Number {
			return this.hasOwnProperty('fontSize') == true ?
				this['fontSize'] :
				this.hasOwnProperty('baseFontSize') == true ?
					this['baseFontSize'] :
					12;
		}
	}
}