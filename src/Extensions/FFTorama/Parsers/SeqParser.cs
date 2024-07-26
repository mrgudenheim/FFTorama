using Godot;
using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;

public partial class SeqParser : Control
{
	[Export]
	FileDialog fileDialog;
	int hexPerFrame = 2;

	// https://ffhacktics.com/wiki/SEQ_%26_Animation_info_page
	Dictionary<string, int> opcodeOffset = new Dictionary<string, int>
	{
		{"ffbe",0},
		{"ffbf",0},
		{"ffc0",1},
		{"ffc1",2},
		{"ffc2",0},
		{"ffc3",0},
		{"ffc4",2},
		{"ffc5",0},
		{"ffc6",1},
		{"ffc7",2},
		{"ffc8",2},
		{"ffc9",2},
		{"ffca",2},
		{"ffcb",0},
		{"ffcc",0},
		{"ffcd",0},
		{"ffce",0},
		{"ffcf",0},
		{"ffd0",0},
		{"ffd1",0},
		{"ffd2",0},
		{"ffd3",1},
		{"ffd4",1},
		{"ffd5",0},
		{"ffd6",1},
		{"ffd7",1},
		{"ffd8",1},
		{"ffd9",2},
		{"ffda",0},
		{"ffdb",1},
		{"ffdc",0},
		{"ffdd",1},
		{"ffde",0},
		{"ffdf",0},
		{"ffe0",0},
		{"ffe1",0},
		{"ffe2",1},
		{"ffe3",1},
		{"ffe4",1},
		{"ffe5",1},
		{"ffe6",1},
		{"ffe7",2},
		{"ffe8",2},
		{"ffe9",1},
		{"ffea",2},
		{"ffeb",0},
		{"ffec",0},
		{"ffed",1},
		{"ffee",1},
		{"ffef",1},
		{"fff0",1},
		{"fff1",2},
		{"fff2",2},
		{"fff3",1},
		{"fff4",1},
		{"fff5",1},
		{"fff6",1},
		{"fff7",3},
		{"fff8",2},
		{"fff9",0},
		{"fffa",3},
		{"fffb",2},
		{"fffc",2},
		{"fffd",1},
		{"fffe",0},
		{"ffff",0}
	};

	string[] opcodes =[
		"ffbe",
		"ffbf",
		"ffc0",
		"ffc1",
		"ffc2",
		"ffc3",
		"ffc4",
		"ffc5",
		"ffc6",
		"ffc7",
		"ffc8",
		"ffc9",
		"ffca",
		"ffcb",
		"ffcc",
		"ffcd",
		"ffce",
		"ffcf",
		"ffd0",
		"ffd1",
		"ffd2",
		"ffd3",
		"ffd4",
		"ffd5",
		"ffd6",
		"ffd7",
		"ffd8",
		"ffd9",
		"ffda",
		"ffdb",
		"ffdc",
		"ffdd",
		"ffde",
		"ffdf",
		"ffe0",
		"ffe1",
		"ffe2",
		"ffe3",
		"ffe4",
		"ffe5",
		"ffe6",
		"ffe7",
		"ffe8",
		"ffe9",
		"ffea",
		"ffeb",
		"ffec",
		"ffed",
		"ffee",
		"ffef",
		"fff0",
		"fff1",
		"fff2",
		"fff3",
		"fff4",
		"fff5",
		"fff6",
		"fff7",
		"fff8",
		"fff9",
		"fffa",
		"fffb",
		"fffc",
		"fffd",
		"fffe",
		"ffff"];
	
	
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
		string[] filepathSplit = filepath.Split("_");
		string fileSuffix = filepathSplit[filepathSplit.Length - 1];
		fileSuffix = fileSuffix.Substring(0, fileSuffix.Length-4); // remove ".txt"

		using var file = Godot.FileAccess.Open(filepath, Godot.FileAccess.ModeFlags.Read);
		string inputHex = file.GetAsText();		
		
		string[] hexStrings = inputHex.Split(" ");
		string output = "label,animation_id,frame_id,delay";
		string dataString = "";

		int section1Length = 4;
		int section2Length = (int)0x400;
		int section3start = section2Length + section1Length;
		int section3Length = HexStringToInt(hexStrings[section3start + 1] + hexStrings[section3start]);

		int dataStartIndex = section3start + 2; // add 2 to get past the size

		List<int> animationIndicies = new();
		for (int i = section1Length; i < section3start; i+=4)
		{
			if ((hexStrings[i] + hexStrings[i+1] + hexStrings[i+2] + hexStrings[i+3]) == "FFFFFFFF")
			{
				continue;
			}

			string hexIndex = hexStrings[i+1] + hexStrings[i];
			int decIndex = HexStringToInt(hexIndex);
			animationIndicies.Add(decIndex);

			// GD.Print(hexIndex);
		}

		// GD.Print(animationIndicies.Count);

		for (int animationId = 0; animationId < animationIndicies.Count; animationId++)
		{
			dataString = fileSuffix + "," + animationId; // TODO set name

			// handle last animation
			int animationEnd = section3start + section3Length;
			if (animationId != animationIndicies.Count - 1) // handle non-last animation
			{
				animationEnd = animationIndicies[animationId + 1] + dataStartIndex;
			}

			for (int pos = animationIndicies[animationId] + dataStartIndex; pos < animationEnd; pos += 2)
			{
				string opcode = hexStrings[pos] + hexStrings[pos + 1];
				// GD.Print(opcode);
				if (opcodeOffset.ContainsKey(opcode.ToLower()))
				{
					pos = pos + opcodeOffset[opcode.ToLower()] + 2;
					continue;
				}
				
				int frameId = HexStringToInt(hexStrings[pos]);
				int delay = HexStringToInt(hexStrings[pos + 1]);

				string[] textParts = [
					dataString, 
					frameId.ToString(),
					delay.ToString()
					];

				dataString = String.Join(",", textParts);
			}

			// GD.Print(frameDataString);


			string[] allText = [output, dataString];
			output = String.Join("\n", allText.Where(s => !string.IsNullOrEmpty(s))); // ignore initial empty string
			
			// GD.Print(output + "\n");
		}

		// GD.Print(output);
		
		Godot.DirAccess.MakeDirRecursiveAbsolute("user://SeqData");
		using var saveFile = Godot.FileAccess.Open($"user://SeqData/seq_data_{fileSuffix}.txt", Godot.FileAccess.ModeFlags.Write);
    	saveFile.StoreString(output);

		Tween tween = CreateTween();
		tween.TweenProperty(fileDialog, "visible", true, 0).SetDelay(0.1);
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
