package xlua;
import byte.ByteData;
import haxe.macro.Expr;
import xlua.Data.Token;

using xlua.Data;

//import hxparse.Parser.parse as parse;

enum LexerErrorMsg {
	UnterminatedString;
	UnterminatedRegExp;
	UnclosedComment;
	UnterminatedEscapeSequence;
	InvalidEscapeSequence(c:String);
	UnknownEscapeSequence(c:String);
	UnclosedCode;
}

class LexerError {
	public var msg:LexerErrorMsg;
	public var pos:Dynamic;
	public function new(msg, pos:Dynamic) {
		this.msg = msg;
		this.pos = pos;
	}
}

class Lexer extends hxparse.Lexer implements hxparse.RuleBuilder {

	static function mkPos(p:hxparse.Position, ?td):Dynamic {
		var pos = {
			file: p.psource,
			min: p.pmin,
			max: p.pmax,
			line: null
		};
		if(td != null){
			pos.line = p.getLinePosition(td);
		}
		return pos;
	}


	static function mk(lexer:hxparse.Lexer, td) {
		return new xlua.Data.Token(td, mkPos(lexer.curPos(), lexer.input));
	}

	// @:mapping generates a map with lowercase enum constructor names as keys
	// and the constructor itself as value
	static var keywords = @:mapping(3) Data.Keyword;

    static var buf = new StringBuf();

    static var ident = "_*[a-zA-Z][a-zA-Z0-9_]*|_+|_+[0-9][_a-zA-Z0-9]*";

    static var integer = "([1-9][0-9]*)|0";

