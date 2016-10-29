package meshData;

abstract MeshDataVector(Array<Int>) {
	
	public var x(get, never):Float;
	public var y(get, never):Float;
	
	inline function get_x():Float return this[0];
	inline function get_y():Float return this[1];
	
}