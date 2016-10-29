package renderer;

import openfl.geom.Matrix;

@:allow(renderer)
class Renderer {
	
	public var width:Int;
	public var height:Int;
	
	var _context:RendererContext = null;

	public function new(width:Int, height:Int) {
		setSize(width, height);
		_context = new RendererContext();
	}
	
	public function setSize(width:Int, height:Int) {
		this.width = width;
		this.height = height;
	}
	
	public function begin():Void {
		if (!_context.isInitialized) {
			return;
		}
	}
	
	public function renderMesh(meshName:String, transform:Matrix, color:Int = 0xFFFFFF, alpha:Float = 1.0):Void {
		if (!_context.isInitialized) {
			return;
		}
	}
	
	public function end():Void {
		if (!_context.isInitialized) {
			return;
		}
		
		_context.setBackbufferSize(width, height);
		_context.context3d.clear(0.0, 0.0, 1.0, 1.0);
		_context.context3d.present();
	}
}
