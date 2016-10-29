package renderer;

import openfl.Memory;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DBufferUsage;
import openfl.display3D.Context3DProfile;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.errors.Error;
import openfl.geom.Matrix;
import openfl.system.ApplicationDomain;
import openfl.utils.ByteArray;
import openfl.utils.Endian;
import renderer.renderBatches;

@:allow(renderer)
class Renderer2 {
	
	public var width:Int;
	public var height:Int;
	public var objects:RendererObjects = new RendererObjects()
	
	var _context:Null<RendererContext> = null;
	
	var _vertexUniforms:VertexUniforms;
	var _triangles:TriangleBytes;
	var _vertices:VertexBytes;
	var _vertexIds:VertexIdBytes;
	
	var _triangleBuffer:Null<TriangleBuffer> = null;
	var _vertexBuffer:Null<VertexBuffer> = null;
	var _vertexIdBuffer:Null<VertexIdBuffer> = null;
	var _program:Null<Program3D> = null;
	
	var _commands:Vector<RendererCommand> = new Vector();
	var _commandsN:Int = 0;

	public function new(width:Int, height:Int) {
		this.width = width;
		this.height = height;
		
		_vertexUniforms = new RendererUniforms(VERTEX_PROGRAM_CONSTANTS_N[_agalVersion]);
		_triangles = new TriangleBytes();
		_vertices = new VertexBytes();
		_vertexIds = new VertexIdBytes();
	}
	
	public function initializeContext(context3d:Context3D):Void {
		_context = new RendererContext(context3d);
		
		_triangleBuffer = new TriangleBuffer(_context.context3d);
		_vertexBuffer = new VertexBuffer(_context.context3d);
		_vertexIdBuffer = new VertexIdBuffer(_context.context3d);
		_program = createProgram(_context.context3d, _context.agalVersion);
	}
	
	public function handleLostContext() {
		_context = null;
		
		_triangleBuffer = null;
		_vertexBuffer = null;
		_vertexIdBuffer = null;
		_program = null;
		
		objects.handleLostContext();
	}
	
	var __renderMesh_matrix:Matrix = new Matrix();
	public function renderMesh(meshName:String, transform:Matrix, color:Int = 0xFFFFFF, alpha:Float = 1.0):Void {
		if (_context == null) {
			return;
		}
		
		if (_commands.length == _commandsN) {
			_commands.length += 512;
			for (commandNo in _commandsN..._commands.length) {
				_commands[commandNo] = new RendererCommand();
			}
		}
		
		var command = _commands[_commandsN++];
		
		var screenspaceTransform = __renderMesh_matrix;
		screenspaceTransform.copyFrom(transform);
		screenspaceTransform.translate(-width / 2, -height / 2);
		screenspaceTransform.scale(1 / (width / 2), -1 / (height / 2));
		
		command.set(meshName, color, alpha, screenspaceTransform);
	}
	
	var __end_batches:Vector<RendererBatch> = new Vector();
	public function end():Void {
		if (_context != null) {
			_context.context3d.clear(0.0, 0.0, 1.0, 1.0);
			
			var batchesN = assembleBatches(__end_batches);
			renderBatches(__end_batches, batchesN);
			
			_context.context3d.present();
		}
	}
	
	function assembleBatches():Void {
		if (_commandsN == 0) {
			return;
		}
		
		var batcher = new BatchAssembler(
			_triangleBuffer.maxTrianglesN, _vertexBuffer.maxVerticesN, _context.maxVertexId
			__flush_batches
		);
		
		for (commandNo in 0..._commandsN) {
			var command = _commands[commandNo];
			
			var mesh = objects.getMesh(command.meshName);
			if (mesh == null) {
				continue;
			}
			
			var meshTexture = objects.getMeshTexture(mesh);
			if (meshTexture == null) {
				continue;
			}
			
			var texture = objects.getTexture(meshTexture.textureName);
			if (texture == null) {
				continue;
			}
			
			var nativeTexture = texture.getOrCreateNativeTexture();
			if (nativeTexture == null) {
				continue;
			}
			
			batcher.addMesh(
				mesh.indices, mesh.vertices,
				nativeTexture, texture.textureData.width, texture.textureData.height,
				meshTexture.xInTexture, meshTexture.yInTexture
			);
		}
		
	}
		
		
		var indexBufferOffset = 0;
		var indexBufferSize = 0;
		var vertexBufferOffset = 0;
		var vertexBufferSize = 0;
		var texture = _batch[0].texture;
		var microbatchObjectsOffset = 0;
		var microbatchObjectsN = 0;
		var microbatchTrianglesOffset = 0;
		var microbatchTrianglesN = 0;
		
		var indexBufferUploadingMicrobatchNo = 0;
		var vertexBufferUploadingMicrobatchNo = 0;
		
