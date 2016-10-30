package renderer;

class RendererCommand {
	
	public var meshName:Null<String> = null;
	
	public var a:Single = 0.0;
	public var b:Single = 0.0;
	public var c:Single = 0.0;
	public var d:Single = 0.0;
	public var tx:Single = 0.0;
	public var ty:Single = 0.0;
	
	public var red:Single = 0.0;
	public var green:Single = 0.0;
	public var blue:Single = 0.0;
	public var alpha:Single = 0.0;

	public function new() {
		
	}
	
	public inline function set(meshName:String,	a:Single, b:Single, c:Single, d:Single, tx:Single, ty:Single, red:Single, green:Single, blue:Single, alpha:Single):Void {
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