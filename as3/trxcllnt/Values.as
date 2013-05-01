/*
 * Copyright (c) 2013 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */
package trxcllnt
{
	import asx.array.filter;
	import asx.array.flatten;
	import asx.array.forEach;
	import asx.array.toDictionary;
	import asx.fn.callProperty;
	import asx.fn.callXMLProperty;
	import asx.fn.not;
	import asx.fn.partial;
	import asx.object.newInstance_;
	
	import flash.utils.*;
	
	import raix.reactive.*;
	import raix.reactive.scheduling.*;
	
	use namespace flash_proxy;
	
	/**
	 * <p>
	 * Values is a dynamic IObservable value container.
	 * </p>
	 * 
	 * <p>
	 * Since it extends Proxy, it overrides the flash_proxy functions for setting
	 * and retrieving data.
	 * </p>
	 */
	public dynamic class Values extends DynObservable implements ICancelable
	{
		public function Values(styleObject:Object = null, ...excludedToStringProps)
		{
			mergeWith(styleObject);
			
			forEach(flatten(excludedToStringProps), function(prop:String):void {
				excludedToStringProperties[prop] = true;
			});
		}
		
		private const subscribers:Array = [];
		
		override public function subscribeWith(observer:IObserver):ICancelable {
			
			subscribers.push(observer);
			
			return Cancelable.create(function():void {
				const i:int = subscribers.indexOf(observer);
				if(i != -1) subscribers.splice(i, 1);
			});
		}
		
		public function cancel():void {
			dispatch(asx.fn.callProperty('onCompleted'));
			subscribers.length = 0;
		}
		
		public function observe(...properties):IObservable {
			properties = flatten(properties);
			
			if(properties.length == 0) throw new Error('...well this is awkward :/');
			
			const wildcard:Boolean = properties.indexOf('*') != -1;
			
			return filter(function(changes:Array):Boolean {
				return wildcard || properties.indexOf(changes[1]) != -1;
			});
		}
		
		public function combine(...properties):IObservable {
			properties = flatten(properties);
			
			if(properties.length == 0) throw new Error('...well this is awkward :/');
			
			const name:String = properties[0];
			const value:* = name == '*' ? this : this[name];
			
			const filtered:IObservable = observe(name);
			
			const obs:IObservable = (value == undefined || value != value) ?
				filtered :
				filtered.startWith([[this, name, value, value]]);
			
			return properties.length == 1 ?
				obs :
				obs.combineLatest(combine(properties.slice(1)), partial(newInstance_, Array));
		}
		
		public function mergeWith(object:Object):Values
		{
			for(var prop:String in object)
				mergeProperty(prop, object);
			
			return this;
		}
		
		public function mergeXMLList(list:XMLList):Values
		{
			return mergeWith(toDictionary(
				list,
				callXMLProperty('localName'),
				callXMLProperty('toString')
			));
		}
		
		public function applyTo(object:Object, dynamic:Boolean = false):Values
		{
			for(var prop:String in store)
				applyProperty(prop, object, dynamic);
			
			return this;
		}
		
		protected var store:Store = new Store();
		protected var excludedToStringProperties:Object = {};
		
		public function toString():String
		{
			const printable:Array = asx.array.filter(store.keys, not(excludedToStringProperties.hasOwnProperty));
			const strings:Array = asx.array.map(printable, function(prop:String):String {
				return prop + ': ' + store[prop].toString();
			});
			return '{' + strings.join('; ') + '}';
		}
		
		protected function mergeProperty(property:String, source:Object):void
		{
			this[property] = source[property];
		}
		
		protected function applyProperty(property:String, destination:Object, dynamic:Boolean = false):void
		{
			if(!destination.hasOwnProperty(property) && !dynamic)
				return;
			
			if(destination[property] is Function) return;
			
			destination[property] = this[property];
		}
		
		protected function update(name:String, o:*, n:*):void {
			dispatch(asx.fn.callProperty('onNext', [this, name, o, n]));
		}
		
		protected function dispatch(action:Function):void {
			forEach(subscribers.concat(), action);
		}
		
		override flash_proxy function getProperty(name:*):*
		{
			return store[name];
		}
		
		override flash_proxy function hasProperty(name:*):Boolean
		{
			return store.hasOwnProperty(name);
		}
		
		override flash_proxy function callProperty(name:*, ... parameters):*
		{
			if(store.hasOwnProperty(name) == false) return null;
			
			const val:* = store[name];
			
			return (val is Function) ? val.apply(this, parameters) : val;
		}
		
		override flash_proxy function deleteProperty(name:*):Boolean
		{
			const val:* = store[name];
			
			if(delete store[name])
			{
				update(name, val, undefined);
				
				return true;
			}
			
			return false;
		}
		
		override flash_proxy function setProperty(name:*, value:*):void
		{
			update(name, store[name], store[name] = value);
		}
		
		override flash_proxy function nextName(index:int):String
		{
			return store.flash_proxy::nextName(index);
		}
		
		override flash_proxy function nextNameIndex(index:int):int
		{
			return store.flash_proxy::nextNameIndex(index);
		}
		
		override flash_proxy function nextValue(index:int):*
		{
			return store.flash_proxy::nextValue(index);
		}
	}
}
