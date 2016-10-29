package mesh;

import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import haxe.Json;
import meshData.MeshAtlasData;

class Meshes {
	
	public var atlas(default, null):MeshAtlas;
	public var atlasTextureData(default, null):BitmapData;

	public function new() {
		//var atlasData:MeshAtlasData = Json.parse(new AtlasJson().toString());
		//atlas = new MeshAtlas(atlasData);
		//atlasTextureData = new AtlasPng(0, 0);
	}
	
	public function update(dt:Float):Void {
		
	}
	
}

//@:bitmap('../assets/meshs.png') 
//private class AtlasPng extends BitmapData { }
//
//@:file('../assets/meshs.json') 
//private class AtlasJson extends ByteArray { }