package renderer;

import haxe.ds.Vector;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.VertexBuffer3D;

class RendererVertexBuffer {
	
	@:allow(renderer.RendererContext) var vertexBuffer3D:Null<VertexBuffer3D> = null;
	@:allow(renderer.RendererContext) var samplers:Vector<Context3DVertexBufferFormat>;
	@:allow(renderer.RendererContext) var samplersFourbytesCount:Int = 0;
	@:allow(renderer.RendererContext) var context:RendererContext;

	public function new(context:RendererContext, samplers:Array<Context3DVertexBufferFormat>) {
		this.context = context;
		this.samplers = Vector.fromArrayCopy(samplers);
		for (samplerFormat in samplers) {
			samplersFourbytesCount += fourbytesCountOfSamplerFormat(samplerFormat);
		}
	}
	
	public static inline function fourbytesCountOfSamplerFormat(samplerFormat:Context3DVertexBufferFormat):Int {
		return switch (samplerFormat) {
			case Context3DVertexBufferFormat.BYTES_4: 1;
			case Context3DVertexBufferFormat.FLOAT_1: 1;
			case Context3DVertexBufferFormat.FLOAT_2: 2;
			case Context3DVertexBufferFormat.FLOAT_3: 3;
			case Context3DVertexBufferFormat.FLOAT_4: 4;
		};
	}
	
}