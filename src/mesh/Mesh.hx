package mesh;

import flash.Vector;
import meshData.MeshData;
import meshData.MeshDataTriangle;
import meshData.MeshDataVector;

class Mesh {
	
	public var name(default, null):String;
	public var width(default, null):Float;
	public var height(default, null):Float;
	public var pivotX(default, null):Float;
	public var pivotY(default, null):Float;
	public var indices(default, null):Vector<UInt>;
	public var vertices(default, null):Vector<Float>;
	
	public var xInAtlas(default, null):Float;
	public var yInAtlas(default, null):Float;
	public var spriteX(default, null):Float;
	public var spriteY(default, null):Float;
	public var spriteWidth(default, null):Float;
	public var spriteHeight(default, null):Float;
	
	public var atlasTexCoords(default, null):Vector<Float>;

	public function new(meshData:MeshData, atlasWidth:Float, atlasHeight:Float) {
		name = meshData.filename;
		width = meshData.sourceSize.w;
		height = meshData.sourceSize.h;
		pivotX = width * meshData.pivot.x;
		pivotY = height * meshData.pivot.y;
		indices = getIndices(meshData.triangles);
		vertices = getVertices(meshData.vertices);
		
		xInAtlas = meshData.frame.x - meshData.spriteSourceSize.x;
		yInAtlas = meshData.frame.y - meshData.spriteSourceSize.y;
		spriteX = meshData.spriteSourceSize.x;
		spriteY = meshData.spriteSourceSize.y;
		spriteWidth = meshData.spriteSourceSize.w;
		spriteHeight = meshData.spriteSourceSize.h;
		
		atlasTexCoords = getTexCoords(meshData.verticesUV, atlasWidth, atlasHeight);
	}
	
	static function getIndices(triangleDatum:Array<MeshDataTriangle>):Vector<UInt> {
		var out = new Vector(triangleDatum.length * 3, true);
		for (i in 0...triangleDatum.length) {
			var triangleData = triangleDatum[i];
			var j = i * 3;
			
			out[j + 0] = triangleData.index0;
			out[j + 1] = triangleData.index1;
			out[j + 2] = triangleData.index2;
		}
		return out;
	}
	
	static function getVertices(verticesDatum:Array<MeshDataVector>):Vector<Float> {
		var out = new Vector(verticesDatum.length * 2, true);
		for (i in 0...verticesDatum.length) {
			var verticesData = verticesDatum[i];
			var j = i * 2;
			
			out[j + 0] = verticesData.x;
			out[j + 1] = verticesData.y;
		}
		return out;
	}
	
	static function getTexCoords(verticesUvDatum:Array<MeshDataVector>, atlasWidth:Float, atlasHeight:Float):Vector<Float> {
		var out = new Vector(verticesUvDatum.length * 2, true);
		for (i in 0...verticesUvDatum.length) {
			var verticesUvData = verticesUvDatum[i];
			var j = i * 2;
			
			out[j + 0] = verticesUvData.x / atlasWidth;
			out[j + 1] = verticesUvData.y / atlasHeight;
		}
		return out;
	}
	
}