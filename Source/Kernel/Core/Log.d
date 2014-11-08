﻿module Core.Log;

import Architecture;
import ObjectManager;


public abstract final class Log : IStaticModule {
	public __gshared int Base = 16;

	private __gshared DisplayChar* _display = cast(DisplayChar *)0xFFFFFFFF800B8000;
	private __gshared int _iterator;
	private __gshared int _padding;
	private __gshared bool _installed;
	public __gshared bool _lockable;

	public static bool Initialize() {
		//Set cursor
		Port.Write!byte(0x3D4, 0x0F);
		Port.Write!byte(0x3D5, 0);
		Port.Write!byte(0x3D4, 0x0E);
		Port.Write!byte(0x3D5, 0);
		
		//Clear screen
		foreach (i; 0 .. 2000)
			_display[i].Address = 0;

		SerialPort.Open();
		return true;
	}

	public static bool Install() {
		_installed = true;
		return true;
	}

	public static bool Uninstall() {
		_installed = false;

		return true;
	}

	public static void NewLine() {
		Scroll();
		_iterator += 80 - (_iterator % 80);
		SerialPort.Write("\n");
	}

	public static void WriteJSON(T...)(T args) {
		bool first;
		foreach (x; args) {
			alias A = typeof(x);

			static if (is(A == string)) {
				if (x == "{" || x == "[" || x == "}" || x == "]") {
					if (_padding && (x == "}" || x == "]"))
						_padding--;

					version (LogUserFriendly)
						if (!first)
							foreach (i; 0 .. _padding * 4)
								Write(" ");

					Write(x);

					version (LogUserFriendly)
						NewLine();

					if (x == "{" || x == "[")
						_padding++;
					continue;
				}
			} else static if (is(A == char)) {
				if (x == '{' || x == '[' || x == '}' || x == ']') {
					if (_padding && (x == '}' || x == ']'))
						_padding--;

					version (LogUserFriendly)
						if (!first)
							foreach (i; 0 .. _padding * 4)
								Write(" ");

					Write(x);

					version (LogUserFriendly)
						NewLine();

					if (x == '{' || x == '[')
						_padding++;
					continue;
				}
			}

			if (!first) {
				version (LogUserFriendly)
					foreach (i; 0 .. _padding * 4)
						Write(" ");

				Write("\"", x, "\": ");
				first = true;
			} else {
				Write("\"", x, "\",");

				version (LogUserFriendly)
					NewLine();
				first = false;
			}
		}
	}

	public static void WriteLine(T...)(T args) {
		Write(args);
		NewLine();
	}

	public static void Write(T...)(T args) {
		if (_lockable) //We must lock this...
			Port.Cli();

		foreach (x; args) {
			alias A = typeof(x);

			static if (is(A == struct) || is(A == class) || is(A == union) || is(A == interface))
				ParseBlock(x);
			else static if (is(A == string) || is(A == const char[]) || is(A == char[]))
				Put(cast(string)x);
			else static if (is(A == char))
				Put(cast(string)(cast(char *)&x)[0 .. 1]);
			else static if (is(A == long)  || is(A == ulong)  || is(A == int)  || is(A == uint) ||
			                is(A == short) || is(A == ushort) || is(A == byte) || is(A == ubyte))
				Put(ToString(x));
			else static if (is(A == enum))
				Put(ToString(cast(ulong)x));
			else static if (is(A == bool))
				Put(x ? "True" : "False");
			else static if (is(typeof({ foreach(elem; T.init) {} }))) {
				Write('[', x[0]);
				foreach (y; x[1 .. $])
					Write(", ", y);
				Put("]");
			} else
				Write("Unknown Type: ", A.stringof);
		}

		if (_lockable)
			Port.Sti();
	}

	private static void ParseBlock(T)(T args) {
		auto values = args.tupleof;

		WriteJSON('{');
		foreach (index, value; values)
			WriteJSON(T.tupleof[index].stringof, value);
		WriteJSON('}');
	}

	private static void Put(string str) {
		if (!_installed)
			return;

		Scroll();
		Print(str, 0, _iterator);
		SerialPort.Write(str);
		_iterator += str.length;
	}

	private static void Scroll() {
		if (_iterator > 80 * 25) {
			if (_lockable) //We must lock this...
				Port.Cli();

			_display[0 .. _iterator - 80] = _display[80 .. _iterator];
			_display[_iterator - 80 .. _iterator] = cast(DisplayChar)0;
			_iterator -= 80;

			if (_lockable)
				Port.Sti();
		}
	}

	private static void Print(string str, uint line, uint offset = 0, byte color = 0x7) {
		foreach (i; 0 .. str.length) {
			_display[line * 80 + offset + i].Char = str[i];
			_display[line * 80 + offset + i].Color = color;
		}
	}

	private static string ToString(T)(T number) {
		char[256] tmp;
		int i = 0;
		bool isNegative = false;
		
		if (!number)
			return "0";
		
		if (number < 0) {
			isNegative = true;
			number = -number;
		}

		static const char[] digits = "0123456789ABCDEF";
		while (number) {
			tmp[i++] = digits[number % Base];
			number = cast(T)(number / Base);
		}

		if (Base == 16) {
			tmp[i++] = 'x';
			tmp[i++] = '0';
		} else if (Base == 8) {
			tmp[i++] = '0';
		} else if (Base == 2) {
			tmp[i++] = 'b';
			tmp[i++] = '0';
		}

		if (isNegative)
			tmp[i++] = '-';
		
		for (int j = 0; j < i / 2; j++) {
			char t = tmp[j];
			tmp[j] = tmp[i - j - 1];
			tmp[i - j - 1] = t;
		}
		
		return cast(string)tmp[0 .. i];
	}

	private union DisplayChar {
		public struct {
			char Char;
			byte Color;
		}
		ushort Address;
	}

	private abstract final static class SerialPort {
		private enum port = 0x3F8;
		
		private static void Open() {
			Port.Write!ubyte(cast(short)(port + 1), 0x00);
			Port.Write!ubyte(cast(short)(port + 3), 0x80);
			Port.Write!ubyte(cast(short)(port + 0), 0x03);
			Port.Write!ubyte(cast(short)(port + 1), 0x00);
			Port.Write!ubyte(cast(short)(port + 3), 0x03);
			Port.Write!ubyte(cast(short)(port + 2), 0xC7);
			Port.Write!ubyte(cast(short)(port + 4), 0x0B);
		}
		
		private static bool Recieved() {
			return (Port.Read!ubyte(cast(short)(port + 5)) & 1) != 0;
		}
		
		private static bool IsTransmitEmpty() {
			return (Port.Read!byte(cast(short)(port + 5)) & 0x20) != 0;
		}
		
		private static void Write(char c) {
			while (!IsTransmitEmpty()) {}
			Port.Write!ubyte(port, c);
		}
		
		private static void Write(string text) {
			foreach (x; text)
				Write(x);
		}
		
		private static char Read() {
			return Recieved() ? Port.Read!ubyte(port) : 0;
		}
	}
}