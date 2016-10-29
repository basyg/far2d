package mesh;

import meshData.MeshAtlasData;

class MeshAtlas {
	
	public var name(default, null):String;
	public var atlasWidth(default, null):Float;
	public var atlasHeight(default, null):Float;
	public var meshes(default, null):Map<String, Mesh>;

	public function new(atlasData:MeshAtlasData) {
		name = atlasData.meta.image;
		atlasWidth = atlasData.meta.size.w;
		atlasHeight = atlasData.meta.size.h;
		meshes = new Map();
		for (frame in atlasData.frames) {
			var mesh = new Mesh(frame, atlasWidth, atlasHeight);
			meshes[mesh.name] = mesh;
		}
	}
	
}