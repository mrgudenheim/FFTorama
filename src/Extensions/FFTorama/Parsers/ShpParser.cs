using Godot;
using System;
using System.Collections;
using System.IO;
using System.Linq;
using System.Security.AccessControl;

public partial class ShpParser : Control
{
	// [Export(PropertyHint.File, "*.txt")]
	public string filepathToHexString;

	[Export]
	FileDialog fileDialog;
	int hexPerFrame = 4;
	int pixelsPerTile = 8;

	Vector2[] subframeSizes =[
		new Vector2(  8,  8 ),
		new Vector2( 16,  8 ),
		new Vector2( 16, 16 ),
		new Vector2( 16, 24 ),
		new Vector2( 24,  8 ),
		new Vector2( 24, 16 ),
		new Vector2( 24, 24 ),
		new Vector2( 32,  8 ),
		new Vector2( 32, 16 ),
		new Vector2( 32, 24 ),
		new Vector2( 32, 32 ),
		new Vector2( 32, 40 ),
		new Vector2( 48, 16 ),
		new Vector2( 40, 32 ),
		new Vector2( 48, 48 ),
		new Vector2( 56, 56 )];

	// https://ffhacktics.com/wiki/Sprite_Y_Rotation_Table
	double[] rotationsDegrees = [
		0,
		15.996,
		23.027,
		26.455,
		26.719,
		26.982,
		29.971,
		42.979,
		45.000,
		55.020,
		60.029,
		70.049,
		90.000,
		119.971,
		120.059,
		124.980,
		127.969,
		129.990,
		135.000,
		140.010,
		145.020,
		150.029,
		153.018,
		154.951,
		160.049,
		164.971];
	
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{		
		// ParseHex(filepathToHexString);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	// public override void _Process(double delta)
	// {
	// }

	// connected from FileDialog node file_selected signal
	public void ParseHex (string filepath)
	{
		// string inputHex = inputHex1;
		// string inputHex = File.ReadAllText(filepath);
		string[] filepathSplit = filepath.Split("_");
		string fileSuffix = filepathSplit[filepathSplit.Length - 1];
		fileSuffix = fileSuffix.Substring(0, fileSuffix.Length-4); // remove ".txt"

		using var file = Godot.FileAccess.Open(filepath, Godot.FileAccess.ModeFlags.Read);
		string inputHex = file.GetAsText();		
		
		string[] hexStrings = inputHex.Split(" ");
		string output = "label,frame_id,subframes,rotation_degrees,x_shift,y_shift,top_left_x_pixels,top_left_y_pixels,sizeX,sizeY,flip_x,flip_y";
		string frameDataString = "";

		int section1Length = 8;
		int section2Length = (int)0x400;
		int swimStartIndex = HexStringToInt(hexStrings[3] + hexStrings[2] + hexStrings[1] + hexStrings[0]) + section2Length; // only type1, type2, cyoko unit have swim frames
		int firstAttackFrame = HexStringToInt(hexStrings[5] + hexStrings[4]); // starting at this point frames load from second (lower) half of spritesheet
		
		// these shapes have a slightly different format
		if (fileSuffix == "wep1" || fileSuffix == "wep2" || fileSuffix == "eff1" || fileSuffix == "eff2")
		{
			section1Length = (int)0x44;
			section2Length = (int)0x800;
			firstAttackFrame = 9999; // these types do not have a second (lower) half 
		}

		int frameDataStartIndex = section2Length + section1Length;
		int firstBlockLength = HexStringToInt(hexStrings[frameDataStartIndex + 1] + hexStrings[frameDataStartIndex]);

		int frameCount = 0;
		int frame_id = 0;
		// add 2 since first 2 were the firstBlockLength
		for (int i = frameDataStartIndex + 2; i < hexStrings.Length; i++)
		{
			// GD.Print(i);
			// after the first block, jump to the second block of frames (ie. swimming) and reset frame count to load from top of spritesheet
			if (i == (frameDataStartIndex + firstBlockLength + 2)) // add 2 to account for first 2 hex defining the block length
			{
				// GD.Print("jumping to second block");
				i = swimStartIndex + 2; // add 2 to account for first 2 hex defining the block length
				frameCount = 0;
			}
			
			
			int numSubframes = 1 + (HexStringToInt(hexStrings[i]) % 8); // right 4 (least significant) bits
			int rotationIndex = HexStringToInt(hexStrings[i]) >> 3; // left 5 (most significant) bits
			GD.Print($"{frame_id}: {hexStrings[i]} {rotationIndex}");
			double yRotation = rotationsDegrees[rotationIndex]; // TODO need to look up value

			int yOffset = 0;
			if (frameCount >= firstAttackFrame)
			{
				yOffset = 256; // subframe should be loaded from second half of sprite sheet
			}

			frameDataString = fileSuffix + "," + frame_id + "," + numSubframes.ToString() + "," + yRotation;

			for (int subFrame = 0; subFrame < numSubframes; subFrame++)
			{
				int xShift = HexStringToInt(hexStrings[i + 2 + (subFrame * hexPerFrame)]);
				int yShift = HexStringToInt(hexStrings[i + 3 + (subFrame * hexPerFrame)]);

				// correct for signed 8 bit int
				if (xShift > 128)
				{
					xShift -= 256;
				}
				if (yShift > 128)
				{
					yShift -= 256;
				}

				string frameHex = hexStrings[i + 5  + (subFrame * hexPerFrame)] + hexStrings[i + 4 + (subFrame * hexPerFrame)]; // accomadate little endian
				int frameDec = HexStringToInt(frameHex);

				BitArray frameBits = new BitArray(new int[] {frameDec} );
				string frameBitsString = Reverse(ToBitString(frameBits));

				string topLeftXString = frameBitsString.Substring(frameBitsString.Length - 5, 5);
				string topLeftYString = frameBitsString.Substring(frameBitsString.Length - 10, 5);
				string sizeRefString = frameBitsString.Substring(frameBitsString.Length - 14, 4);
				string flipXString = frameBitsString.Substring(frameBitsString.Length - 15, 1);
				string flipYString = frameBitsString.Substring(frameBitsString.Length - 16, 1);

				int topLeftX = Convert.ToInt32(topLeftXString, 2) * pixelsPerTile;
				int topLeftY = (Convert.ToInt32(topLeftYString, 2) * pixelsPerTile) + yOffset;
				int sizeRef = Convert.ToInt32(sizeRefString, 2);

				string[] textParts = [
					frameDataString, 
					xShift.ToString(), 
					yShift.ToString(), 
					topLeftX.ToString(), 
					topLeftY.ToString(), 
					subframeSizes[sizeRef].X.ToString(),
					subframeSizes[sizeRef].Y.ToString(),
					(flipXString.ToInt() != 0).ToString(), 
					(flipYString.ToInt() != 0).ToString()
					];

				frameDataString = String.Join(",", textParts);
			}

			// GD.Print(frameDataString);


			string[] allText = [output, frameDataString];
			output = String.Join("\n", allText.Where(s => !string.IsNullOrEmpty(s))); // ignore initial empty string
			
			// GD.Print(output + "\n");
			
			i = i + 2 + (4 * numSubframes) - 1; // subtract 1 since forloop already adds 1
			frameCount +=1;
			frame_id += 1;
		}

		// GD.Print(output);

		Godot.DirAccess.MakeDirRecursiveAbsolute("user://FrameData");
		using var saveFile = Godot.FileAccess.Open($"user://FrameData/frame_data_{fileSuffix}.txt", Godot.FileAccess.ModeFlags.Write);
    	saveFile.StoreString(output);

		// store frame offsets for wep and eff type spritesheets
		if (fileSuffix.StartsWith("wep") || fileSuffix.StartsWith("eff"))
		{
			int offsets_start = 6; // start at knife
			
			string frame_offset_data = "Knife,Ninja Sword,Sword,Knight Sword,Katana,Axe,Rod,Stave,Flail,Gun,Crossbow,Bow,Instrument,Book,Polearm,Pole,Bag,Cloth,Shield,Shuriken,Bomb\n";
			
			string[] frame_offsets = new string[section1Length - offsets_start];
			for (int i = offsets_start; i < section1Length; i += 2)
			{
				int frame_offset = HexStringToInt(hexStrings[i + 1] + hexStrings[i]);
				frame_offsets[(i - offsets_start) / 2] = frame_offset.ToString();
			}
			frame_offset_data = frame_offset_data + String.Join(",", frame_offsets);
			using var saveFileOffset = Godot.FileAccess.Open($"user://FrameData/frame_offset_data_{fileSuffix}.txt", Godot.FileAccess.ModeFlags.Write);
    		saveFileOffset.StoreString(frame_offset_data);
		}
		

		Tween tween = CreateTween();
		tween.TweenProperty(fileDialog, "visible", true, 0).SetDelay(0.1);
		// fileDialog.Visible = true;
	}

	public int HexStringToInt(string hex)
	{
		return int.Parse(hex, System.Globalization.NumberStyles.HexNumber);
	}

	public static string ToBitString(BitArray bits)
	{
		string bit_string = "";

		for (int i = 0; i < bits.Count; i++)
		{
			char c = bits[i] ? '1' : '0';
			bit_string += c;
		}

		return bit_string;
	}

	public static string Reverse( string s )
	{	
		char[] charArray = s.ToCharArray();
		Array.Reverse(charArray);
		return new string(charArray);
	}
}
