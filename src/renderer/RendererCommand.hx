package renderer;

class RendererCommand {
	
	public var meshName:Null<String> = null;
	
	public var a:Float = 0.0;
	public var b:Float = 0.0;
	public var c:Float = 0.0;
	public var d:Float = 0.0;
	public var tx:Float = 0.0;
	public var ty:Float = 0.0;
	
	public var red:Float = 0.0;
	public var green:Float = 0.0;
	public var blue:Float = 0.0;
	public var alpha:Float = 0.0;

	public function new() {
		
	}
	
	public inline function set(meshName:String,	a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float, red:Float, green:Float, blue:Float, alpha:Float):Void {
		this.meshName = meshName;
		
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
		this.tx = tx;
		this.ty = ty;
		
		this.red = red;
		this.green = green;
		this.blue = blue;
		this.alpha = alpha;
	}
	
}