		for (object in _batch) {
			var objectIndices = object.indices;
			var objectVertices = object.vertices;
			
			var nextIndexBufferSize = indexBufferSize + object.trianglesN * TRIANGLE_INDICES_N;
			var nextVertexBufferSize = vertexBufferSize + object.verticesN;
			var nextTexture = object.texture;
			var nextMicrobatchObjectsN = microbatchObjectsN + 1;
			var nextMicrobatchTrianglesN = microbatchTrianglesN + object.trianglesN;
			
			var isIndexBufferOverflowed = nextIndexBufferSize > maxIndicesN;
			var isVertexBufferOverflowed = nextVertexBufferSize > maxVerticesN;
			var isStateChanged = texture != nextTexture;
			var isMicrobatchFull = nextMicrobatchObjectsN > _maxVertexId;
			
			if (isIndexBufferOverflowed && batchIndices.position + objectIndices.length > batchIndices.length) {
				batchIndices.length += maxIndicesN << 1;
			}
			if (isVertexBufferOverflowed && batchVertices.position + objectVertices.length > batchVertices.length) {
				batchVertices.length += maxVerticesN << 2;
			}
			
			var isNewMicrobatch = isIndexBufferOverflowed || isVertexBufferOverflowed || isStateChanged || isMicrobatchFull;
			if (isNewMicrobatch) {
				if (microbatchesN == microbatches.length) {
					microbatches.push(new RendererDrawcall());
				}
				var microbatch = microbatches[microbatchesN++];
				microbatch.set(
					0, 0,
					0, 0,
					texture,
					microbatchObjectsOffset, microbatchObjectsN,
					microbatchTrianglesOffset, microbatchTrianglesN
				);
				microbatchObjectsOffset += microbatchObjectsN;
				nextMicrobatchObjectsN -= microbatchObjectsN;
				microbatchTrianglesOffset += microbatchTrianglesN;
				nextMicrobatchTrianglesN -= microbatchTrianglesN;
				
				if (isIndexBufferOverflowed) {
					microbatches[indexBufferUploadingMicrobatchNo].uploadIndexBufferOffset = indexBufferOffset;
					microbatches[indexBufferUploadingMicrobatchNo].uploadIndexBuffer = indexBufferSize;
					indexBufferUploadingMicrobatchNo = microbatchesN;
					indexBufferOffset += indexBufferSize * 2;
					nextIndexBufferSize -= indexBufferSize;
				}
				
				if (isVertexBufferOverflowed) {
					microbatches[vertexBufferUploadingMicrobatchNo].uploadVertexBufferOffset = vertexBufferOffset;
					microbatches[vertexBufferUploadingMicrobatchNo].uploadVertexBuffer = vertexBufferSize;
					vertexBufferUploadingMicrobatchNo = microbatchesN;
					vertexBufferOffset += vertexBufferSize * BUFFER_VERTEX_SIZE * 4;
					nextVertexBufferSize -= vertexBufferSize;
				}
			}
			
			batchIndices.writeBytes(objectIndices, 0, objectIndices.length);
			batchVertices.writeBytes(objectVertices, 0, objectVertices.length);
			
			indexBufferSize = nextIndexBufferSize;
			vertexBufferSize = nextVertexBufferSize;
			texture = nextTexture;
			microbatchObjectsN = nextMicrobatchObjectsN;
			microbatchTrianglesN = nextMicrobatchTrianglesN;
		}
		
		if (microbatchesN == microbatches.length) {
			microbatches.push(new RendererDrawcall());
		}
		var microbatch = microbatches[microbatchesN++];
		microbatch.set(
			0, 0,
			0, 0,
			texture,
			microbatchObjectsOffset, microbatchObjectsN,
			microbatchTrianglesOffset, microbatchTrianglesN
		);
		microbatches[indexBufferUploadingMicrobatchNo].uploadIndexBufferOffset = indexBufferOffset;
		microbatches[indexBufferUploadingMicrobatchNo].uploadIndexBuffer = indexBufferSize;
		microbatches[vertexBufferUploadingMicrobatchNo].uploadVertexBufferOffset = vertexBufferOffset;
		microbatches[vertexBufferUploadingMicrobatchNo].uploadVertexBuffer = vertexBufferSize;
		
