package renderer;

import openfl.Vector;

abstract RendererUniforms(Vector<Float>) to Vector<Float> {

	public inline function new(n:Int) {
		this = new Vector(n << 2, true);
	}
	
	public inline function clear():Void {
		for (i in 0...getConstantsN()) {
			var j = i << 2;
			this[j + 0] = 0.0;
			this[j + 1] = 0.0;
			this[j + 2] = 0.0;
			this[j + 3] = 0.0;
		}
	}
	
	public inline function setXY00(register:Int, x:Float, y:Float):Void {
		var i = register << 2;
		this[i + 0] = x;
		this[i + 1] = y;
		this[i + 2] = 0.0;
		this[i + 3] = 0.0;
	}
	
	public inline function setXYZW(register:Int, x:Float, y:Float, z:Float, w:Float):Void {
		var i = register << 2;
		this[i + 0] = x;
		this[i + 1] = y;
		this[i + 2] = z;
		this[i + 3] = w;
	}
	
	public inline function setRGBA(register:Int, r:Float, g:Float, b:Float, a:Float):Void {
		var i = register << 2;
		this[i + 0] = r;
		this[i + 1] = g;
		this[i + 2] = b;
		this[i + 3] = a;
	}
	
	public inline function setRGB1(register:Int, r:Float, g:Float, b:Float):Void {
		var i = register << 2;
		this[i + 0] = r;
		this[i + 1] = g;
		this[i + 2] = b;
		this[i + 3] = 1.0;
	}
	
	public inline function getConstantsN():Int {
		return this.length >> 2;
	}
	
}