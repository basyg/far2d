package renderer;

import flash.Vector;
import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DBufferUsage;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.IndexBuffer3D;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.TextureBase;
import flash.errors.Error;
import flash.geom.Matrix;
import renderer.RendererMesh;

class Renderer2 {
	
	static inline var TRIANGLE_INDICES_N:Int = 3;
	static inline var MESH_VERTEX_SIZE:Int = 2;
	static inline var BUFFER_VERTEX_SIZE:Int = 3;
	static inline var VERTEX_UNIFORMS_HEAD_SIZE:Int = 2;
	static inline var VERTEX_UNIFORMS_OBJECT_SIZE:Int = 3;
	static inline var MAX_MESH_WIDHT:Float = 4096;
	
	static var AGAL_VERSIONS:Map<String, UInt> = [
		(cast Context3DProfile.BASELINE_CONSTRAINED) => 1,
		(cast Context3DProfile.BASELINE) => 1,
		(cast Context3DProfile.BASELINE_EXTENDED) => 1,
		(cast Context3DProfile.STANDARD_CONSTRAINED) => 2,
		(cast Context3DProfile.STANDARD) => 2,
		(cast Context3DProfile.STANDARD_EXTENDED) => 3,
	];
	
	static var VERTEX_PROGRAM_CONSTANTS_N:Map<UInt, Int> = [
		1 => 128,
		2 => 250,
		3 => 250,
	];
	
	static var FRAGMENT_PROGRAM_CONSTANTS_N:Map<UInt, Int> = [
		1 => 28,
		2 => 64,
		3 => 200,
	];
	
	public var maxIndicesN(default, null):Int = 0xEFFFF;
	public var maxVerticesN(default, null):Int = 65535;
	
	public var agalVersion(default, null):UInt;
	public var maxMicrobatchSize(default, null):UInt;
	
	var _width:Int = -1;
	var _height:Int = -1;
	var _newWidth:Int;
	var _newHeight:Int;
	
	var _context3d:Context3D;
	var _vertexUniforms:RendererUniforms;
	var _fragmentUniforms:RendererUniforms;
	var _indexBuffer:IndexBuffer3D;
	var _vertexBuffer:VertexBuffer3D;
	var _program:Program3D;
	
	var _textureIds:Map<String, Int> = new Map();
	var _textureIdPool:IntIdPool = new IntIdPool();
	var _textures:Vector<Null<RendererTexture>> = new Vector();
	
	var _batchSize:Int = 0;
	var _batch:Vector<RendererObject> = new Vector();
	var _batchIndicesN:Int;
	var _batchIndices:Vector<UInt>;
	var _batchVerticesN:Int;
	var _batchVertices:Vector<Float>;
	
	var _currentState = new RendererState();

	public function new(context3d:Context3D, width:Int, height:Int) {
		setSize(width, height);
		
		_context3d = context3d;
		_context3d.enableErrorChecking = App.IS_DEBUG;
		_context3d.setCulling(Context3DTriangleFace.NONE);
		
		agalVersion = getAgalVersion(cast _context3d.profile);
		
		_vertexUniforms = new RendererUniforms(VERTEX_PROGRAM_CONSTANTS_N[agalVersion]);
		_fragmentUniforms = new RendererUniforms(FRAGMENT_PROGRAM_CONSTANTS_N[agalVersion]);
		
		maxMicrobatchSize = Math.floor((_vertexUniforms.getConstantsN() - VERTEX_UNIFORMS_HEAD_SIZE) / VERTEX_UNIFORMS_OBJECT_SIZE);
		
		_indexBuffer = _context3d.createIndexBuffer(maxIndicesN, Context3DBufferUsage.DYNAMIC_DRAW);
		_batchIndices = new Vector(maxIndicesN);
		_indexBuffer.uploadFromVector(_batchIndices, 0, maxIndicesN);
		_batchIndices.length = 0;
		
		_vertexBuffer = _context3d.createVertexBuffer(maxVerticesN, BUFFER_VERTEX_SIZE, Context3DBufferUsage.DYNAMIC_DRAW);
		_batchVertices = new Vector(maxVerticesN * 4);
		_vertexBuffer.uploadFromVector(_batchVertices, 0, maxVerticesN);
		_batchVertices.length = 0;
		
		var vertexProgram = new Agal([
			// var va0 = [posX, posY, i, 0]
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
			'mul oc, ft1, v0',
		]).assembleFragmentProgram(agalVersion);
		_program = _context3d.createProgram();
		_program.upload(vertexProgram, fragmentProgram);
		
	}
	
