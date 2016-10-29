package renderer;

class RendererBatch {
	
	public var uploadIndexBufferOffset:Int = 0;
	public var uploadIndexBuffer:Int = 0;
	
	public var uploadVertexBufferOffset:Int = 0;
	public var uploadVertexBuffer:Int = 0;
	
	public var nativeTexture:Null<RendererTexture> = null;
	
	public var objectsOffset:Int = 0;
	public var objectsN:Int = 0;
	
	public var trianglesOffset:Int = 0;
	public var trianglesN:Int = 0;

	public function new() {
		
	}
	
	public inline function set(
		uploadIndexBufferOffset:Int, uploadIndexBuffer:Int,
		uploadVertexBufferOffset:Int, uploadVertexBuffer:Int,
		nativeTexture:Null<RendererTexture>,
		objectsOffset:Int, objectsN:Int,
		trianglesOffset:Int, trianglesN:Int
	):Void {
		this.uploadIndexBufferOffset = uploadIndexBufferOffset;
		this.uploadIndexBuffer = uploadIndexBuffer;
		this.uploadVertexBufferOffset = uploadVertexBufferOffset;
		this.uploadVertexBuffer = uploadVertexBuffer;
		this.nativeTexture = nativeTexture;
		this.objectsOffset = objectsOffset;
		this.objectsN = objectsN;
		this.trianglesOffset = trianglesOffset;
		this.trianglesN = trianglesN;
	}
	
}