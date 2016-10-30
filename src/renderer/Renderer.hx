package renderer;

import haxe.ds.Vector;
import openfl.geom.Matrix;

@:allow(renderer)
class Renderer {
	
	public var width:Int;
	public var height:Int;
	
	public var cache:RendererCache = new RendererCache();
	
	var _width:Single = 0.0;
	var _height:Single = 0.0;
	
	var _context:RendererContext;
	var _commands:Vector<RendererCommand>;
	var _commandsCount:Int = 0;

	public function new(width:Int, height:Int) {
		this.width = width;
		this.height = height;
		
		_context = new RendererContext();
		_commands = new Vector(512);
		for (i in 0..._commands.length) {
			_commands[i] = new RendererCommand();
		}
	}
	
	public function begin():Void {
		_width = width;
		_height = height;
		
		if (!_context.isInitialized) {
			return;
		}
	}
	
	var __renderMesh_matrix:Matrix = new Matrix();
	public function renderMesh(name:String, transform:Matrix, red:Single = 1.0, green:Single = 1.0, blue:Single = 1.0, alpha:Single = 1.0):Void {
		if (_commands.length == _commandsCount) {
			var commands = new Vector(_commands.length * 2);
			Vector.blit(_commands, 0, commands, 0, _commands.length);
			for (i in _commands.length...commands.length) {
				commands[i] = new RendererCommand();
			}
			_commands = commands;
		}
		
		var a:Single = transform.a;
		var b:Single = transform.b;
		var c:Single = transform.c;
		var d:Single = transform.d;
		var tx:Single = transform.tx;
		var ty:Single = transform.ty;
		
		var halfWidth = width / 2;
		var halfHeight = height / 2;
		var scaleX = 1 / (width / 2);
		var scaleY = -1 / (height / 2);
		
		a = a * scaleX;
		b = b * scaleY;
		c = c * scaleX;
		d = d * scaleY;
		tx = (tx - halfWidth) * scaleX;
		ty = (ty - halfHeight) * scaleY;
		
		var command = _commands[_commandsCount++];
		command.set(name, a, b, c, d, tx, ty, red, green, blue, alpha);
	}
	
	public function end():Void {
		if (!_context.isInitialized) {
			return;
		}
		
		_context.setBackbufferSize(Std.int(_width), Std.int(_height));
		_context.context3d.clear(0.0, 0.0, 1.0, 1.0);
		_context.context3d.present();
		
		_commandsCount = 0;
	}
}
