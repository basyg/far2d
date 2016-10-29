package mesh;

import openfl.Assets;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import haxe.Json;
import meshData.MeshAtlasData;

class Meshes {
	
	public var atlas(default, null):MeshAtlas;
	public var atlasTextureData(default, null):BitmapData;

	public function new() {
		var atlasData:MeshAtlasData = Json.parse(Assets.getText('assets/meshs.json'));
		atlas = new MeshAtlas(atlasData);
		atlasTextureData = Assets.getBitmapData('assets/meshs.png');
	}
	
	public function update(dt:Float):Void {
		
	}
	
}