		_batchObjectsN = 0;
	}
	
	function renderBatches(batchIndices:ByteArray, batchVertices:ByteArray, microbatches:Vector<RendererBatch>, microbatchesN:Int):Void {
		var state = __flush_state;
		state.set(
			_vertexBuffer,
			_program,
			null,
			Context3DBlendFactor.SOURCE_ALPHA,
			Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
		);
		for (i in 0...microbatchesN) {
			var microbatch = microbatches[i];
			if (microbatch.uploadIndexBuffer > 0) {
				_indexBuffer.uploadFromByteArray(batchIndices, microbatch.uploadIndexBufferOffset, 0, microbatch.uploadIndexBuffer);
			}
			if (microbatch.uploadVertexBuffer > 0) {
				_vertexBuffer.uploadFromByteArray(batchVertices, microbatch.uploadVertexBufferOffset, 0, microbatch.uploadVertexBuffer);
			}
			
			state.texture = microbatch.nativeTexture.getOrCreateTexture(_context3d);
			setState(state);
			
			_vertexUniforms.setXYZW(0, 0.0, 0.5, 1.0, 2.0);
			_vertexUniforms.setXYZW(1, microbatch.nativeTexture.textureData.width, microbatch.nativeTexture.textureData.height, 0.0, 0.0);
			
			for (j in 0...microbatch.objectsN) {
				var object = _batch[microbatch.objectsOffset + j];
				
				var r = (object.color >>> 16) & 0xFF;
				var g = (object.color >>> 8) & 0xFF;
				var b = object.color & 0xFF;
				
				var firstRegister = VERTEX_UNIFORMS_HEAD_SIZE + j * VERTEX_UNIFORMS_OBJECT_SIZE;
				_vertexUniforms.setRGBA(firstRegister + 0, r / 255, g / 255, b / 255, object.alpha);
				_vertexUniforms.setXYZW(firstRegister + 1, object.transformA, object.transformB, object.transformTx, object.xInTexture);
				_vertexUniforms.setXYZW(firstRegister + 2, object.transformC, object.transformD, object.transformTy, object.yInTexture);
				//_vertexUniforms.setXYZW(firstRegister + 1, 1, 0, 0, object.xInTexture);
				//_vertexUniforms.setXYZW(firstRegister + 2, 0, 1, 0, object.yInTexture);
			}
			
			var numRegisters = VERTEX_UNIFORMS_HEAD_SIZE + microbatch.objectsN * VERTEX_UNIFORMS_OBJECT_SIZE;
			_context3d.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexUniforms, numRegisters);
			
			_context3d.drawTriangles(_indexBuffer, microbatch.trianglesOffset * TRIANGLE_INDICES_N, microbatch.trianglesN);
			//_context3d.drawTriangles(_indexBuffer, 0, _batch[0].trianglesN);
		}
	}
	
	static function createProgram(context3d:Context3D, agalVersion:Int):Program3D {
		var vertexProgram = new Agal([
			// var va0 = [posX, posY, i, 0]
			// // var va0 = [i, 0, 0, 0]
			// var vc0 = [0.0, 0.5, 1.0, 2.0]
			// var vc1 = [textureW, textureH, 0, 0]
			// var vc[i] = [r, g, b, a]
			// var vc[i+1] = [a, b, tx, xInTexture]
			// var vc[i+2] = [c, d, ty, yInTexture]
			
			// v0 = vc[i]
			'mov v0, vc[va0.z]',
			// vt1 = vc[i+1] = [a, b, tx, xInTexture]
			'add vt1, vc0.zxxx, va0.zwww',
			'mov vt1, vc[vt1.x]',
			// vt2 = vc[i+2] = [c, d, ty, yInTexture]
			'add vt2, vc0.wxxx, va0.zwww',
			'mov vt2, vc[vt2.x]',
			// vt3 = [0, 0, 1, 1]
			'mov vt3, vc0.xxzz',
			// vt0 = [xInTexture, yInTexture, 0, 0]
			'mov vt0, vc0.xxxx',
			'mov vt0.x, vt1.w',
			'mov vt0.y, vt2.w',
			// vt4 = [posX, posY, 1, 1]
			'mov vt4, vc0.xxzz',
			'mov vt4.xy, va0',
			// vt4 = applyTransform(vt4)
			'm33 vt4.xyz, vt4, vt1',
			// op = vt0
			'mov op, vt4',
			
			// vt4 = [posX, posY, 0, 0]
			'mov vt4, vc0.xxxx',
			'mov vt4.xy, va0',
			// vt4.xy = vt4 + [xInTexture, yInTexture, 0, 0]
			'add vt4.xy, vt4, vt0',
			// vt4.xy = vt4 / [textureW, textureH, 0, 0]
			'div vt4.xy, vt4, vc1',
			// v1 = vt4
			'mov v1, vt4',
		]).assembleVertexProgram(agalVersion);
		
		var fragmentProgram = new Agal([
			'tex ft1, v1, fs0 <2d, linear, nomip, clamp>',
			//'move oc, ft1',
			'mul oc, ft1, v0',
		]).assembleFragmentProgram(agalVersion);
		
		var program = context3d.createProgram();
		program.upload(vertexProgram, fragmentProgram);
		return program;
	}
	
}

private class BatchAssembler {
	
	public var batchesN(default, null):Int;
	
	var _maxBufferTrianglesN:Int;
	var _maxBufferVerticesN:Int;
	var _maxUniformsVertexId:Int;
	
	var _triangles:TriangleBytes;
	var _vertices:VertexBytes;
	var _vertexIds:VertexIdBytes;
	
