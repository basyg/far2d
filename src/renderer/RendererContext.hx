package renderer;

import openfl.display3D.Context3DBufferUsage;
import openfl.Lib;
import openfl.display.Stage3D;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DBlendFactor;
import openfl.display3D.Context3DProfile;
import openfl.display3D.Context3DRenderMode;
import openfl.display3D.Context3DTriangleFace;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.TextureBase;
import openfl.events.Event;

class RendererContext {
	
	static public inline var MAX_VERTICES_N:Int = 0xFFFF;
	
	static var AGAL_VERSIONS:Map<Context3DProfile, Int> = [
		Context3DProfile.BASELINE_CONSTRAINED => 1,
		Context3DProfile.BASELINE => 1,
		Context3DProfile.BASELINE_EXTENDED => 1,
		Context3DProfile.STANDARD_CONSTRAINED => 2,
		Context3DProfile.STANDARD => 2,
		//cast(Context3DProfile.STANDARD_EXTENDED, String) => 3,
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
	
	public var isInitialized(default, null):Bool = false;
	
	public var stage3d(default, null):Stage3D;
	public var context3d(default, null):Null<Context3D> = null;
	public var agalVersion(default, null):Int = -1;
	public var maxVertexUniformsN(default, null):Int = -1;
	public var maxFragmentUniformsN(default, null):Int = -1;
	
	@:allow(renderer) var vertexIdBuffers:Array<RendererVertexIdBuffer> = [];
	@:allow(renderer) var vertexBuffers:Array<RendererVertexBuffer> = [];
	
	var _backBufferWidth:Int = -1;
	var _backBufferHeight:Int = -1;
	var _vertexIdBuffer:Null<RendererVertexIdBuffer> = null;
	var _vertexBuffer:Null<RendererVertexBuffer> = null;
	var _program:Null<Program3D> = null;
	var _texture:Null<TextureBase> = null;
	var _srcBlendFactor:Null<Context3DBlendFactor> = null;
	var _destBlendFactor:Null<Context3DBlendFactor> = null;

	public function new() {
		stage3d = Lib.current.stage.stage3Ds[0];
		stage3d.addEventListener(Event.CONTEXT3D_CREATE, handleContext3dCreate);
		stage3d.requestContext3D(Context3DRenderMode.AUTO, Context3DProfile.STANDARD);
	}
	
	function handleContext3dCreate(e:Event):Void {
		stage3d.removeEventListener(Event.CONTEXT3D_CREATE, handleContext3dCreate);
		stage3d.addEventListener(Event.CONTEXT3D_CREATE, handleContext3dRestore);
		
		setContext3d(stage3d.context3D);
	}
	
	function handleContext3dRestore(e:Event):Void {
		// TODO
		throw 'is not implemented';
	}
	
	function setContext3d(context3d:Null<Context3D>):Void {
		if (context3d == null) {
			this.context3d = null;
			
			agalVersion = -1;
			maxVertexUniformsN = -1;
			maxFragmentUniformsN = -1;
			
			for (vertexIdBuffer in vertexIdBuffers) {
				if (vertexIdBuffer.vertexBuffer3D != null) {
					vertexIdBuffer.vertexBuffer3D.dispose();
					vertexIdBuffer.vertexBuffer3D = null;
				}
			}
			
			for (vertexBuffer in vertexBuffers) {
				if (vertexBuffer.vertexBuffer3D != null) {
					vertexBuffer.vertexBuffer3D.dispose();
					vertexBuffer.vertexBuffer3D = null;
				}
			}
		}
		else {
			if (!AGAL_VERSIONS.exists(context3d.profile)) {
				throw 'Unknown Context3DProfile: ${context3d.profile}';
			}
			
			this.context3d = context3d;
			context3d.enableErrorChecking = App.IS_DEBUG;
			context3d.setCulling(Context3DTriangleFace.NONE);
			
			agalVersion = AGAL_VERSIONS[context3d.profile];
			maxVertexUniformsN = VERTEX_PROGRAM_CONSTANTS_N[agalVersion];
			maxFragmentUniformsN = FRAGMENT_PROGRAM_CONSTANTS_N[agalVersion];
			
			for (vertexIdBuffer in vertexIdBuffers) {
				vertexIdBuffer.vertexBuffer3D = context3d.createVertexBuffer(MAX_VERTICES_N, 1, Context3DBufferUsage.DYNAMIC_DRAW);
			}
			
			for (vertexBuffer in vertexBuffers) {
				vertexBuffer.vertexBuffer3D = context3d.createVertexBuffer(MAX_VERTICES_N, vertexBuffer.samplersFourbytesCount, Context3DBufferUsage.DYNAMIC_DRAW);
			}
		}
		
		isInitialized = context3d != null;
	}
	
	public function setBackbufferSize(width:Int, height:Int):Void {
		if (_backBufferWidth != width || _backBufferHeight != height) {
			if (isInitialized) {
				context3d.configureBackBuffer(width, height, 0, false, false, false);
			}
			_backBufferWidth = width;
			_backBufferHeight = height;
		}
	}
	
	public function setState(
		vertexIdBuffer:Null<RendererVertexIdBuffer>,
		vertexBuffer:Null<RendererVertexBuffer>,
		program:Program3D,
		texture:TextureBase,
		srcBlendFactor:Context3DBlendFactor,
		destBlendFactor:Context3DBlendFactor
	):Void {
		if (!isInitialized) {
			return;
		}
		
		{
			var samplerIndex = 0;
			
			if (_vertexIdBuffer != vertexIdBuffer) {
				context3d.setVertexBufferAt(samplerIndex++, vertexIdBuffer.vertexBuffer3D, 0, Context3DVertexBufferFormat.FLOAT_1);
				_vertexIdBuffer = vertexIdBuffer;
			}
			
			if (_vertexBuffer != vertexBuffer) {
				if (vertexBuffer != null) {
					var bufferOffset = 0;
					
					for (samplerFormat in vertexBuffer.samplers) {
						context3d.setVertexBufferAt(samplerIndex++, vertexBuffer.vertexBuffer3D, bufferOffset, samplerFormat);
						bufferOffset += RendererVertexBuffer.fourbytesCountOfSamplerFormat(samplerFormat);
					}
				}
				if (_vertexBuffer != null) {
					var oldSamplersCount = _vertexBuffer.samplers.length;
					var newSamplersCount = vertexBuffer == null ? 0 : vertexBuffer.samplers.length;
					
					for (i in newSamplersCount...oldSamplersCount) {
						context3d.setVertexBufferAt(samplerIndex++, null);
					}
				}
			}
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
	
	public function createVertexIdBuffer():RendererVertexIdBuffer {
		var vertexIdBuffer = new RendererVertexIdBuffer(this);
		vertexIdBuffers.push(vertexIdBuffer);
		return vertexIdBuffer;
	}
	
	public function disposeVertexIdBuffer(vertexIdBuffer:RendererVertexIdBuffer):Void {
		if (vertexIdBuffer.context == null) {
			'RendererVertexIdBuffer is already disposed';
		}
		
		if (vertexIdBuffer.vertexBuffer3D != null) {
			vertexIdBuffer.vertexBuffer3D.dispose();
			vertexIdBuffer.vertexBuffer3D = null;
		}
		
		var index = vertexIdBuffers.indexOf(vertexIdBuffer);
		var last = vertexIdBuffers.pop();
		if (last != vertexIdBuffer) {
			vertexIdBuffers[index] = last;
		}
		vertexIdBuffer.context = null;
	}
	
	public function createVertexBuffer(samplers:Array<Context3DVertexBufferFormat>):RendererVertexBuffer {
		var vertexBuffer = new RendererVertexBuffer(this, samplers);
		vertexBuffers.push(vertexBuffer);
		return vertexBuffer;
	}
	
	public function disposeVertexBuffer(vertexBuffer:RendererVertexBuffer):Void {
		if (vertexBuffer.context == null) {
			'RendererVertexBuffer is already disposed';
		}
		
		if (vertexBuffer.vertexBuffer3D != null) {
			vertexBuffer.vertexBuffer3D.dispose();
			vertexBuffer.vertexBuffer3D = null;
		}
		
		var index = vertexBuffers.indexOf(vertexBuffer);
		var last = vertexBuffers.pop();
		if (last != vertexBuffer) {
			vertexBuffers[index] = last;
		}
		vertexBuffer.context = null;
	}
	
}