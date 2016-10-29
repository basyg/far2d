package meshData;

abstract MeshDataTriangle(Array<Int>) {
	
	public var index0(get, never):UInt;
	public var index1(get, never):UInt;
	public var index2(get, never):UInt;
	
	inline function get_index0():UInt return this[0];
	inline function get_index1():UInt return this[1];
	inline function get_index2():UInt return this[2];

}