	var _batches:Vector<RendererBatch>;
	var _batch:Null<RendererBatch>;
	
	public inline function new(
		maxBufferTrianglesN:Int, maxBufferVerticesN:Int, maxUniformsVertexId:Int,
		
		batches:Vector<RendererBatch>,
	) {
		batchesN = 0;
		
		_maxBufferTrianglesN = maxBufferTrianglesN;
		_maxBufferVerticesN = maxBufferVerticesN;
		_maxUniformsVertexId = maxUniformsVertexId;
		
		_batches = batches;
		_batch = null;
	}
	
	public inline function addMesh(
		meshTriangles:TriangleBytes, meshVertices:VertexBytes,
		nativeTexture:TextureBase, textureWidth:Int, textureHeight:Int,
	):Void {
		if (_batch == null) {
			_batch = getNextBatch();
		}
		
		var bufferTrianglesN = _batch.firstBufferTriangleNo + _batch.bufferTrianglesN;
		var bufferVertexN = _batch.firstBufferVertexNo + _batch.bufferVerticesN;
		
		var isTriangleBufferFull = bufferTrianglesN + meshTriangles.trianglesN > _maxBufferTrianglesN;
		var isVertexBufferFull = bufferVertexN + meshVertices.verticesN > _maxBufferVerticesN;
		var isUniformsFull = _batch.lastVertexId == _maxUniformsVertexId;
		var isStateChanging = _batch.lastVertexId == _maxUniformsVertexId;
		
		if (isTriangleBufferFull) {
			
		}
		
		if (isVertexBufferFull) {
			
		}
		
		if (isTriangleBufferFull || isVertexBufferFull || isUniformsFull || isStateChanging) {
			
		}
	}
	
	public inline function end():Void {
		
	}
	
	inline function getNextBatch():RendererBatch {
		if (_batches.length == batchesN) {
			_batches.length += 256;
			for (batchNo in batchesN..._batches.length) {
				_batches[batchNo] = new RendererBatch();
			}
		}
		
		return _batches[batchesN];
	}
	
}

private class RendererObjects {
	
	var _meshIdPool:IntIdPool = new IntIdPool();
	var _textureIdPool:IntIdPool = new IntIdPool();
	
	var _meshIds:Map<String, Int> = new Map();
	var _meshes:Vector<Null<RendererMesh2>> = new Vector();
	var _meshTextures:Vector<Null<RendererMeshTexture>> = new Vector();
	var _textureIds:Map<String, Int> = new Map();
	var _textures:Vector<Null<RendererTexture>> = new Vector();
	
	public function new() {
		
	}
	
	public function handleLostContext() {
		for (texture in _textures) {
			texture.disposeTexture();
		}
	}
	
	public function addMesh(meshName:String, indices:Vector<UInt>, vertices:Vector<Float>):Void {
		if (_meshIds.exists(meshName)) {
			removeMesh(meshName);
		}
		
		var meshId = _meshIdPool.aquireId();
		_meshIds[meshName] = meshId;
		_meshes[meshId] = new RendererMesh2(meshName, meshId, indices, vertices);
		
		if (meshId >= _meshes.length) {
			_meshes.length = meshId + 1;
			_meshTextures.length = meshId + 1;
		};
	}
	
	public function removeMesh(meshName:String):Void {
		if (_meshIds.exists(meshName)) {
			removeMeshTexture(meshName);
			
			var meshId = _meshIds[meshName];
			_meshIds.remove(meshName);
			_meshIdPool.releaseId(meshId);
			
			_meshes[meshId] = null;
		}
	}
	
	public function addMeshTexture(meshName:String, textureName:String, xInTexture:Float, yInTexture:Float):Void {
		if (!_meshIds.exists(meshName)) {
			throw new Error('Mesh "$meshName" does not exists');
		}
		
		var meshId = _meshIds[meshName];
		_meshTextures[meshId] = new RendererMeshTexture(meshName, textureName, xInTexture, yInTexture);
	}
	
	public function removeMeshTexture(meshName:String):Void {
		if (_meshIds.exists(meshName)) {
			var meshId = _meshIds[meshName];
			_meshTextures[meshId] = null;
		}
	}
	
	public function addTexture(textureName:String, texture:BitmapData):Void {
		if (_textureIds.exists(textureName)) {
			removeTexture(textureName);
		}
		
		var textureId = _textureIdPool.aquireId();
		_textureIds[textureName] = textureId;
		_textures[textureId] = new RendererTexture(textureName, texture);
	}
	
	public function removeTexture(textureName:String):Void {
		if (_textureIds.exists(textureName)) {
			var textureId = _textureIds[textureName];
			_textureIds.remove(textureName);
			_textureIdPool.releaseId(textureId);
			
			_textures[textureId].disposeTexture();
			_textures[textureId] = null;
		}
	}
	
	public function getMesh(meshName:String):Null<RendererMesh2> {
		return _meshIds.exists(meshName) ? _meshes[_meshIds[meshName]] : null;
	}
	
