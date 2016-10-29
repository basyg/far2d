package renderer;

import flash.Vector;

class RendererMesh {
	
	public var meshName(default, null):String;
	
	public var trianglesN(default, null):Int;
	public var indices(default, null):Vector<UInt>;
	
	public var verticesN(default, null):Int;
	public var vertices(default, null):Vector<Float>;

	public function new(meshName:String, indices:Vector<UInt>, vertices:Vector<Float>) {
		var trianglesN = Math.floor(indices.length / 3);
		if (trianglesN * 3 != indices.length) {
			throw 'invalid indices count: "${indices.length}"';
		}
		
		var verticesN = Math.floor(vertices.length / 2);
		if (verticesN * 2 != vertices.length) {
			throw 'invalid vertices count: "${vertices.length}"';
		}
		
		this.meshName = meshName;
		this.trianglesN = trianglesN;
		this.indices = indices.concat();
		this.verticesN = verticesN;
		this.vertices = vertices.concat();
	}
	
}