package;

import flash.Vector;

abstract IntIdPool(Vector<Int>) {

	public inline function new(firstId:Int = 0) {
		this = new Vector(1);
		this[0] = firstId;
	}
	
	public inline function aquireId():Int {
		return if (this.length == 1) {
			var id = this[0];
			this[0] = id + 1;
			id;
		}
		else {
			this.pop();
		}
	}
	
	public inline function releaseId(id:Int):Void {
		this.push(id);
	}
	
}