	public function getMeshTexture(mesh:RendererMesh2):RendererMeshTexture {
		return _meshTextures[mesh.id];
	}
	
	public function getTexture(textureName:String):RendererTexture {
		return _textureIds.exists(textureName) ? _textures[_textureIds[textureName]] : null;
	}
	
}

private class RendererCommand {
	
	public var meshName:Null<String> = null;
	public var color:Int = 0;
	public var alpha:Float = 0;
	
	public var a:Float = 0;
	public var b:Float = 0;
	public var c:Float = 0;
	public var d:Float = 0;
	public var tx:Float = 0;
	public var ty:Float = 0;

	public function new() {
		
	}
	
	public inline function set(meshName:String,	color:Int, alpha:Float, transform:Matrix):Void {
		this.meshName = meshName;
		this.color = color;
		this.alpha = alpha;
		
		a = transform.a;
		b = transform.b;
		c = transform.c;
		d = transform.d;
		tx = transform.tx;
		ty = transform.ty;
	}
	
}

private class RendererCommand2 {
	
	public var trianglesN:Int = 0;
	public var indices:Null<ByteArray> = null;
	public var verticesN:Int = 0;
	public var vertices:Null<ByteArray> = null;
	public var texture:Null<RendererTexture> = null;
	public var xInTexture:Float = 0;
	public var yInTexture:Float = 0;
	
	public var color:Int = 0;
	public var alpha:Float = 0;
	
	public var transformA:Float = 0;
	public var transformB:Float = 0;
	public var transformC:Float = 0;
	public var transformD:Float = 0;
	public var transformTx:Float = 0;
	public var transformTy:Float = 0;

	public function new() {
		
	}
	
	public inline function set(
		trianglesN:Int,
		indices:Null<ByteArray>,
		verticesN:Int,
		vertices:Null<ByteArray>,
		color:Int,
		alpha:Float,
		texture:RendererTexture,
		xInTexture:Float,
		yInTexture:Float,
		transform:Matrix
	):Void {
		this.trianglesN = trianglesN;
		this.indices = indices;
		this.verticesN = verticesN;
		this.vertices = vertices;
		this.color = color;
		this.alpha = alpha;
		this.texture = texture;
		this.xInTexture = xInTexture;
		this.yInTexture = yInTexture;
		
		transformA = transform.a;
		transformB = transform.b;
		transformC = transform.c;
		transformD = transform.d;
		transformTx = transform.tx;
		transformTy = transform.ty;
	}
	
	public inline function set2(
		mesh:RendererMesh2,
		meshTexture:RendererMeshTexture,
		texture:RendererTexture,
		color:Int,
		alpha:Float,
		transform:Matrix
	):Void {
		this.trianglesN = mesh.trianglesN;
		this.indices = mesh.indices;
		this.verticesN = mesh.verticesN;
		this.vertices = mesh.vertices;
		this.color = color;
		this.alpha = alpha;
		this.texture = texture;
		this.xInTexture = meshTexture.xInTexture;
		this.yInTexture = meshTexture.yInTexture;
		
		transformA = transform.a;
		transformB = transform.b;
		transformC = transform.c;
		transformD = transform.d;
		transformTx = transform.tx;
		transformTy = transform.ty;
	}
	
}

private class RendererMesh2 {
	
	public var name(default, null):String;
	public var id(default, null):Int;
	
	public var trianglesN(default, null):Int;
	public var indices(default, null):ByteArray;
	
	public var verticesN(default, null):Int;
	public var vertices(default, null):ByteArray;

	public function new(name:String, id:Int, indices:Vector<UInt>, vertices:Vector<Float>) {
		var trianglesN = Math.floor(indices.length / TriangleBuffer.TRIANGLE_INDICES_N);
		var verticesN = Math.floor(vertices.length / VertexBuffer.VERTEX_FLOATS_N);
		
		if (trianglesN * TriangleBuffer.TRIANGLE_INDICES_N != indices.length) {
			throw new Error('Invalid indices count: "${indices.length}"');
		}
		if (verticesN * VertexBuffer.VERTEX_FLOATS_N != vertices.length) {
			throw new Error('Invalid vertex floats count: "${vertices.length}"');
		}
		
		this.name = name;
		this.id = id;
		this.trianglesN = trianglesN;
		this.verticesN = verticesN;
		
		this.indices = new ByteArray();
		this.indices.endian = Endian.LITTLE_ENDIAN;
		for (index in indices) {
			this.indices.writeShort(index);
		}
		
		this.vertices = new ByteArray();
		this.vertices.endian = Endian.LITTLE_ENDIAN;
		for (float in vertices) {
			this.vertices.writeFloat(float);
		}
	}
	
}