	public function handleContext3dRestore() {
		for (texture in _textures) {
			texture.disposeTexture();
		}
	}
	
	public function setSize(width:Int, height:Int):Void {
		_newWidth = width;
		_newHeight = height;
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
	
	public function begin():Void {
		if (_newWidth != _width || _newHeight != _height) {
			_context3d.configureBackBuffer(_newWidth, _newHeight, 0, false, false, false);
			_width = _newWidth;
			_height = _newHeight;
		}
		
		_context3d.clear(0.0, 0.0, 1.0, 1.0);
	}
	
	var __renderMesh_transform:Matrix = new Matrix();
	public function renderMesh(indices:Vector<UInt>, vertices:Vector<Float>, transform:Matrix, color:Int = 0xFFFFFF, alpha:Float = 1.0, textureName:String, xInTexture:Float, yInTexture:Float):Void {
		var trianglesN = Math.floor(indices.length / TRIANGLE_INDICES_N);
		if (trianglesN * TRIANGLE_INDICES_N != indices.length) {
			throw 'invalid indices count: "${indices.length}"';
		}
		
		var verticesN = Math.floor(vertices.length / MESH_VERTEX_SIZE);
		if (verticesN * MESH_VERTEX_SIZE != vertices.length) {
			throw 'invalid vertices count: "${vertices.length}"';
		}
		
		if (_textureIds.exists(textureName)) {
			if (_batchSize == _batch.length) {
				_batch.push(new RendererObject());
			}
			
			var textureId = _textureIds[textureName];
			var texture = _textures[textureId];
			var screenspaceTransform = __renderMesh_transform;
			screenspaceTransform.copyFrom(transform);
			screenspaceTransform.translate(-_width / 2, -_height / 2);
			screenspaceTransform.scale(1 / (_width / 2), -1 / (_height / 2));
			
			var object = _batch[_batchSize++];
			object.set(
				trianglesN,
				verticesN,
				color,
				alpha,
				texture,
				screenspaceTransform
			);
			
			var batchIndices = _batchIndices;
			var startNo = _batchIndicesN;
			for (i in 0...trianglesN) {
				var offset = i * TRIANGLE_INDICES_N;
				batchIndices[startNo + offset + 0] = indices[offset + 0];
				batchIndices[startNo + offset + 1] = indices[offset + 1];
				batchIndices[startNo + offset + 2] = indices[offset + 2];
			}
			_batchIndicesN += trianglesN * TRIANGLE_INDICES_N;
			
			var batchVertices = _batchVertices;
			var startNo = _batchVerticesN;
			for (i in 0...verticesN) {
				var offset0 = i * BUFFER_VERTEX_SIZE;
				var offset1 = i * MESH_VERTEX_SIZE;
				batchVertices[startNo + offset0 + 0] = vertices[offset1 + 0];
				batchVertices[startNo + offset0 + 1] = vertices[offset1 + 1];
				batchVertices[startNo + offset0 + 2] = 0.0;
			}
			_batchVerticesN += verticesN * BUFFER_VERTEX_SIZE;
		}
	}
	
	public function end():Void {
		flush();
		
		_context3d.present();
	}
	
	var __flush_transform:Matrix = new Matrix();
	var __flush_state:RendererState = new RendererState();
	function flush():Void {
		if (_batchSize == 0) {
			return;
		}
		
		var objectsN = _batchSize;
		var batchIndices = _batchIndices;
		var batchVertices = _batchVertices;
		
		var i = 0;
		var nextObject = _batch[0];
		while (nextObject != null) {
			var object = nextObject;
			nextObject = i + 1 < objectsN ? _batch[i + 1] : null;
			
			
			
			i++;
		}
		
		//trace(_batchIndices.length);
		_batchSize = 0;
		_batchIndicesN = 0;
		_batchVerticesN = 0;
		//_batchIndices.length = 0;
		//_batchVertices.length = 0;
	}
	
	//var __flush_transform:Matrix = new Matrix();
	//var __flush_state:RendererState = new RendererState();
	//function flush():Void {
		//if (_batchSize > 0) {
			//var i = 0;
			//var batchedVerticesN = 0;
			//for (microbatchSize in parseMicrobatchSizes()) {
				//var stateObject = _batch[i];
				//var microbatchTrianglesN = 0;
				//
				//for (j in 0...microbatchSize) {
					//var object = _batch[i++];
					//for (k in 0...object.verticesN) {
						//_vertexVector[(batchedVerticesN + k) * BUFFER_VERTEX_SIZE + 2] = j;
					//}
					//
					//batchedVerticesN += object.verticesN;
					//microbatchTrianglesN += object.trianglesN;
				//}
			//}
			//
			//_indexBuffer.uploadFromVector(_indexVector, 0, _batchTrianglesN * TRIANGLE_INDICES_N);
			//_vertexBuffer.uploadFromVector(_vertexVector, 0, _batchVerticesN);
			//
			//var i = 0;
			//var drawedTrianglesN = 0;
			//for (microbatchSize in parseMicrobatchSizes()) {
				//var stateObject = _batch[i];
				//var microbatchTrianglesN = 0;
				//
				//for (j in 0...microbatchSize) {
					//var object = _batch[i++];
					//
					//var r = (object.color >>> 16) & 0xFF;
					//var g = (object.color >>> 8) & 0xFF;
					//var b = object.color & 0xFF;
					//
					//var firstRegister = VERTEX_UNIFORMS_HEAD_SIZE + j * VERTEX_UNIFORMS_OBJECT_SIZE;
					//_vertexUniforms.setRGBA(firstRegister + 0, r / 255, g / 255, b / 255, object.alpha);
					//_vertexUniforms.setXYZW(firstRegister + 1, object.transformA, object.transformB, object.transformTx, object.xInTexture);
					//_vertexUniforms.setXYZW(firstRegister + 2, object.transformC, object.transformD, object.transformTy, object.yInTexture);
					//
					//microbatchTrianglesN += object.trianglesN;
				//}
				//
				//var stateTexture = stateObject.texture;
				//var state = __flush_state;
				//state.set(
					//_vertexBuffer,
					//_program,
					//stateTexture.getOrCreateTexture(_context3d),
					//Context3DBlendFactor.SOURCE_ALPHA,
					//Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
				//);
				//setState(state);
				//
				//_vertexUniforms.setXYZW(0, 0.0, 0.5, 1.0, 2.0);
				//_vertexUniforms.setXYZW(1, stateTexture.textureData.width, stateTexture.textureData.height, 0.0, 0.0);
				//
				//var numRegisters = VERTEX_UNIFORMS_HEAD_SIZE + microbatchSize * VERTEX_UNIFORMS_OBJECT_SIZE;
				//_context3d.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexUniforms, numRegisters);
				//
				//_context3d.drawTriangles(_indexBuffer, drawedTrianglesN * TRIANGLE_INDICES_N, microbatchTrianglesN);
				//
				//drawedTrianglesN += microbatchTrianglesN;
			//}
			//
			//_batchSize = 0;
			//_batchTrianglesN = 0;
			//_batchVerticesN = 0;
		//}
	//}
	
	var __parseMicrobatchSizes_vector:Vector<Int> = new Vector();
	function parseMicrobatchSizes():Vector<Int> {
		var sizes = __parseMicrobatchSizes_vector;
		sizes.length = 0;
		
		var maxSize = maxMicrobatchSize;
		
		var size:UInt = 0;
		var prevTexture:Null<RendererTexture> = null;
		for (i in 0..._batch.length) {
			var object = _batch[i];
			var texture = object.texture;
			
			if (size == maxSize || (texture != prevTexture && size > 0)) {
				sizes.push(size);
				size = 0;
			}
			
			size++;
			prevTexture = texture;
		}
		if (size > 0) {
			sizes.push(size);
		}
		
		return sizes;
	}
	
	function setState(state:RendererState):Void {
		var currentState = _currentState;
		
		if (currentState.vertexBuffer != state.vertexBuffer) {
			_context3d.setVertexBufferAt(0, state.vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_3);
		}
		
		if (currentState.program != state.program) {
			_context3d.setProgram(state.program);
		}
		
		if (currentState.texture != state.texture) {
			if (state.texture == null) {
				_context3d.setTextureAt(0, null);
			}
			else {
				_context3d.setTextureAt(0, state.texture);
			}
		}
		
		if (currentState.srcBlendFactor != state.srcBlendFactor || currentState.destBlendFactor != state.destBlendFactor) {
			_context3d.setBlendFactors(state.srcBlendFactor, state.destBlendFactor);
		}
		
		currentState.setFrom(state);
	}
	
	static function getAgalVersion(profile:Context3DProfile):UInt {
		if (!AGAL_VERSIONS.exists(cast profile)) {
			throw new Error('Unknown Context3DProfile: $profile');
		}
		return AGAL_VERSIONS[cast profile];
	}
	
}