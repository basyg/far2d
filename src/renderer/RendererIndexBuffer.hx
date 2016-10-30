package renderer;

import openfl.display3D.IndexBuffer3D;

class RendererIndexBuffer {
	
	@:allow(renderer.RendererContext) var indexBuffer3D:Null<IndexBuffer3D> = null;
	@:allow(renderer.RendererContext) var context:RendererContext;
	
	public function new(context:RendererContext) {
		this.context = context;
	}
	
}