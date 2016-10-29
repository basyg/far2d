package meshData;

typedef MeshData = {
	
	filename: String,
	frame: MeshDataRectangle,
	rotated: Bool,
	trimmed: Bool,
	spriteSourceSize: MeshDataRectangle,
	sourceSize: MeshDataSize,
	pivot: MeshDataPoint,
	vertices: Array<MeshDataVector>,
	verticesUV: Array<MeshDataVector>,
	triangles: Array<MeshDataTriangle>,
	
}