private abstract VertexUniforms(Vector<Float>) to Vector<Float> {
	
	static public inline var HEADER_UNIFORMS_N:Int = 2;
	static public inline var OBJECT_UNIFORMS_N:Int = 3;
	static public inline var UNIFORM_FLOATS_N:Int = 4;
	
	public var uniformsN(get, never):Int; inline function get_uniformsN():Int return Math.floor(this.length / UNIFORM_FLOATS_N);
	public var maxVertexId(get, never):Int; inline function get_objectsN():Int return getMaxVertexId(uniformsN);

	public inline function new(uniformsN:Int) {
		this = new Vector(uniformsN * UNIFORM_FLOATS_N, true);
	}
	
	public inline function clear():Void {
		var length = this.length;
		this.fixed = false;
		this.length = 0;
		this.length = length;
		this.fixed = true;
	}
	
	public inline function setHeader(drawcall:RendererBatch):Void {
		var textureWidth = drawcall.nativeTexture.textureData.width;
		var textureHeight = drawcall.nativeTexture.textureData.height;
		
		setUniform(0, 0.0, 0.5, 1.0, 2.0);
		setUniform(1, textureWidth, textureHeight, 0.0, 0.0);
	}
	
	public inline function setObject(vertexId:Int, command:RendererCommand):Void {
		var r = (command.color >>> 16) & 0xFF;
		var g = (command.color >>> 8) & 0xFF;
		var b = command.color & 0xFF;
		
		var i = HEADER_UNIFORMS_N + vertexId * OBJECT_UNIFORMS_N;
		setUniform(i + 0, r / 255, g / 255, b / 255, command.alpha);
		setUniform(i + 1, command.transformA, command.transformB, command.transformTx, command.xInTexture);
		setUniform(i + 2, command.transformC, command.transformD, command.transformTy, command.yInTexture);
	}
	
	public inline function setUniform(no:Int, x:Float, y:Float, z:Float, w:Float):Void {
		var i = no  * UNIFORM_FLOATS_N;
		this[i + 0] = x;
		this[i + 1] = y;
		this[i + 2] = z;
		this[i + 3] = w;
	}
	
	static public inline function getMaxVertexId(uniformsN:Int):Int {
		return Math.floor((uniformsN - HEADER_UNIFORMS_N) / OBJECT_UNIFORMS_N);
	}
	
}
	
private abstract TriangleBuffer(IndexBuffer3D) to IndexBuffer3D {
	
	static public inline var MAX_TRIANGLES_N:Int = 0x4FFFF;
	static public inline var TRIANGLE_INDICES_N:Int = 3;
	static public inline var TRIANGLE_BYTES_N:Int = TRIANGLE_INDICES_N * INDEX_BYTES_N;
	static public inline var INDEX_BYTES_N:Int = 2;
	
	public var maxTrianglesN(get, never):Int; inline function get_maxTrianglesN():Int return MAX_TRIANGLES_N;
	
	public inline function new(context3d:Context3D) {
		this = context3d.createIndexBuffer(MAX_TRIANGLES_N * TRIANGLE_INDICES_N, Context3DBufferUsage.DYNAMIC_DRAW);
	}
	
	public inline function upload(triangles:TriangleBytes, offset:Int, n:Int):Void {
		this.uploadFromByteArray(triangles, offset * TRIANGLE_BYTES_N, 0, n * TRIANGLE_INDICES_N);
	}
	
}

private abstract TriangleBytes(ByteArray) to ByteArray {
	
	static var _domain:Null<ApplicationDomain> = null;

	public var trianglesN(get, never):Int; inline function get_trianglesN():Int return Math.floor(this.length / TriangleBuffer.TRIANGLE_BYTES_N);
	
	public inline function new() {
		if (_domain == null) {
			_domain = ApplicationDomain.currentDomain;
		}
		
		this = new ByteArray();
		this.endian = Endian.LITTLE_ENDIAN;
		grow();
	}
	
	public inline function setRangeFrom(rangeBegin:Int, fromTriangles:TriangleBytes, valueOffset:Int):Void {
		var byteRangeBegin = rangeBegin * TriangleBuffer.TRIANGLE_BYTES_N;
		var bytesN = fromTriangles.trianglesN * TriangleBuffer.TRIANGLE_BYTES_N;
		
		while (trianglesN < rangeBegin + fromTriangles.trianglesN) {
			grow();
		}
		
		this.position = byteRangeBegin;
		this.writeBytes(fromTriangles, 0, bytesN);
		
		if (_domain.domainMemory != this) {
			_domain.domainMemory = this;
		}
		
		var i = byteRangeBegin;
		var end = byteRangeBegin + bytesN;
		while (i < end) {
			var i0 = i + TriangleBuffer.INDEX_BYTES_N * 0;
			var i1 = i + TriangleBuffer.INDEX_BYTES_N * 1;
			var i2 = i + TriangleBuffer.INDEX_BYTES_N * 2;
			Memory.setI16(i0, Memory.getUI16(i0) + valueOffset);
			Memory.setI16(i1, Memory.getUI16(i1) + valueOffset);
			Memory.setI16(i2, Memory.getUI16(i2) + valueOffset);
			i += TriangleBuffer.TRIANGLE_BYTES_N;
		}
	}
	
	inline function grow():Void {
		this.length += TriangleBuffer.MAX_TRIANGLES_N * TriangleBuffer.TRIANGLE_BYTES_N;
	}
	
}
	
