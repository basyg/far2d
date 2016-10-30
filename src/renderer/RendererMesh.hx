package renderer;

import haxe.ds.Vector;
import openfl.utils.ByteArray;
import openfl.utils.Endian;

class RendererMesh {
	
	static public inline var INDICES_COUNT_IN_TRIANGLE:Int = 3;
	static public inline var FLOATS_COUNT_IN_VERTEX:Int = 2;
	
	public var name(default, null):String;
	public var trianglesN(default, null):Int;
	public var verticesN(default, null):Int;
	public var triangles(default, null):ByteArray;
	public var vertices(default, null):ByteArray;
	
	public var textureName(default, null):String;
	public var xInTexture(default, null):Float;
	public var yInTexture(default, null):Float;

	public function new(name:String, triangleIndices:Vector<UInt>, vertex2dPositions:Vector<Float>, textureName:String, xInTexture:Float, yInTexture:Float) {
		this.name = name;
		this.trianglesN = Math.floor(triangleIndices.length / INDICES_COUNT_IN_TRIANGLE);
		this.verticesN = Math.floor(vertex2dPositions.length / FLOATS_COUNT_IN_VERTEX);
		
		if (trianglesN * INDICES_COUNT_IN_TRIANGLE != triangleIndices.length) {
			throw 'Invalid indices count in mesh "$name"';
		}
		if (verticesN * FLOATS_COUNT_IN_VERTEX != vertex2dPositions.length) {
			throw 'Invalid vertices count in mesh "$name"';
		}
		
		this.triangles = new ByteArray();
		this.triangles.endian = Endian.LITTLE_ENDIAN;
		for (index in triangleIndices) {
			this.triangles.writeShort(index);
		}
		
		this.vertices = new ByteArray();
		this.vertices.endian = Endian.LITTLE_ENDIAN;
		for (float in vertex2dPositions) {
			this.vertices.writeFloat(float);
		}
		
		this.textureName = textureName;
		this.xInTexture = xInTexture;
		this.yInTexture = yInTexture;
	}
	
}