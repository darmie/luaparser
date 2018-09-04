package test;

import byte.ByteData;
import xlua.Lexer;
import xlua.Parser;

class Main {
    public static function main() {
        var str = "return (table.print(a))";
        var byteData = ByteData.ofString(str);
        var lex = new Lexer(byteData, "test.lua");
        var ts = new hxparse.LexerTokenSource(lex, Lexer.tok);
        var p = new Parser(ts);
        trace(p.parseLua());
    }
}