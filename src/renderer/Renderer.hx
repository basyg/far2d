package renderer;

import haxe.ds.Vector;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DVertexBufferFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Matrix;
import openfl.utils.AGALMiniAssembler;

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
		var scaleX = 1 / halfWidth;
		var scaleY = -1 / halfHeight;
		
		a = a * scaleX;
		b = b * scaleY;
		c = c * scaleX;
		d = d * scaleY;
		tx = (tx - halfWidth) * scaleX;
		ty = (ty - halfHeight) * scaleY;
		
		var command = _commands[_commandsCount++];
		command.set(name, a, b, c, d, tx, ty, red, green, blue, alpha);
	}
	
	var ib:IndexBuffer3D = null;
	var vb:VertexBuffer3D = null;
	var p:Program3D = null;
	var u:openfl.Vector<Float> = null;
	
	public function end():Void {
		if (!_context.isInitialized) {
			return;
		}
		
		_context.setBackbufferSize(Std.int(_width), Std.int(_height));
		_context.context3d.clear(0.0, 0.0, 1.0, 1.0);
		
		var c = _context.context3d;
		if (ib == null) {
			ib = c.createIndexBuffer(3);
			vb = c.createVertexBuffer(3, 2);
			p = c.createProgram();
			
			ib.uploadFromVector(openfl.Vector.ofArray([(0:UInt), 1, 2]), 0, 3);
			vb.uploadFromVector(openfl.Vector.ofArray([0.5, 0.0, 1.0, 0.5, 0.0, 1.0]), 0, 3);
			
			var as = new AGALMiniAssembler(true);
			var vp = as.assemble(Context3DProgramType.VERTEX, [
				'add v0 va0 vc0',
				'mov op va0',
			].join('\n'));
			var fp = as.assemble(Context3DProgramType.FRAGMENT, [
				'mov oc, v0',
			].join('\n'));
			p.upload(vp, fp);
			u = openfl.Vector.ofArray([0.0, 0.0, 0.0, 1.0]);
		}
		
		c.setVertexBufferAt(0, vb, 0, Context3DVertexBufferFormat.FLOAT_2);
		c.setProgram(p);
		c.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, u, 1);
		c.drawTriangles(ib, 0, 1);
		
		_context.context3d.present();
		
		_commandsCount = 0;
	}
	
}
