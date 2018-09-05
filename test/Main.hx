package test;

import byte.ByteData;
import xlua.Lexer;
import xlua.Parser;

class Main {
    public static function main() {
        var str = "while x < 2 do return 2 end";
        var byteData = ByteData.ofString(str);
        var lex = new Lexer(byteData, "test.lua");
        var ts = new hxparse.LexerTokenSource(lex, Lexer.tok);
        var p = new Parser(ts);
        trace(p.parseLua());
    }
}