package renderer;

import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.TextureBase;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class RendererTexture {
	
	public var name(default, null):String;
	public var data(default, null):BitmapData;
	
	var _nativeTexture(default, null):Null<Texture> = null;
	
	public function new(name:String, data:BitmapData) {
		this.name = name;
		this.data = new BitmapData(data.width, data.height);
		copyBitmapDataFromTo(data, this.data);
	}
	
	public function disposeTexture():Void {
		if (_nativeTexture != null) {
			_nativeTexture.dispose();
			_nativeTexture = null;
		}
	}
	
	public function getOrCreateNativeTexture(context3d:Context3D):Null<TextureBase> {
		if (_nativeTexture == null) {
			_nativeTexture =  context3d.createTexture(data.width, data.height, Context3DTextureFormat.BGRA, false, 0);
			_nativeTexture.uploadFromBitmapData(data);
		}
		return _nativeTexture;
	}
	
	static var __copyBitmapDataFromTo_sourceRect:Rectangle = new Rectangle();
	static var __copyBitmapDataFromTo_destPoint:Point = new Point();
	static function copyBitmapDataFromTo(from:BitmapData, to:BitmapData):Void {
		__copyBitmapDataFromTo_sourceRect.setTo(0, 0, from.width, from.height);
		__copyBitmapDataFromTo_destPoint.setTo(0, 0);
		to.copyPixels(from, __copyBitmapDataFromTo_sourceRect, __copyBitmapDataFromTo_destPoint);
	}
	
}