private abstract VertexBuffer(VertexBuffer3D) to VertexBuffer3D {
	
	static public inline var MAX_VERTICES_N:Int = 0xFFFF;
	static public inline var VERTEX_FLOATS_N:Int = 2;
	static public inline var VERTEX_BYTES_N:Int = VERTEX_FLOATS_N * FLOAT_BYTES_N;
	static public inline var FLOAT_BYTES_N:Int = 4;
	
	public var maxVerticesN(get, never):Int; inline function get_maxVerticesN():Int return MAX_VERTICES_N;
	public var bufferFormat(get, never):Context3DVertexBufferFormat; inline function get_bufferFormat():Context3DVertexBufferFormat return Context3DVertexBufferFormat.);;
	
	public inline function new(context3d:Context3D) {
		this = context3d.createVertexBuffer(MAX_VERTICES_N, VERTEX_FLOATS_N, Context3DBufferUsage.DYNAMIC_DRAW);
	}
	
	public inline function upload(vertices:VertexBytes, from:Int, n:Int):Void {
		this.uploadFromByteArray(vertices, from * VERTEX_BYTES_N, 0, n);
	}
	
}

private abstract VertexBytes(ByteArray) to ByteArray {

	public var verticesN(get, never):Int; inline function get_verticesN():Int return Math.floor(this.length / VertexBuffer.VERTEX_BYTES_N);
	
	public inline function new() {
		this = new ByteArray();
		this.endian = Endian.LITTLE_ENDIAN;
		grow();
	}
	
	public inline function setRangeFrom(rangeBegin:Int, fromVertices:VertexBytes):Void {
		var byteRangeBegin = rangeBegin * VertexBuffer.VERTEX_BYTES_N;
		var bytesN = fromVertices.verticesN * VertexBuffer.VERTEX_BYTES_N;
		
		while (verticesN < rangeBegin + fromVertices.verticesN) {
			grow();
		}
		
		this.position = byteRangeBegin;
		this.writeBytes(fromVertices, 0, bytesN);
	}
	
	inline function grow():Void {
		this.length += VertexBuffer.MAX_VERTICES_N * VertexBuffer.VERTEX_BYTES_N;
	}
	
}
	
private abstract VertexIdBuffer(VertexBuffer3D) from VertexBuffer3D {
	
	static public inline var VERTEX_ID_FLOATS_N:Int = 1;
	static public inline var VERTEX_ID_BYTES_N:Int = VERTEX_ID_FLOATS_N * VertexBuffer.FLOAT_BYTES_N;
	
	public var maxVertexIdsN(get, never):Int; inline function get_maxVertexIdsN():Int return VertexBuffer.MAX_VERTICES_N;
	public var bufferFormat(get, never):Context3DVertexBufferFormat; inline function get_bufferFormat():Context3DVertexBufferFormat return Context3DVertexBufferFormat.FLOAT_1;
	
	public inline function new(context3d:Context3D) {
		this = context3d.createVertexBuffer(VertexBuffer.MAX_VERTICES_N, VERTEX_ID_FLOATS_N, Context3DBufferUsage.DYNAMIC_DRAW);
	}
	
	public inline function upload(vertexIds:VertexIdBytes, from:Int, n:Int):Void {
		this.uploadFromByteArray(vertexIds, from * VERTEX_ID_BYTES_N, 0, n);
	}
	
}

private abstract VertexIdBytes(ByteArray) to ByteArray {

	public var vertexIdsN(get, never):Int; inline function get_vertexIdsN():Int return Math.floor(this.length / VertexIdBuffer.VERTEX_ID_BYTES_N);
	
	public inline function new() {
		this = new ByteArray();
		this.endian = Endian.LITTLE_ENDIAN;
		grow();
	}
	
	public inline function setRange(begin:Int, n:Int, vertexId:Int):Void {
		var prefab = getVertexIdPrefab(vertexId, n);
		var byteRangeBegin = begin * VertexIdBuffer.VERTEX_ID_BYTES_N;
		var bytesN = n * VertexIdBuffer.VERTEX_ID_BYTES_N;
		
		this.position = byteRangeBegin;
		this.writeBytes(prefab, 0, bytesN);
	}
	
	inline function grow():Void {
		this.length += VertexBuffer.MAX_VERTICES_N * VertexBuffer.VERTEX_BYTES_N;
	}
	
	static var __getVertexIdPrefab_vertexIdPrefabs:Vector<Null<ByteArray>> = new Vector();
	static inline function getVertexIdPrefab(vertexId:Int, n:Int):ByteArray {
		var vertexIdPrefabs = __getVertexIdPrefab_vertexIdPrefabs;
		
		if (vertexIdPrefabs.length <= vertexId) {
			vertexIdPrefabs.length = vertexId + 1;
		}
		
		var prefab = vertexIdPrefabs[vertexId];
		if (prefab == null) {
			prefab = new ByteArray();
			vertexIdPrefabs[vertexId] = prefab;
		}
		
		var bytesN = n * VertexIdBuffer.VERTEX_ID_BYTES_N;
		if (prefab.length <= bytesN) {
			var i = prefab.length;
			var end = bytesN;
			while (i < end) {
				prefab.writeFloat(vertexId);
				i += VertexIdBuffer.VERTEX_ID_BYTES_N;
			}
		}
		
		return prefab;
	}
	
}

