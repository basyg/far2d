package renderer;

import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DTextureFormat;
import flash.display3D.textures.Texture;
import flash.display3D.textures.TextureBase;
import flash.geom.Point;
import flash.geom.Rectangle;

class RendererTexture {
	
	public var textureName(default, null):String;
	public var textureData(default, null):BitmapData;
	
	var _texture(default, null):Null<Texture> = null;
	
	public function new(textureName:String, textureData:BitmapData) {
		this.textureName = textureName;
		this.textureData = new BitmapData(textureData.width, textureData.height);
		copyBitmapDataFromTo(textureData, this.textureData);
	}
	
	public function disposeTexture():Void {
		if (_texture != null) {
			_texture.dispose();
			_texture = null;
		}
	}
	
	public function getOrCreateNativeTexture(context3d:Context3D):Null<TextureBase> {
		if (_texture == null) {
			_texture =  context3d.createTexture(textureData.width, textureData.height, Context3DTextureFormat.BGRA, false);
			_texture.uploadFromBitmapData(textureData);
		}
		return _texture;
	}
	
	public function setTextureData(textureData:BitmapData):Void {
		if (
			this.textureData.width != textureData.width ||
			this.textureData.height != textureData.height
		) {
			disposeTextureData();
			disposeTexture();
			
			this.textureData = new BitmapData(textureData.width, textureData.height);
		}
		
		copyBitmapDataFromTo(textureData, this.textureData);
		if (_texture != null) {
			_texture.uploadFromBitmapData(this.textureData);
		}
	}
	
	function disposeTextureData():Void {
		//if (textureData != null) {
			textureData.dispose();
			textureData = null;
		//}
	}
	
	static function copyBitmapDataFromTo(from:BitmapData, to:BitmapData):Void {
		__copyBitmapDataFromTo_sourceRect.setTo(0, 0, from.width, from.height);
		__copyBitmapDataFromTo_destPoint.setTo(0, 0);
		to.copyPixels(from, __copyBitmapDataFromTo_sourceRect, __copyBitmapDataFromTo_destPoint);
	}
	static var __copyBitmapDataFromTo_sourceRect:Rectangle = new Rectangle();
	static var __copyBitmapDataFromTo_destPoint:Point = new Point();
	
}