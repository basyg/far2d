package renderer;

import openfl.display3D.VertexBuffer3D;

class RendererVertexIdBuffer {
	
	@:allow(renderer) var vertexBuffer3D:Null<VertexBuffer3D> = null;
	@:allow(renderer) var context:RendererContext;
	
	public function new(context:RendererContext) {
		this.context = context;
	}
	
	public function dispose():Void {
		if (context == null) {
			'RendererVertexIdBuffer is already disposed';
		}
		
		context.disposeVertexIdBuffer(this);
	}
	
}