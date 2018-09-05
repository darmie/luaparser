package test;

import byte.ByteData;
import xlua.Lexer;
import xlua.Parser;

class Main {
    public static function main() {
        var str = 'print(x)
                   while x > 2 do 
                        if x == 2 then 
                            return 2
                        else 
                            return x
                        end
                   end';
        var byteData = ByteData.ofString(str);
        var lex = new Lexer(byteData, "test.lua");
        var ts = new hxparse.LexerTokenSource(lex, Lexer.tok);
        var p = new Parser(ts);
        trace(p.parseLua());
    }
}