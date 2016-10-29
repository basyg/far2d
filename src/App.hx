package;

import flash.Vector;
import flash.display.Stage;
import flash.display.Stage3D;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DRenderMode;
import flash.events.Event;
import flash.geom.Matrix;
import flash.text.TextField;
import haxe.Timer;
import mesh.Meshes;
import renderer.Renderer;
import renderer.Renderer2;

enum ERenderer {
	
	First(renderer:Renderer);
	Second(renderer:Renderer2);
	
}

class App {
	
	public static inline var IS_DEBUG = #if debug true #else false #end;
	
	public var fps(default, null):Float = 0;
	public var frameDuration(default, null):Float = 0;
	public var statusUpdateTime(default, null):Float = 0;
	
	var _meshes:Meshes;
	
	var _stage:Stage;
	var _status:TextField;
	var _stage3d:Stage3D;
	var _renderer:Null<ERenderer> = null;
	
	var _frameStartTimes:Vector<Float> = new Vector(60);
	var _frameTimes:Vector<Float> = new Vector(60);

	public function new(stage:Stage) {
		_meshes = new mesh.Meshes();
		
		_stage = stage;
		_stage.scaleMode = StageScaleMode.NO_SCALE;
		_stage.align = StageAlign.TOP_LEFT;
		_stage.frameRate = 60;
		
		//_status = new TextField();
		//_status.background = true;
		//_status.width = 150;
		//_status.height = 20;
		//_stage.addChild(_status);
		
		_stage3d = stage.stage3Ds[0];
		_stage3d.addEventListener(Event.CONTEXT3D_CREATE, handleContext3dCreate);
		_stage3d.requestContext3D(cast Context3DRenderMode.AUTO, Context3DProfile.STANDARD);
		
		_stage.addEventListener(Event.ENTER_FRAME, handleEnterFrame);
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
			//_status.text = 'fps: $fpsText frameTime: $frameTimeText';
		}
	}
	
	function update():Void {
		_meshes.update(1 / _stage.frameRate);
		
		if (_renderer != null) {
			renderer();
		}
	}
	
	function renderer():Void {
		switch (_renderer) {
			case ERenderer.First(renderer): {
				renderer.begin();
				
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
						renderer.renderMesh('objBuildAncientPoolStage1.png', matrix, 0xFFFFFF);
						matrix.tx += 10;
						renderer.renderMesh('objBuildAncientPoolStage2.png', matrix, 0xFFFFFF);
						matrix.tx += 10;
						renderer.renderMesh('objBuildAncientPoolStage3.png', matrix, 0xFFFFFF);
						matrix.tx += 10;
						renderer.renderMesh('objBuildAncientPoolStage4.png', matrix, 0xFFFFFF);
						matrix.tx += 10;
						renderer.renderMesh('objBuildAncientPoolStage5.png', matrix, 0xFFFFFF);
					}
				}
				
				renderer.end();
			}
			case ERenderer.Second(renderer): {
				renderer.begin();
				
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
						renderer.renderMesh('objBuildAncientPoolStage1.png', matrix, 0xFFFFFF);
						matrix.tx += 10;
						renderer.renderMesh('objBuildAncientPoolStage2.png', matrix, 0xFFFFFF);
						matrix.tx += 10;
						renderer.renderMesh('objBuildAncientPoolStage3.png', matrix, 0xFFFFFF);
						matrix.tx += 10;
						renderer.renderMesh('objBuildAncientPoolStage4.png', matrix, 0xFFFFFF);
						matrix.tx += 10;
						renderer.renderMesh('objBuildAncientPoolStage5.png', matrix, 0xFFFFFF);
					}
				}
				
				renderer.end();
			}
		}
	}
	var __render_matrix = new Matrix();
	
	function handleContext3dCreate(e:Event):Void {
		_stage3d.removeEventListener(Event.CONTEXT3D_CREATE, handleContext3dCreate);
		
		//_renderer = ERenderer.First(new Renderer(_stage3d.context3D, _stage.stageWidth, _stage.stageHeight));
		_renderer = ERenderer.Second(new Renderer2(_stage3d.context3D, _stage.stageWidth, _stage.stageHeight));
		
		switch (_renderer) {
			case ERenderer.First(renderer): {
				renderer.addTexture(_meshes.atlas.name, _meshes.atlasTextureData);
				for (mesh in _meshes.atlas.meshes) {
					renderer.addMesh(mesh.name, mesh.indices, mesh.vertices);
					renderer.addMeshTexture(mesh.name, _meshes.atlas.name, mesh.xInAtlas, mesh.yInAtlas);
				}
			}
			case ERenderer.Second(renderer): {
				renderer.addTexture(_meshes.atlas.name, _meshes.atlasTextureData);
				for (mesh in _meshes.atlas.meshes) {
					renderer.addMesh(mesh.name, mesh.indices, mesh.vertices);
					renderer.addMeshTexture(mesh.name, _meshes.atlas.name, mesh.xInAtlas, mesh.yInAtlas);
				}
			}
		}
		
		_stage.addEventListener(Event.RESIZE, handleResize);
		_stage3d.addEventListener(Event.CONTEXT3D_CREATE, handleContext3dRestore);
	}
	
	function handleResize(e:Event):Void {
		switch (_renderer) {
			case ERenderer.First(renderer): renderer.setSize(_stage.stageWidth, _stage.stageHeight);
			case ERenderer.Second(renderer): renderer.setSize(_stage.stageWidth, _stage.stageHeight);
		}
	}
	
	function handleContext3dRestore(e:Event):Void {
		switch (_renderer) {
			case ERenderer.First(renderer): renderer.handleContext3dRestore();
			case ERenderer.Second(renderer): renderer.handleContext3dRestore();
		}
	}
	
}