package renderer_;

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

class Renderer {
	
	static var VERTEX_SIZE:Int = 2;
	
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
	
	public var maxIndexesN(default, null):Int = 196608;
	public var maxVerticesN(default, null):Int = 65535;
	
	public var agalVersion(default, null):UInt;
	
	var _width:Int = -1;
	var _height:Int = -1;
	var _newWidth:Int;
	var _newHeight:Int;
	
	var _context3d:Context3D;
	var _indexBuffer:IndexBuffer3D;
	var _indexVector:Vector<UInt>;
	var _vertexBuffer:VertexBuffer3D;
	var _vertexVector:Vector<Float>;
	var _program:Program3D;
	var _vertexUniforms:RendererUniforms;
	var _fragmentUniforms:RendererUniforms;
	
	var _currentVertexBuffer:Null<VertexBuffer3D> = null;
	var _currentProgram:Null<Program3D> = null;
	var _currentTexture:Null<TextureBase> = null;
	var _currentSrcBlendFactor:Null<Context3DBlendFactor> = null;
	var _currentDestBlendFactor:Null<Context3DBlendFactor> = null;
	
	var _meshIds:Map<String, Int> = new Map();
	var _meshIdPool:IntIdPool = new IntIdPool();
	var _meshes:Vector<Null<RendererMesh>> = new Vector();
	var _meshTextures:Vector<Null<RendererMeshTexture>> = new Vector();
	var _meshIndexBufferOffsets:Vector<Int> = new Vector();
	var _bufferTrianglesN:Int = 0;
	var _bufferVerticesN:Int = 0;
	
	var _textureIds:Map<String, Int> = new Map();
	var _textureIdPool:IntIdPool = new IntIdPool();
	var _textures:Vector<Null<RendererTexture>> = new Vector();
	
	var _buffersIsInvalid:Bool = true;