    // @:rule wraps the expression to the right of => with function(lexer) return
    public static var tok = @:rule [
        "" => mk(lexer, Eof),
        "[\r\n\t ]+" => {
			#if keep_whitespace
			var space = lexer.current;
			var token:Token = lexer.token(tok);
			token.space = space;
			token;
			#else
			lexer.token(tok);
			#end
		},
        "0x[0-9a-fA-F]+" => mk(lexer, Const(CInt(lexer.current))),
        integer => mk(lexer, Const(CInt(lexer.current))),
        integer + "\\.[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
        "\\.[0-9]+" => mk(lexer, Const(CFloat(lexer.current))),
        integer + "[eE][\\+\\-]?[0-9]+" => mk(lexer,Const(CFloat(lexer.current))),
        integer + "\\.[0-9]*[eE][\\+\\-]?[0-9]+" => mk(lexer,Const(CFloat(lexer.current))),
        "-- [^\n\r]*" => mk(lexer, CommentLine(lexer.current.substr(2))),
        "+\\+" => mk(lexer,Unop(OpIncrement)),
        "~" => mk(lexer,Unop(OpNegBits)),
        "%=" => mk(lexer,Binop(OpAssignOp(OpMod))),
        "&=" => mk(lexer,Binop(OpAssignOp(OpAnd))),
        "|=" => mk(lexer,Binop(OpAssignOp(OpOr))),
        "^=" => mk(lexer,Binop(OpAssignOp(OpXor))),
        "+=" => mk(lexer,Binop(OpAssignOp(OpAdd))),
        "-=" => mk(lexer,Binop(OpAssignOp(OpSub))),
        "*=" => mk(lexer,Binop(OpAssignOp(OpMult))),
        "/=" => mk(lexer,Binop(OpAssignOp(OpDiv))),
        "<<=" => mk(lexer,Binop(OpAssignOp(OpShl))),
        "==" => mk(lexer,Binop(OpEq)),
        "~=" => mk(lexer,Binop(OpNotEq)),
        "<=" => mk(lexer,Binop(OpLte)),
        "and" => mk(lexer,Binop(OpBoolAnd)),
        "or" => mk(lexer,Binop(OpBoolOr)),
        "<<" => mk(lexer,Binop(OpShl)),
        "\\.\\.\\." => mk(lexer, TriplDot),
        "~" => mk(lexer,Unop(OpNot)),
        "<" => mk(lexer,Binop(OpLt)),
        ">" => mk(lexer,Binop(OpGt)),
        ":" => mk(lexer, Col),
        "," => mk(lexer, Comma),
        "\\." => mk(lexer, Dot),
        "%" => mk(lexer,Binop(OpMod)),
        "&" => mk(lexer,Binop(OpAnd)),
        "|" => mk(lexer,Binop(OpOr)),
        "^" => mk(lexer,Binop(OpXor)),
        "+" => mk(lexer,Binop(OpAdd)),
        "*" => mk(lexer,Binop(OpMult)),
        "/" => mk(lexer,Binop(OpDiv)),
        "-" => mk(lexer,Binop(OpSub)),
        "=" => mk(lexer,Binop(OpAssign)),
        "in" => mk(lexer,Binop(OpIn)),
        "[" => mk(lexer, BkOpen),
        "]" => mk(lexer, BkClose),
        "{" => mk(lexer, BrOpen),
        "}" => mk(lexer, BrClose),
        "\\(" => mk(lexer, POpen),
        "\\)" => mk(lexer, PClose),
		'"' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(string) catch (e:haxe.io.Eof) throw new LexerError(UnterminatedString, mkPos(pmin, lexer.input));
			var token = mk(lexer, Const(CString(unescape(buf.toString(), mkPos(pmin)))));
			token.pos.min = pmin.pmin; token;
		},
		"'" => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(string2) catch (e:haxe.io.Eof) throw new LexerError(UnterminatedString, mkPos(pmin, lexer.input));
			var token = mk(lexer, Const(CString(unescape(buf.toString(), mkPos(pmin)))));
			token.pos.min = pmin.pmin; token;
		},
		'--\\[\\[' => {
			buf = new StringBuf();
			var pmin = lexer.curPos();
			var pmax = try lexer.token(comment) catch (e:haxe.io.Eof) throw new LexerError(UnclosedComment, mkPos(pmin, lexer.input));
			var token = mk(lexer, Comment(buf.toString()));
			token.pos.min = pmin.pmin; token;
		},
        "#" + ident => mk(lexer, Sharp(lexer.current.substr(1))),
		ident => {
			var kwd = keywords.get(lexer.current);
			if(kwd != null){
				mk(lexer, Kwd(kwd));
			} else {
				mk(lexer, Const(CIdent(lexer.current)));
			}
		}
	];

	public static var string = @:rule [
		"\\\\\\\\" => {
			buf.add("\\\\");
			lexer.token(string);
		},
		"\\\\" => {
			buf.add("\\");
			lexer.token(string);
		},
		"\\\\\"" => {
			buf.add('"');
			lexer.token(string);
		},
		'"' => lexer.curPos().pmax,
		"[^\\\\\"]+" => {
			buf.add(lexer.current);
			lexer.token(string);
		}
	];

    //escaped string
    public static var string2 = @:rule [
		"\\\\t" => {
			buf.addChar("\t".code);
			lexer.token(string);
		},
		"\\\\n" => {
			buf.addChar("\n".code);
			lexer.token(string);
		},
		"\\\\r" => {
			buf.addChar("\r".code);
			lexer.token(string);
		},
		'\\\\"' => {
			buf.addChar('"'.code);
			lexer.token(string);
		},
		"\\\\u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]" => {
			buf.add(String.fromCharCode(Std.parseInt("0x" +lexer.current.substr(2))));
			lexer.token(string);
		},
		'"' => {
			lexer.curPos().pmax;
		},
		'[^"]' => {
			buf.add(lexer.current);
			lexer.token(string);
		}        
    ];

	public static var comment = @:rule [
	 	"\\]\\]" => lexer.curPos().pmax,
	];

	static inline function unescapePos(pos:Dynamic, index:Int, length:Int):Dynamic {
		return {
			file: pos.source,
			min: pos.min + index,
			max: pos.min + index + length,
			line: null
		}
	}

	static function unescape(s:String, pos:Position) {
		var b = new StringBuf();
		var i = 0;
		var esc = false;
		while (true) {
			if (s.length == i) {
				break;
			}
			var c = s.charCodeAt(i);
			if (esc) {
				var iNext = i + 1;
				switch (c) {
					case 'n'.code: b.add("\n");
					case 'r'.code: b.add("\r");
					case 't'.code: b.add("\t");
					case '"'.code | '\''.code | '\\'.code: b.addChar(c);
					case _ >= '0'.code && _ <= '3'.code => true:
						iNext += 2;
					case 'x'.code:
						var chars = s.substr(i + 1, 2);
						if (!(~/^[0-9a-fA-F]{2}$/.match(chars))) throw new LexerError(InvalidEscapeSequence("\\x"+chars), unescapePos(pos, i, 1 + 2));
						var c = Std.parseInt("0x" + chars);
						b.addChar(c);
						iNext += 2;
					case 'u'.code:
						var c:Int;
						if (s.charAt(i + 1) == "{") {
							var endIndex = s.indexOf("}", i + 3);
							if (endIndex == -1) throw new LexerError(UnterminatedEscapeSequence, unescapePos(pos, i, 2));
							var l = endIndex - (i + 2);
							var chars = s.substr(i + 2, l);
							if (!(~/^[0-9a-fA-F]+$/.match(chars))) throw new LexerError(InvalidEscapeSequence("\\u{"+chars+"}"), unescapePos(pos, i, 1 + 2 + l));
							c = Std.parseInt("0x" + chars);
							if (c > 0x10FFFF) throw new LexerError(InvalidEscapeSequence("\\u{"+chars+"}"), unescapePos(pos, i, 1 + 2 + l));
							iNext += 2 + l;
						} else {
							var chars = s.substr(i + 1, 4);
							if (!(~/^[0-9a-fA-F]{4}$/.match(chars))) throw new LexerError(InvalidEscapeSequence("\\u"+chars), unescapePos(pos, i, 1 + 4));
							c = Std.parseInt("0x" + chars);
							iNext += 4;
						}
						b.addChar(c);
					case c:
						throw new LexerError(UnknownEscapeSequence("\\"+String.fromCharCode(c)), unescapePos(pos, i, 1));
				}
				esc = false;
				i = iNext;
			} else switch (c) {
				case '\\'.code:
					++i;
					esc = true;
				case _:
					b.addChar(c);
					++i;
			}

		}
		return b.toString();
	}
}