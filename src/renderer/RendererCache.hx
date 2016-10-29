package renderer;

class RendererCache {
	
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