	public function new(context3d:Context3D, width:Int, height:Int) {
		setSize(width, height);
		
		_context3d = context3d;
		_context3d.enableErrorChecking = App.IS_DEBUG;
		_context3d.setCulling(Context3DTriangleFace.NONE);
		
		agalVersion = getAgalVersion(cast _context3d.profile);
		
		_indexBuffer = _context3d.createIndexBuffer(maxIndexesN, Context3DBufferUsage.STATIC_DRAW);
		_indexVector = new Vector(maxIndexesN, true);
		_indexBuffer.uploadFromVector(_indexVector, 0, maxIndexesN);
		
		_vertexBuffer = _context3d.createVertexBuffer(maxVerticesN, VERTEX_SIZE, Context3DBufferUsage.STATIC_DRAW);
		_vertexVector = new Vector(maxVerticesN * 4, true);
		_vertexBuffer.uploadFromVector(_vertexVector, 0, maxVerticesN);
		
		var vertexProgram = new Agal([
			// var va0 = [posX, posY, 0, 0]
			// var vc0 = [0.0, 0.5, 1.0, 2.0]
			// var vc1 = [r, g, b, a]
			// var vc2 = [a, b, tx, 0]
			// var vc3 = [c, d, ty, 0]
			// var vc4 = [0, 0, 1, 0]
			// var vc5 = [xInTexture, yInTexture, textureW, textureH]
			'mov v0, vc1',
			
			'mov vt0, vc0.xxzz',
			'mov vt0.xy, va0',
			'm33 vt0.xyz, vt0, vc2',
			'mov op, vt0',
			
			'mov vt1, va0.xy',
			'add vt1.xy, vt1, vc5.xy',
			'div vt1.xy, vt1, vc5.zw',
			'mov v1, vt1',
		]).assembleVertexProgram(agalVersion);
		var fragmentProgram = new Agal([
			'tex ft1, v1, fs0 <2d, linear, nomip, clamp>',
			'mul oc, ft1, v0',
		]).assembleFragmentProgram(agalVersion);
		_program = _context3d.createProgram();
		_program.upload(vertexProgram, fragmentProgram);
		
		_vertexUniforms = new RendererUniforms(VERTEX_PROGRAM_CONSTANTS_N[agalVersion]);
		_fragmentUniforms = new RendererUniforms(FRAGMENT_PROGRAM_CONSTANTS_N[agalVersion]);
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
	
	public function addMesh(meshName:String, indices:Vector<UInt>, vertices:Vector<Float>):Void {
		if (_meshIds.exists(meshName)) {
			removeMesh(meshName);
		}
		
		var meshId = _meshIdPool.aquireId();
		_meshIds[meshName] = meshId;
		_meshes[meshId] = new RendererMesh(meshName, indices, vertices);
		
		if (meshId >= _meshes.length) {
			_meshes.length = meshId + 1;
			_meshTextures.length = meshId + 1;
			_meshIndexBufferOffsets.length = meshId + 1;
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
		
		_buffersIsInvalid = true;
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
	
	public function begin():Void {
		if (_newWidth != _width || _newHeight != _height) {
			_context3d.configureBackBuffer(_newWidth, _newHeight, 0, false, false, false);
			_width = _newWidth;
			_height = _newHeight;
		}
		
		_context3d.clear(0.0, 0.0, 1.0, 1.0);
		
		if (_buffersIsInvalid) {
			compileBuffers();
			_indexBuffer.uploadFromVector(_indexVector, 0, _bufferTrianglesN * 3);
			_vertexBuffer.uploadFromVector(_vertexVector, 0, _bufferVerticesN);
			
			_buffersIsInvalid = false;
		}
	}
	
	var __renderMesh_transform:Matrix = new Matrix();
	public function renderMesh(meshName:String, transform:Matrix, color:Int = 0xFFFFFF, alpha:Float = 1.0):Void {
		if (_meshIds.exists(meshName)) {
			var meshId = _meshIds[meshName];
			var mesh = _meshes[meshId];
			var meshTexture = _meshTextures[meshId];
			
			if (meshTexture != null && _textureIds.exists(meshTexture.textureName)) {
				var textureId = _textureIds[meshTexture.textureName];
				var texture = _textures[textureId];
				
				setState(
					_vertexBuffer,
					_program,
					texture.getOrCreateTexture(_context3d),
					Context3DBlendFactor.SOURCE_ALPHA,
					Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA
				);
				
				var r = (color >>> 16) & 0xFF;
				var g = (color >>> 8) & 0xFF;
				var b = color & 0xFF;
				
				__renderMesh_transform.copyFrom(transform);
				transform = __renderMesh_transform;
				transform.translate(-_width / 2, -_height / 2);
				transform.scale(1 / (_width / 2), -1 / (_height / 2));
				
				_vertexUniforms.setXYZW(0, 0.0, 0.5, 1.0, 2.0);
				_vertexUniforms.setRGBA(1, r / 255, g / 255, b / 255, alpha);
				_vertexUniforms.setXYZW(2, transform.a, transform.b, transform.tx, 0);
				_vertexUniforms.setXYZW(3, transform.c, transform.d, transform.ty, 0);
				_vertexUniforms.setXYZW(4, 0, 0, 1, 0);
				_vertexUniforms.setXYZW(5, meshTexture.xInTexture, meshTexture.yInTexture, texture.textureData.width, texture.textureData.height);
				_context3d.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, _vertexUniforms, 6);
				//_context3d.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, _fragmentUniforms, 2);
				
				var indexBufferOffset = _meshIndexBufferOffsets[meshId];
				_context3d.drawTriangles(_indexBuffer, indexBufferOffset, mesh.trianglesN);
			}
		}
	}
	
	public function end():Void {
		_context3d.present();
	}
	
	var __renderTestTriangles_program:Null<Program3D> = null;
	public function renderTestTriangles():Void {
		//var trianglesN = Math.floor(maxIndexesN / 3);
		//for (i in 0...trianglesN) {
			//var j = i * 3;
			//
			//_indexVector[j + 0] = j + 0;
			//_indexVector[j + 1] = j + 1;
			//_indexVector[j + 2] = j + 2;
		//}
		//for (i in 0...trianglesN) {
			//var x0 = -0.5, y0 = -0.5;
			//var x1 = 0.0, y1 = 0.5;
			//var x2 = 0.5, y2 = 0.25;
			//
			//var j = i * 6;
			//var x =  Math.random() * 2.0 - 1.0;
			//var y =  Math.random() * 2.0 - 1.0;
			//_vertexVector[j + 0] = x0 * 0.05 + x;
			//_vertexVector[j + 1] = y0 * 0.05 + y;
			//_vertexVector[j + 2] = x1 * 0.05 + x;
			//_vertexVector[j + 3] = y1 * 0.05 + y;
			//_vertexVector[j + 4] = x2 * 0.05 + x;
			//_vertexVector[j + 5] = y2 * 0.05 + y;
		//}
		//for (i in 0...trianglesN) {
			//var x0 = -0.5, y0 = -0.5;
			//var x1 = 0.0, y1 = 0.5;
			//var x2 = 0.5, y2 = 0.25;
			//
			//var j = i * 6;
			//var x =  Math.random() * 2.0 - 1.0;
			//var y =  Math.random() * 2.0 - 1.0;
			//_texCoordVector[j + 0] = x0 * 0.05 + x;
			//_texCoordVector[j + 1] = y0 * 0.05 + y;
			//_texCoordVector[j + 2] = x1 * 0.05 + x;
			//_texCoordVector[j + 3] = y1 * 0.05 + y;
			//_texCoordVector[j + 4] = x2 * 0.05 + x;
			//_texCoordVector[j + 5] = y2 * 0.05 + y;
		//}
		//
		//if (__renderTestTriangles_program == null) {
			//var vertexProgram = new Agal([
				//'mov v0, va1',
				//'mov op, va0',
			//]).assembleVertexProgram(agalVersion);
			//var fragmentProgram = new Agal([
				//'mov oc, v0',
			//]).assembleFragmentProgram(agalVersion);
			//__renderTestTriangles_program = _context3d.createProgram();
			//__renderTestTriangles_program.upload(vertexProgram, fragmentProgram);
		//}
		//
		//_indexBuffer.uploadFromVector(_indexVector, 0, trianglesN * 3);
		//_vertexBuffer.uploadFromVector(_vertexVector, 0, trianglesN * 3);
		//_texCoordBuffer.uploadFromVector(_texCoordVector, 0, trianglesN * 3);
		//
		//setState(
			//_vertexBuffer,
			//null,
			//__renderTestTriangles_program,
			//null
		//);
		//
		//_context3d.drawTriangles(_indexBuffer, 0, trianglesN);
	}
	
	function setState(
		vertexBuffer:VertexBuffer3D,
		program:Program3D,
		texture:Null<TextureBase>,
		srcBlendFactor:Context3DBlendFactor,
		destBlendFactor:Context3DBlendFactor
	):Void {
		if (_currentVertexBuffer != vertexBuffer) {
			_context3d.setVertexBufferAt(0, vertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			_currentVertexBuffer = vertexBuffer;
		}
		
		if (_currentProgram != program) {
			_context3d.setProgram(program);
			_currentProgram = program;
		}
		
		if (_currentTexture != texture) {
			if (texture == null) {
				_context3d.setTextureAt(0, null);
			}
			else {
				_context3d.setTextureAt(0, texture);
			}
			_currentTexture = texture;
		}
		
		if (srcBlendFactor != _currentSrcBlendFactor || destBlendFactor != _currentDestBlendFactor) {
			_context3d.setBlendFactors(srcBlendFactor, destBlendFactor);
			_currentSrcBlendFactor = srcBlendFactor;
			_currentDestBlendFactor = destBlendFactor;
		}
	}
	
	function compileBuffers():Void {
		var indexBufferOffset = 0;
		var indexOffset = 0;
		var vertexBufferOffset = 0;
		var trianglesN = 0;
		var verticesN = 0;
		
		for (meshId in 0..._meshes.length) {
			var mesh = _meshes[meshId];
			var meshTexture = _meshTextures[meshId];
			if (canAddMeshToBuffer(mesh, meshTexture)) {
				_meshIndexBufferOffsets[meshId] = indexBufferOffset;
				
				var indices = mesh.indices;
				for (i in 0...mesh.trianglesN) {
					var j = i * 3;
					_indexVector[indexBufferOffset + j + 0] = indexOffset + indices[j + 0];
					_indexVector[indexBufferOffset + j + 1] = indexOffset + indices[j + 1];
					_indexVector[indexBufferOffset + j + 2] = indexOffset + indices[j + 2];
				}
				
				var vertices = mesh.vertices;
				//var texCoords = meshTexture.texCoords;
				for (i in 0...mesh.verticesN) {
					var j2 = i * 2;
					//var j4 = i * 4;
					_vertexVector[vertexBufferOffset + j2 + 0] = vertices[j2 + 0];
					_vertexVector[vertexBufferOffset + j2 + 1] = vertices[j2 + 1];
					//_vertexVector[vertexBufferOffset + j4 + 0] = vertices[j2 + 0];
					//_vertexVector[vertexBufferOffset + j4 + 1] = vertices[j2 + 1];
					//_vertexVector[vertexBufferOffset + j4 + 2] = texCoords[j2 + 0];
					//_vertexVector[vertexBufferOffset + j4 + 3] = texCoords[j2 + 1];
				}
				
				indexBufferOffset += mesh.trianglesN * 3;
				indexOffset += mesh.verticesN;
				vertexBufferOffset += mesh.verticesN * VERTEX_SIZE;
				trianglesN += mesh.trianglesN;
				verticesN += mesh.verticesN;
			}
		}
		
		_bufferTrianglesN = trianglesN;
		_bufferVerticesN = verticesN;
	}
	
	static inline function canAddMeshToBuffer(mesh:Null<RendererMesh>, meshTexture:Null<RendererMeshTexture>):Bool {
		return mesh != null && meshTexture != null;
	}
	
	static function getAgalVersion(profile:Context3DProfile):UInt {
		if (!AGAL_VERSIONS.exists(cast profile)) {
			throw new Error('Unknown Context3DProfile: $profile');
		}
		return AGAL_VERSIONS[cast profile];
	}
	
}