class RendererContext {
	
	static var AGAL_VERSIONS:Map<Context3DProfile, Int> = [
		Context3DProfile.BASELINE_CONSTRAINED => 1,
		Context3DProfile.BASELINE => 1,
		Context3DProfile.BASELINE_EXTENDED => 1,
		Context3DProfile.STANDARD_CONSTRAINED => 2,
		Context3DProfile.STANDARD => 2,
		Context3DProfile.STANDARD_EXTENDED => 3,
	];
	
	static var VERTEX_PROGRAM_CONSTANTS_N:Map<Int, Int> = [
		1 => 128,
		2 => 250,
		3 => 250,
	];
	
	static var FRAGMENT_PROGRAM_CONSTANTS_N:Map<Int, Int> = [
		1 => 28,
		2 => 64,
		3 => 200,
	];
	
	public var context3d(default, null):Context3D;
	public var agalVersion(default, null):Int;
	public var maxVertexUniformsN(default, null):Int;
	public var maxFragmentUniformsN(default, null):Int;
	public var maxUniformsVertexId(default, null):Int;
	
	var _backBufferWidth:Int = -1;
	var _backBufferHeight:Int = -1;
	var _vertexBuffer:Null<VertexBuffer> = null;
	var _vertexIdBuffer:Null<VertexIdBuffer> = null;
	var _program:Null<Program3D> = null;
	var _texture:Null<TextureBase> = null;
	var _srcBlendFactor:Null<Context3DBlendFactor> = null;
	var _destBlendFactor:Null<Context3DBlendFactor> = null;

	public function new(context3d:Context3D) {
		if (!AGAL_VERSIONS.exists(cast context3d.profile)) {
			throw new Error('Unknown Context3DProfile: ${context3d.profile}');
		}
		
		context3d = context3d;
		context3d.enableErrorChecking = App.IS_DEBUG;
		context3d.setCulling(Context3DTriangleFace.NONE);
		
		agalVersion = AGAL_VERSIONS[cast context3d.profile];
		maxVertexUniformsN = VERTEX_PROGRAM_CONSTANTS_N[agalVersion];
		maxFragmentUniformsN = FRAGMENT_PROGRAM_CONSTANTS_N[agalVersion];
		maxUniformsVertexId = VertexUniforms.getMaxVertexId(maxVertexUniformsN);
	}
	
	public function setState(
		backBufferWidth:Int,
		backBufferHeight:Int, 
		vertexBuffer:VertexBuffer,
		vertexIdBuffer:VertexBuffer,
		program:Program3D,
		texture:TextureBase,
		srcBlendFactor:Context3DBlendFactor,
		destBlendFactor:Context3DBlendFactor
	):Void {
		if (_backBufferWidth != backBufferWidth || _backBufferHeight != backBufferHeight) {
			context3d.configureBackBuffer(backBufferWidth, backBufferHeight, 0, false, false, false);
			_backBufferWidth = backBufferWidth;
			_backBufferHeight = backBufferHeight;
		}
		
		if (_vertexBuffer != vertexBuffer) {
			context3d.setVertexBufferAt(0, vertexBuffer, 0, vertexBuffer.bufferFormat);
			_vertexBuffer = vertexBuffer;
		}
		
		if (_vertexIdBuffer != vertexIdBuffer) {
			context3d.setVertexBufferAt(1, vertexIdBuffer, 0, vertexIdBuffer.bufferFormat);
			_vertexIdBuffer = vertexIdBuffer;
		}
		
		if (_program != program) {
			context3d.setProgram(program);
			_program = program;
		}
		
		if (_texture != texture) {
			context3d.setTextureAt(0, texture);
			_texture = texture;
		}
		
		if (_srcBlendFactor != srcBlendFactor || _destBlendFactor != destBlendFactor) {
			context3d.setBlendFactors(srcBlendFactor, destBlendFactor);
			_srcBlendFactor = srcBlendFactor;
			_destBlendFactor = destBlendFactor;
		}
	}
	
}