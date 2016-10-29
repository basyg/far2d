package renderer;

import openfl.Vector;

class RendererMeshTexture {
	
	public var meshName(default, null):String;
	public var textureName(default, null):String;
	public var xInTexture(default, null):Float;
	public var yInTexture(default, null):Float;

	public function new(meshName:String, textureName:String, xInTexture:Float, yInTexture:Float) {
		this.meshName = meshName;
		this.textureName = textureName;
		this.xInTexture = xInTexture;
		this.yInTexture = yInTexture;
	}
	
}