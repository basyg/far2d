package;

import flash.Lib;
import flash.Vector;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.geom.Matrix;
import flash.text.TextField;
import haxe.Timer;
import haxe.io.Path;
import mesh.Meshes;
import renderer.Renderer;

class App {
	
	public static inline var IS_DEBUG = #if debug true #else false #end;
	
	public var fps(default, null):Float = 0;
	public var frameDuration(default, null):Float = 0;
	public var statusUpdateTime(default, null):Float = 0;
	
	var _stage:Stage;
	var _renderer:Renderer;
	var _status:Null<TextField> = null;
	
	var _frameStartTimes:Vector<Float> = new Vector(60);
	var _frameTimes:Vector<Float> = new Vector(60);
	
	var _meshes:Meshes = null;

	public function new() {
		_stage = Lib.current.stage;
		_stage.scaleMode = StageScaleMode.NO_SCALE;
		_stage.align = StageAlign.TOP_LEFT;
		_stage.frameRate = 60;
		
		_renderer = new Renderer(_stage.stageWidth, _stage.stageHeight);
		
		//_status = new TextField();
		//_status.background = true;
		//_status.width = 150;
		//_status.height = 20;
		//_stage.addChild(_status);
		
		start();
		
		_stage.addEventListener(Event.RESIZE, handleResize);
		_stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
	}
	
	function start():Void {
		_meshes = new Meshes();
		
		var atlasName = Path.withoutExtension(_meshes.atlas.name);
		_renderer.cache.addTexture(atlasName, _meshes.atlasTextureData);
		
		for (mesh in _meshes.atlas.meshes) {
			var meshName = Path.withoutExtension(mesh.name);
			_renderer.cache.addMesh(meshName, mesh.indices, mesh.vertices, atlasName, mesh.xInAtlas, mesh.yInAtlas);
		}
	}
	
	function handleResize(e:Event):Void {
		_renderer.width = _stage.stageWidth;
		_renderer.height = _stage.stageHeight;
	}
	
	function handleEnterFrame(e:Event):Void {
		var t0 = Timer.stamp();
		
		update();
		
		var t1 = Timer.stamp();
		
		_frameStartTimes.shift();
		_frameStartTimes.push(t0);
		_frameTimes.shift();
		_frameTimes.push(t1 - t0);
		
		var measureDuration = 0.2;
		if (t0 - statusUpdateTime > measureDuration) {
			statusUpdateTime = t0;
			
			var framesN = 0;
			var frameTime = 0.0;
			for (i in 0...60) {
				var startTime = _frameStartTimes[i];
				if (t0 - startTime < measureDuration) {
					framesN++;
					frameTime += _frameTimes[i];
				}
			}
			fps = framesN / measureDuration;
			frameTime = frameTime / framesN * 1000;
			
			var fpsText = Math.round(fps * 10);
			var frameTimeText = Math.round(frameTime * 10);
			if (_status != null) {
				_status.text = 'fps: $fpsText frameTime: $frameTimeText';
			}
		}
	}
	
	function update():Void {
		_meshes.update(1 / _stage.frameRate);
		render();
	}
	
	var __render_matrix = new Matrix();
	function render():Void {
		_renderer.begin();
		
		var matrix = __render_matrix;
		matrix.identity();
		//m.translate(2560 / 2, 1440 / 2);
		matrix.scale(0.1, 0.1);
		//m.rotate( -Math.PI / 8)
		
		for (i in 0...10) {
			matrix.tx = 0;
			matrix.ty += 10;
			for (i in 0...20) {
				matrix.tx += 10;
				_renderer.renderMesh('objBuildAncientPoolStage1', matrix, 0xFFFFFF);
				matrix.tx += 10;
				_renderer.renderMesh('objBuildAncientPoolStage2', matrix, 0xFFFFFF);
				matrix.tx += 10;
				_renderer.renderMesh('objBuildAncientPoolStage3', matrix, 0xFFFFFF);
				matrix.tx += 10;
				_renderer.renderMesh('objBuildAncientPoolStage4', matrix, 0xFFFFFF);
				matrix.tx += 10;
				_renderer.renderMesh('objBuildAncientPoolStage5', matrix, 0xFFFFFF);
			}
		}
		
		_renderer.end();
	}
	
}