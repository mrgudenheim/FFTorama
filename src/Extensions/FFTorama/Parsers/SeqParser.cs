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

	[Export(PropertyHint.File, "*.txt")]
	string opcodeListFilePath;

	// https://ffhacktics.com/wiki/SEQ_%26_Animation_info_page
	Dictionary<string, int> opcodeParameters = new();
	Dictionary<string, string> opcodeNames = new();
	
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{		
		LoadOpcodeData(opcodeListFilePath);
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	// public override void _Process(double delta)
	// {
	// }

	public void LoadOpcodeData(string opcodeFilePath)
	{
		using var file = Godot.FileAccess.Open(opcodeFilePath, Godot.FileAccess.ModeFlags.Read);
		string input = file.GetAsText();		
		
		string[] lines = input.Split("\n");

		// skip first row of headers
		for (int line_index = 1; line_index < lines.Length; line_index++)
		{		
			string[] parts = lines[line_index].Split(",");
			string opcodeCode = parts[2].Substring(0, 4); // ignore extra characters in text file
			string opcodeName = parts[0];
			int opcodeNumParameters = Int32.Parse(parts[1]);

			// GD.Print(opcodeName + " " + opcodeNumParameters.ToString() + " " + opcodeCode);
			opcodeNames[opcodeCode] = opcodeName;
			opcodeParameters[opcodeCode] = opcodeNumParameters;
		}
	}

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
			string[] textParts;

			// handle last animation
			int animationEnd = section3start + section3Length;
			if (animationId != animationIndicies.Count - 1) // handle non-last animation
			{
				animationEnd = animationIndicies[animationId + 1] + dataStartIndex;
			}

			int pos = animationIndicies[animationId] + dataStartIndex;
			while ( pos < animationEnd)
			{
				string opcode = (hexStrings[pos] + hexStrings[pos + 1]).ToLower();
				// if (opcode.StartsWith("ff"))
				// {
				// 	GD.Print($"{opcode} {opcodeParameters.ContainsKey(opcode)}");
				// }
				
				
				// handle opcodes
				if (opcodeParameters.ContainsKey(opcode))
				{
					string opcodeName = opcodeNames[opcode];
					string[] opcodeArguments = new string[opcodeParameters[opcode]];
					for (int i = 0; i < opcodeParameters[opcode]; i++)
					{
						int argument_pos = pos + 2 + i;
						int argument = HexStringToInt(hexStrings[argument_pos]);

						// correct for signed 8 bit int
						if (opcode == "ffc0" || // WaitForDistort
						opcode == "ffc6" || // WaitForInput
						opcode == "ffd3" || // WeaponSheatheCheck1
						opcode == "ffd6" || // WeaponSheatheCheck2
						opcode == "ffd8" || // SetFrameOffset
						opcode == "ffee" || // MoveUnitFB
						opcode == "ffef" || // MoveUnitDU 
						opcode == "fff0" || // MoveUnitRL
						opcode == "fffa" || // MoveUnit RL, DU, FB
						(opcode == "fffc" && i == 0) || // Wait (first parameter only)
						opcode == "fffd") // HoldWeapon
						{
							if (argument > 128)
							{
								argument -= 256;
							}
						}
						
						opcodeArguments[i] = argument.ToString();
					}
					string arguments = String.Join(",", opcodeArguments);

					textParts = [
						dataString,
						opcodeName,
						arguments
						];
					
					pos = pos + opcodeParameters[opcode] + 2; // add 2 to account for the bytes the opcode takes up
				}
				else
				{
					int frameId = HexStringToInt(hexStrings[pos]);
					int delay = HexStringToInt(hexStrings[pos + 1]);

					textParts = [
						dataString, 
						frameId.ToString(),
						delay.ToString()
						];

					pos += 2;
				}

				dataString = String.Join(",", textParts.Where(s => !string.IsNullOrEmpty(s))); // ignore empty strings
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
