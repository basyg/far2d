package renderer;

import flash.Lib;
import flash.display.Stage3D;
import flash.display3D.Context3D;
import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DRenderMode;
import flash.display3D.Context3DTriangleFace;
import flash.display3D.Program3D;
import flash.display3D.textures.TextureBase;
import flash.events.Event;

class RendererContext {
	
	static var AGAL_VERSIONS:Map<String, Int> = [
	cast(Context3DProfile.BASELINE_CONSTRAINED, String) => 1,
		cast(Context3DProfile.BASELINE, String) => 1,
		cast(Context3DProfile.BASELINE_EXTENDED, String) => 1,
		cast(Context3DProfile.STANDARD_CONSTRAINED, String) => 2,
		cast(Context3DProfile.STANDARD, String) => 2,
		cast(Context3DProfile.STANDARD_EXTENDED, String) => 3,
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
	
	var _backBufferWidth:Int = -1;
	var _backBufferHeight:Int = -1;
	//var _vertexBuffer:Null<VertexBuffer> = null;
	//var _vertexIdBuffer:Null<VertexIdBuffer> = null;
	var _program:Null<Program3D> = null;
	var _texture:Null<TextureBase> = null;
	var _srcBlendFactor:Null<Context3DBlendFactor> = null;
	var _destBlendFactor:Null<Context3DBlendFactor> = null;

	public function new() {
		stage3d = Lib.current.stage.stage3Ds[0];
		stage3d.addEventListener(Event.CONTEXT3D_CREATE, handleContext3dCreate);
		stage3d.requestContext3D(cast(Context3DRenderMode.AUTO, String), Context3DProfile.STANDARD);
	}
	
	function handleContext3dCreate(e:Event):Void {
		stage3d.removeEventListener(Event.CONTEXT3D_CREATE, handleContext3dCreate);
		stage3d.addEventListener(Event.CONTEXT3D_CREATE, handleContext3dRestore);
		setContext3d(stage3d.context3D);
	}
	
	function handleContext3dRestore(e:Event):Void {
		// TODO
	}
	
	function setContext3d(context3d:Null<Context3D>):Void {
		if (context3d == null) {
			this.context3d = null;
			
			agalVersion = -1;
			maxVertexUniformsN = -1;
			maxFragmentUniformsN = -1;
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
		}
		
		isInitialized = context3d != null;
	}
	
	public function setBackbufferSize(width:Int, height:Int):Void {
		if (_backBufferWidth != width || _backBufferHeight != height) {
			context3d.configureBackBuffer(width, height, 0, false, false, false);
			_backBufferWidth = width;
			_backBufferHeight = height;
		}
	}
	
	public function setState(
		//vertexBuffer:VertexBuffer,
		//vertexIdBuffer:VertexBuffer,
		program:Program3D,
		texture:TextureBase,
		srcBlendFactor:Context3DBlendFactor,
		destBlendFactor:Context3DBlendFactor
	):Void {
		//if (_vertexBuffer != vertexBuffer) {
			//context3d.setVertexBufferAt(0, vertexBuffer, 0, vertexBuffer.bufferFormat);
			//_vertexBuffer = vertexBuffer;
		//}
		//
		//if (_vertexIdBuffer != vertexIdBuffer) {
			//context3d.setVertexBufferAt(1, vertexIdBuffer, 0, vertexIdBuffer.bufferFormat);
			//_vertexIdBuffer = vertexIdBuffer;
		//}
		
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