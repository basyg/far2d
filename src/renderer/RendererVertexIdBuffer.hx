package renderer;

import openfl.display3D.VertexBuffer3D;

class RendererVertexIdBuffer {
	
	@:allow(renderer.RendererContext) var vertexBuffer3D:Null<VertexBuffer3D> = null;
	@:allow(renderer.RendererContext) var context:RendererContext;
	
	public function new(context:RendererContext) {
		this.context = context;
	}
	
}