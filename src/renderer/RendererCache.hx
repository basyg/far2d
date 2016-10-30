package renderer;

import haxe.ds.StringMap;
import haxe.ds.Vector;
import openfl.display.BitmapData;

class RendererCache {
	
	var _meshes:Map<String, RendererMesh> = new Map();
	var _textures:Map<String, RendererTexture> = new Map();
	
	public function new() {
		
	}
	
	public function disposeTextures() {
		for (texture in _textures) {
			texture.disposeTexture();
		}
	}
	
	public function addMesh(name:String, triangleIndices:Vector<UInt>, vertex2dPositions:Vector<Float>, textureName:String, xInTexture:Float, yInTexture:Float):Void {
		if (_meshes.exists(name)) {
			throw 'Mesh "$name" is exists';
		}
		
		_meshes.set(name, new RendererMesh(name, triangleIndices, vertex2dPositions, textureName, xInTexture, yInTexture));
	}
	
	public function addTexture(name:String, data:BitmapData):Void {
		if (_textures.exists(name)) {
			throw 'Texture "$name" is exists';
		}
		
		_textures.set(name, new RendererTexture(name, data));
	}
	
	public inline function getMesh(name:String):Null<RendererMesh> {
		return _meshes.get(name);
	}
	
	public inline function getTexture(name:String):Null<RendererTexture> {
		return _textures.get(name);
	}
	
}