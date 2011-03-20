/*
Copyright 2011 Martin Jonasson, grapefrukt games. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY grapefrukt games "AS IS" AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL grapefrukt games OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of grapefrukt games.
*/

package com.grapefrukt.exporter.serializers.images {
	import com.codeazur.as3swf.data.consts.BitmapFormat;
	import com.codeazur.as3swf.utils.MatrixUtils;
	import com.grapefrukt.exporter.misc.MaxRectsBinPack;
	import com.grapefrukt.exporter.serializers.files.IFileSerializer;
	import com.grapefrukt.exporter.serializers.files.ZipFileAtlasSerializer;
	import com.grapefrukt.exporter.textures.BitmapTexture;
	import com.grapefrukt.exporter.textures.TextureBase;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	/**
	 * ...
	 * @author Martin Jonasson (m@grapefrukt.com)
	 */
	public class PNGAtlasPackerSerializer extends PNGImageSerializer {
		
		private var _texture_rects	:Vector.<TextureRect>;
		private var _binpackers		:Vector.<MaxRectsBinPack>;
		private var _atlas_width	:uint;
		private var _atlas_height	:uint;
		
		public function PNGAtlasPackerSerializer(atlasWidth:uint = 512, atlasHeight:uint = 512) {
			_texture_rects 	= new Vector.<TextureRect>;
			_binpackers 	= new Vector.<MaxRectsBinPack>;
			_atlas_width 	= atlasWidth;
			_atlas_height 	= atlasHeight;
			
			addBinPacker();
		}
		
		public function addBinPacker():void {
			_binpackers.push(new MaxRectsBinPack(_atlas_width, _atlas_height));
		}
		
		override public function serialize(texture:TextureBase):ByteArray {
			var bt:BitmapTexture = texture as BitmapTexture;
			var rect:Rectangle;
			
			if (bt.bounds.width > _atlas_width || bt.bounds.height > _atlas_height) {
				throw new Error("Texture " + bt.name + "(" + bt.bounds.width + "x" + bt.bounds.height + ") is too big to fit in atlas (" + _atlas_width + "x" + _atlas_height + ")");
				return;
			}
			
			var index:int = -1;
			var binWasAdded:Boolean = false;
			
			while (!rect || rect.height == 0) {
				index++;
				
				// texture did not fit in any previous bin
				if (index >= _binpackers.length) {
					if (binWasAdded) {
						throw new Error("Can't fit " + texture.name + " in any atlas, giving up");
						return;
					}
					addBinPacker();
					binWasAdded = true;
				}
				
				rect = _binpackers[index].insert(bt.bounds.width, bt.bounds.height, MaxRectsBinPack.METHOD_RECT_BEST_AREA_FIT);
			}
			
			_texture_rects.push(new TextureRect(bt, rect, index));
			return null;
		}
		
		public function output(fileSerializer:IFileSerializer):void {
			var atlases:Vector.<BitmapData> = new Vector.<BitmapData>;
			var i:int;
			
			for (i = 0; i < _binpackers.length; i++) {
				atlases.push(new BitmapData(_atlas_width, _atlas_height, true, 0x00000000));
			}
			
			for each(var tr:TextureRect in _texture_rects) {
				atlases[tr.atlasIndex].copyPixels(tr.texture.bitmap, tr.texture.bitmap.rect, tr.rect.topLeft);
			}
			
			for (i = 0; i < _binpackers.length; i++) {
				var bt:BitmapTexture = new BitmapTexture("atlas" + i, atlases[i], atlases[i].rect, 0);
				fileSerializer.serialize(bt.name + extension, super.serialize(bt));
			}
		}
		
		override public function get extension():String {
			return ".png";
		}
		
	}

}
import com.grapefrukt.exporter.textures.BitmapTexture;
import flash.geom.Rectangle;

class TextureRect {
	public var texture		:BitmapTexture;
	public var rect			:Rectangle;
	public var atlasIndex	:uint = 0;
	
	public function TextureRect(texture:BitmapTexture, rect:Rectangle, atlasIndex:uint) {
		this.rect = rect;
		this.texture = texture;
		this.atlasIndex = atlasIndex;
	}
}