package renderer;

import haxe.ds.Vector;
import openfl.utils.ByteArray;
import openfl.utils.Endian;

class RendererMesh {
	
	static public inline var INDICES_COUNT_IN_TRIANGLE:Int = 3;
	static public inline var FOURBYTES_COUNT_IN_VERTEX:Int = 2;
	
	public var name(default, null):String;
	public var trianglesCount(default, null):Int;
	public var verticesCount(default, null):Int;
	public var triangles(default, null):ByteArray;
	public var vertices(default, null):ByteArray;
	
	public var textureName(default, null):String;
	public var xInTexture(default, null):Single;
	public var yInTexture(default, null):Single;

	public function new(name:String, triangleIndices:Vector<UInt>, vertex2dPositions:Vector<Float>, textureName:String, xInTexture:Float, yInTexture:Float) {
		this.name = name;
		trianglesCount = Math.floor(triangleIndices.length / INDICES_COUNT_IN_TRIANGLE);
		verticesCount = Math.floor(vertex2dPositions.length / FOURBYTES_COUNT_IN_VERTEX);
		
		if (trianglesCount * INDICES_COUNT_IN_TRIANGLE != triangleIndices.length) {
			throw 'Invalid indices count in mesh "$name"';
		}
		if (verticesCount * FOURBYTES_COUNT_IN_VERTEX != vertex2dPositions.length) {
			throw 'Invalid vertices count in mesh "$name"';
		}
		
		triangles = new ByteArray();
		triangles.endian = Endian.LITTLE_ENDIAN;
		for (index in triangleIndices) {
			triangles.writeShort(index);
		}
		
		vertices = new ByteArray();
		vertices.endian = Endian.LITTLE_ENDIAN;
		for (float in vertex2dPositions) {
			vertices.writeFloat(float);
		}
		
		this.textureName = textureName;
		this.xInTexture = xInTexture;
		this.yInTexture = yInTexture;
	}
	
}