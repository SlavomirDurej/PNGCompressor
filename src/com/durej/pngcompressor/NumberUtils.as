/**
 * @author slavd
 */
package com.durej.pngcompressor
{
	import flash.globalization.LocaleID;
	import flash.globalization.NumberFormatter;
	
	public class NumberUtils {
	
	
	static public function getFileExtension(url:String) :String
	{
		var my_array:Array = url.split(".");
		var extension:String = my_array[my_array.length-1].toLowerCase();
		return extension;
	}
	
		
	static public function kBfromB (nuOfBytes:Number,roundTo:int=2):String 
	{
		return roundToDecimalPlace(nuOfBytes/1024,roundTo);
	}
		
	static public function MBfromB (nuOfBytes:Number,roundTo:int=2):String 
	{
		return roundToDecimalPlace(nuOfBytes/1048576,roundTo);
	}
	
	
	static public function bFromKB (nuOfKb:Number):Number 
	{
		return 1024*nuOfKb;
	}
	
	static public function bFromMB (nuOfMB:Number):Number 
	{
		return 1048576*nuOfMB;
	}
	
	static public function roundToDecimalPlace(nu:Number, nuOfPlaceToRoundTo:int):String
	{
		var formater:NumberFormatter = new NumberFormatter(LocaleID.DEFAULT);	
		//formater.= nuOfPlaceToRoundTo;
		return formater.formatNumber(nu);
	}
			
	
}
}
