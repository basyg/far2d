package;

import com.adobe.utils.extended.AGALMiniAssembler;
import flash.display3D.Context3DProgramType;
import flash.utils.ByteArray;

abstract Agal(Array<String>) {
	
	static var assembler:AGALMiniAssembler = new AGALMiniAssembler(App.IS_DEBUG);
	
	public inline function new(?codeLines:Array<String>) {
		this = codeLines == null ? [] : codeLines;
	}
	
	@:op(A + B)
	public inline function addLine(line:String):Agal {
		var copy = this.copy();
		copy.push(line);
		return new Agal(copy);
	}
	
	@:op(A + B)
	public inline function addLines(lines:Array<String>):Agal {
		return new Agal(this.concat(lines));
	}
	
	@:op(A + B)
	public inline function addAgal(agal:Agal):Agal {
		return new Agal(this.concat(agal.getLines()));
	}
	
	public inline function assembleVertexProgram(agalVersion:Int = 1):ByteArray {
		var string = this.join('\n');
		return assembler.assemble(cast Context3DProgramType.VERTEX, string, agalVersion, false);
	}
	
	public inline function assembleFragmentProgram(agalVersion:Int = 1):ByteArray {
		var string = this.join('\n');
		return assembler.assemble(cast Context3DProgramType.FRAGMENT, string, agalVersion, false);
	}
	
	inline function getLines():Array<String> {
		return this;
	}
	
}