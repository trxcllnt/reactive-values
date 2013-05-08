package trxcllnt
{
	import asx.array.detect;
	import asx.array.head;
	import asx.fn.K;
	import asx.fn.sequence;
	
	import flash.system.Capabilities;
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
			if(hasProperty(name) == false) return null;
			
			const val:* = properties[name];
			
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
			if(!properties.hasOwnProperty(name))
				propNames.push(name.toString());
			
			if(value is String) {
				const val:Number = process(name, value);
				properties[name] = val == val ? val : value;
			} else {
				properties[name] = value;
			}
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
		
		private static const processors:Array = [];
		private static const screenDPI:Number = Capabilities.screenDPI;
		
		public static function addProcessor(pattern:RegExp, func:Function):void {
			processors.push([pattern, func]);
		}
		
		private function process(name:String, value:String):Number {
			
			const pair:Array = detect(processors, sequence(head, asx.fn.callProperty('test', value))) as Array;
			
			if(pair == null) return NaN;
			
			const pattern:RegExp = pair[0];
			const func:Function = pair[1];
			
			return func.call(this, pattern, name, value);
		}
		
		private function getBase(name:String):Number {
			return this.hasOwnProperty(name) ? this[name] : this.hasOwnProperty('fontSize') ? this['fontSize'] : 12;
		}
		
		addProcessor(/\d+\s*?%/i, function(p:RegExp, name:String, v:String):Number {
			return this.getBase(name) * parseFloat(v.substring(0, (/%/i).exec(v).index));
		});
		
		addProcessor(/\d+\s*?px/i, function(p:RegExp, name:String, v:String):Number {
			return parseFloat(v.substring(0, (/px/i).exec(v).index));
		});
		
		addProcessor(/\d+\s*?pt/i, function(p:RegExp, name:String, v:String):Number {
			return parseFloat(v.substring(0, (/pt/i).exec(v).index)) / 72 * screenDPI;
		});
		
		addProcessor(/\d+\s*?em/i, function(p:RegExp, name:String, v:String):Number {
			return this.getBase(name) * parseFloat(v.substring(0, (/em/i).exec(v).index));
		});
		
		addProcessor(/\d+\s*?ex/i, function(p:RegExp, name:String, v:String):Number {
			return this.getBase(name) * parseFloat(v.substring(0, (/ex/i).exec(v).index)) * 0.5;
		});
		
		addProcessor(/\#/i, function(p:RegExp, name:String, v:String):Number {
			return uint('0x' + v.substring(1));
		});
	}
}