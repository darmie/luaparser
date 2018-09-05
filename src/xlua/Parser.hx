package xlua;

import byte.ByteData;
import haxe.io.BytesData;
import xlua.Data.Keyword;
import hxparse.Parser.parse as parse;
import hxparse.ParserBuilder;
import haxe.macro.Expr;
import xlua.Data.Token;
import xlua.Data.TokenDef;
import xlua.Data.RuleStat;
import xlua.Data.RuleExpr;
import xlua.ast.*;

using xlua.Data;


class Parser extends hxparse.Parser<hxparse.LexerTokenSource<Token>, Token> {
    var ast:Array<RuleStat>;


    public function new(ts:hxparse.LexerTokenSource<Token>) {
        super(ts);
        ast = new Array<RuleStat>();
    }
    public function parseLua() {
        return parseStatements(ast);
    }

    static function isDecimal(ch:Int):Bool { return '0'.charCodeAt(0) <= ch && ch <= '9'.charCodeAt(0); }

    static function isIdent(ch:Int, pos:Int):Bool {
        return ch == '_'.charCodeAt(0) || 'A'.charCodeAt(0) <= ch && ch <= 'Z'.charCodeAt(0) || 'a'.charCodeAt(0) <= ch && ch <= 'z'.charCodeAt(0) || isDecimal(ch) && pos > 0;
    }

    static function isDigit(ch:Int):Bool {
        return '0'.charCodeAt(0) <= ch && ch <= '9'.charCodeAt(0) || 'a'.charCodeAt(0) <= ch && ch <= 'f'.charCodeAt(0) || 'A'.charCodeAt(0) <= ch && ch <= 'F'.charCodeAt(0);
    }


    function parseStatements(stmts:Array<RuleStat>) {
        return parse(switch stream {
            // if statements
            // 'if' exp 'then' block ('elseif' exp 'then' block)* ('else' block)? 'end'
            case [{tok:Kwd(KwdIf)}]:{
                parseIfStatement(stmts);
                parseStatements(stmts);
                stmts;
            };
            case [{tok:Kwd(KwdWhile)}]:{
                var condition = parseLogicalOp();
                var doBlock:Array<RuleStat> = new Array<RuleStat>();
                switch  stream{
                    case [{tok:Kwd(KwdDo)}]:{
                        parseStatements(doBlock);
                        switch stream {
                            case [{tok:Kwd(KwdEnd)}]:{}
                            case _:{}
                            default: {
                                throw "Parse error: expected 'end' after do-statement";
                            }
                        }
                    }
                    case _:
                        throw "Parse error: invalid while statment. expected 'do'";
                }
                stmts.push(SWhile(condition, doBlock));
                parseStatements(stmts);
                stmts;
            };
            // assignments
            // x = exp or x, y, z = exp, exp, exp
            case [{tok:Const(c)}]:{
                var rhs = [];
                var lhs = [];
                switch c {
                    case CIdent(s): {
                        lhs.push(EIdent(s));
                        var method = null;
                        var params = [];
                        // check if its a function call
                        switch stream {
                            case [{tok:Col} | {tok:Dot}]:{
                                switch stream {
                                    case [{tok:Const(CIdent(s))}]:{
                                        method = EIdent(s);
                                        switch stream {
                                            case [{tok:POpen}]:{
                                                parseExprList(params);
                                                stmts.push(SFunctionCall(EFunctionCall(null, lhs[0], method, params, false)));
                                                switch stream {
                                                    case [_ => v]:{
                                                        switch v {
                                                            case {tok:PClose}:
                                                            default:{
                                                                throw "Parse error: Parenthesis opened but not closed. expected ')'";
                                                            }
                                                        }
                                                    }
                                                }
                                            };
                                            case _:
                                        }
                                    };
                                }
                            };
                            case [{tok:POpen}]:{
                                parseExprList(params);
                                stmts.push(SFunctionCall(EFunctionCall(null, lhs[0], null, params, false)));
                                switch stream {
                                    case [_ => v]:{
                                        switch v {
                                            case {tok:PClose}:
                                            default:{
                                                throw "Parse error: Parenthesis opened but not closed. expected ')'";
                                            }
                                        }
                                    }
                                }
                            };
                        }
                    };
                    case _:
                }
                parseNameList(lhs);
                switch stream {
                    case [{tok:Binop(OpAssign)}]:{  
                        parseExprList(rhs);
                        stmts.push(SAssign(lhs, rhs));
                    };
                    case [{tok:Eof}]:
                    case _:
                }
                parseStatements(stmts);
                stmts;              
            };
            // local assignments 
            // local x = y
            case [{tok:Kwd(KwdLocal)}]:{
                switch stream {
                    case [{tok:Const(c)}]:{
                        var rhs = [];
                        var lhs = [];
                        switch c {
                            case CIdent(s): {
                                lhs.push(EIdent(s));
                            };
                            case _:
                        }
                        parseNameList(lhs);
                        switch stream {
                            case [{tok:Binop(OpAssign)}]:{  
                                parseExprList(rhs);
                                stmts.push(SLocalAssign(lhs, rhs));
                            };
                            case [{tok:Eof}]:
                            case _:
                        }                      
                    };
                    case [{tok:Kwd(KwdFunction)}]:{
                        var name = "";
                        switch stream {
                            case [{tok:Const(CIdent(s))}]:{
                                name = s;
                            };
                            case _:
                        }
                        var func = parseFunctionBody();

                        stmts.push(SFunctionDef(name, func));

                    }
                    case _:                   
                }

                parseStatements(stmts);
                stmts;  
            };
            // function name
            // function object:method() ... end
            // function object.method() .... end
            // function name() ... end
            case [{tok:Kwd(KwdFunction)}]:{
                        var name = "";
                        var method = "";
                        switch stream {
                            case [{tok:Const(CIdent(s))}]:{
                                name = s;
                                
                                switch stream {
                                    case [{tok:Col}]:{
                                        switch stream {
                                            case [{tok:Const(CIdent(s))}]:{
                                                method = s;
                                            }
                                        }
                                    };
                                    case [{tok:Dot}]:{
                                        switch stream {
                                            case [{tok:Const(CIdent(s))}]:{
                                                method = s;
                                            }
                                        }
                                    }
                                    case _:
                                }
                            };

                            case _:
                        }
                        var func = parseFunctionBody();
                        
                        stmts.push(SFunctionName(func, EIdent(name), method));
                        
                        parseStatements(stmts);
                        stmts;              
            };
            // return statement
            // return expr;
            case [{tok:Kwd(KwdReturn)}]: {
                var v:Array<RuleExpr> = [];
                parseExprList(v);
                stmts.push(SReturn(v));
                parseStatements(stmts);
                stmts;
            };
            // repeat block until exp
            case [{tok:Kwd(KwdRepeat)}]: {
                var block = parseStatements([]);
                var expr = null;
                switch stream {
                    case [{tok:Kwd(KwdUntil)}]: {
                       expr = parseLogicalOp();
                       switch stream {
                           case [{tok:POpen}]:{
                               expr = parseLogicalOp();
                               switch stream {
                                   case [_ => v]:{
                                       switch v {
                                           case {tok:PClose}:
                                           default:{
                                               throw "Parse error: Parenthesis opened but not closed. expected ')'";
                                           }
                                       }
                                   }
                               }
                           };
                           case _:
                       }
                    }
                    case _:
                }
                stmts.push(SRepeat(expr, block));
                parseStatements(stmts);
                stmts;
            };
            // '(' exp ')'
            case [{tok:POpen}]:{
                var exprs = [];
                parseExprList(exprs);
                switch stream {
                    case [_ => v]:{
                        switch v {
                            case {tok:PClose}:
                            case _:{
                                    throw "Parse error: Parenthesis opened but not closed. expected ')'";
                            }
                        };

                    }
                }
                stmts.push(SParenthesis(exprs));
                parseStatements(stmts);
                stmts;
            };
            case [{tok:Kwd(KwdDo), pos:p}]:{
                var doBlock:Array<RuleStat> = new Array<RuleStat>();
                parseStatements(doBlock);
                switch stream {
                    case [{tok:Kwd(KwdEnd)}]:{}
                    case _:{}
                    default: {
                        throw "Parse error: expected 'end' after do-statement";
                    }
                }
                stmts.push(SDoBlock(doBlock));
                parseStatements(stmts);
                stmts;
            }
            case [{tok:Eof}]:{
                stmts;
            };
            case _:{
                stmts;
            }
        });
    }

    function parseLogicalOp() {
         return parse(switch stream {
             // exp Binop exp
             case [{tok:Const(c1)}, {tok:Binop(op)}, {tok:Const(c2)}]:{
                var lhs:RuleExpr = null;
                var rhs:RuleExpr = null;
                var _op:String = null;
                switch c1 {
                    case CInt(s):{
                        lhs = ENumber(s);
                    };
                    case CString(s):{
                        lhs = EString(s);
                    };
                    case CIdent(s): {
                        lhs = EIdent(s);
                    };
                    case _: 
                }

                switch c2 {
                    case CInt(s):{
                        rhs = ENumber(s);
                    };
                    case CString(s):{
                        rhs = EString(s);
                    };
                    case CIdent(s): {
                        rhs = EIdent(s);
                    };
                    case _: 
                }

                switch op {
                    case OpEq: {
                        _op = "==";
                    };
                    case OpNotEq: {
                        _op = "~=";
                    };
                    case OpAnd: {
                        _op = "and";
                    };
                    case OpOr: {
                        _op = "or";
                    };
                    case OpLt: {
                        _op = "<";
                    }
                    case OpGt: {
                        _op = ">";
                    }
                    case OpGte: {
                        _op = ">=";
                    }
                    case OpLte: {
                        _op = "<=";
                    }
                    case _: {}
                }

                ELogicalOp(lhs, rhs, _op);
                
             };
             default: 
                null;
         });
    }


    function parseDoStatement(stmts:Array<RuleStat>){
        var doBlock = [];
        parseStatements(doBlock);
        stmts.push(SDoBlock(doBlock));
    }


    function parseIfStatement(stmts:Array<RuleStat>){
               var reRun = function(){};
               var condition:RuleExpr = parseLogicalOp();
               var then:Array<RuleStat> = new Array<RuleStat>();
               var _else:Array<RuleStat> = new Array<RuleStat>();
            
               var reRun = function(){
                //check 'then' block
                parse(switch stream {
                    case [{tok:Kwd(KwdThen)}]: {
                        parseStatements(then);
                        // check 'else' or 'elseIf' block
                        switch stream {
                            case [{tok:Kwd(KwdElse)}]: {
                                parseStatements(_else);
                                switch stream { 
                                    case [_ => v]:{
                                         
                                        switch v.tok {
                                            case Kwd(KwdEnd):{
                                            }
                                            default: {
                                                throw "Parse Error: if block not closed";
                                            }
                                        }
                                    }                                    
                                }
                                
                            };
                            case [{tok:Kwd(KwdElseif)}]:{
                                parseIfStatement(_else);
                            }
                            case [_ => v]:{
                                
                                switch v.tok {
                                    case Kwd(KwdEnd):{
                                    }
                                    default: {
                                        throw "Parse Error: if block not closed";
                                    }
                                }
                            }
                        }

                        stmts.push(SIfThen(condition, then, _else));
                    };
                    default: {
                        throw "Parse Error: missing 'then' keyword";
                    }
                });
                
               }
               reRun();     
    }


    function parseExprList(ret:Array<RuleExpr>):Array<RuleExpr> {
        var reRun = function(){};
        reRun = function() {
                    parse(switch stream {
                        case [{tok:Comma}]:{
                            reRun();
                        }
                        case [{tok:Const(cx)}]:{
                            switch cx {
                                case CIdent(s): {
                                    var id = EIdent(s);
                                    var params = [];
                                    // check function call
                                    switch stream {
                                        case [{tok:Col} | {tok:Dot}]:{
                                            switch stream {
                                                case [{tok:Const(CIdent(s))}]:{
                                                    var method = EIdent(s);
                                                    switch stream {
                                                        case [{tok:POpen}]:{
                                                            parseExprList(params);
                                                            ret.push(EFunctionCall(null, id, method, params, false));
                                                            switch stream {
                                                                case [_ => v]:{
                                                                    switch v {
                                                                        case {tok:PClose}:
                                                                        default:{
                                                                            throw "Parse error: Parenthesis opened but not closed. expected ')'";
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        };
                                                        case _:
                                                    }
                                                };
                                            }
                                        };
                                        case [{tok:POpen}]:{
                                                parseExprList(params);
                                                ret.push(EFunctionCall(null, id, null, params, false));
                                                switch stream {
                                                    case [_ => v]:{
                                                        switch v {
                                                            case {tok:PClose}:
                                                            default:{
                                                                throw "Parse error: Parenthesis opened but not closed. expected ')'";
                                                            }
                                                        }
                                                    }
                                                }
                                        };
                                        default:{
                                            ret.push(EIdent(s));
                                        }
                                    }

                                };
                                case CInt(s):{
                                    ret.push(ENumber(s));
                                };
                                case CString(s):{
                                    ret.push(EString(s));
                                }
                                case CFloat(s):{
                                    ret.push(ENumber(s));
                                }
                                case _:
                            }                            
                        };
                        case [{tok:Kwd(KwdFunction)}]:{
                            var func = parseFunctionBody();
                            ret.push(func);
                            reRun();
                            ret;
                        };
                        case _:
                    });
        };        
        return parse(switch stream {
            case [{tok:Const(c)}]:{
                switch c {
                    case CIdent(s): {
                       // ret.push();
                        var id = EIdent(s);
                        var params = [];
                        switch stream {
                                        case [{tok:Col} | {tok:Dot}]:{
                                            switch stream {
                                                case [{tok:Const(CIdent(s))}]:{
                                                    var method = EIdent(s);
                                                    switch stream {
                                                        case [{tok:POpen}]:{
                                                            parseExprList(params);
                                                            ret.push(EFunctionCall(null, id, method, params, false));
                                                            switch stream {
                                                                case [_ => v]:{
                                                                    switch v {
                                                                        case {tok:PClose}:
                                                                        default:{
                                                                            throw "Parse error: Parenthesis opened but not closed. expected ')'";
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        };
                                                        case _:
                                                    }
                                                };
                                            }
                                        };
                                        case [{tok:POpen}]:{
                                                
                                                parseExprList(params);
                                                ret.push(EFunctionCall(null, id, null, params, false));
                                                switch stream {
                                                    case [_ => v]:{
                                                        switch v {
                                                            case {tok:PClose}:
                                                            default:{
                                                                throw "Parse error: Parenthesis opened but not closed. expected ')'";
                                                            }
                                                        }
                                                    }
                                                }
                                        };
                                        case _:
                        }

                        if(params.length == 0){
                            ret.push(id);
                        }
                    };
                    case CInt(s):{
                        ret.push(ENumber(s));
                    };
                    case CString(s):{
                        ret.push(EString(s));
                    }
                    case CFloat(s):{
                        ret.push(ENumber(s));
                    }
                    case _:
                }

                reRun();
                ret;
            }
            case [{tok:Kwd(KwdFunction)}]:{
                var func = parseFunctionBody();
                ret.push(func);
                reRun();
                ret;
            }
            // '(' exp ')'
            case [{tok:POpen}]:{
                parseExprList(ret);
                switch stream {
                    case [_ => v]:{
                        switch v {
                            case {tok:PClose}:
                            default:{
                                throw "Parse error: Parenthesis opened but not closed. expected ')'";
                            }
                        }
                    }
                }
                reRun();
                ret;
            };
            case _:{
                ret;
            };
        });
    }

    function parseNameList(ret:Array<RuleExpr>):Array<RuleExpr> {
        return parse(switch stream {
            case [{tok:Comma}]:{
                switch stream {
                    case [{tok:Const(c)}]:{
                        var reRun = function(){};
                        switch c {
                                case CIdent(s): {
                                    ret.push(EIdent(s));
                                };
                                case _:
                        }

                        reRun = function() {
                            switch stream {
                                case [{tok:Comma}]:{
                                    reRun();
                                }
                                case [{tok:Const(CIdent(s))}]:{
                                    ret.push(EIdent(s));
                                }
                                case _:
                            }
                        };
                        reRun();
                        ret;
                    }                    
                }                
            }
            case _:{
                ret;
            }
        });
    }

    function parseParamList(ret:Array<Dynamic>){
        var reRun = function(){};
        reRun = function() {
                            parse(switch stream {
                                case [{tok:Comma}]:{
                                    reRun();
                                }
                                case [{tok:Const(CIdent(s))}]:{
                                    ret.push(EIdent(s));
                                }
                                case [{tok:TriplDot}]:{
                                    reRun();
                                    ret.push("...");
                                }
                                case _:
                            });
        };  
        parse(switch stream {
            case [{tok:Comma}]:{              
                switch stream {
                    case [{tok:Const(c)}]:{
                        switch c {
                                case CIdent(s): {
                                    ret.push(EIdent(s));
                                };
                                case _:
                        }
                        reRun();
                    };
                    case [{tok:TriplDot}]:{
                        reRun();
                        ret.push("...");
                    };                  
                }                
            }
            case _:{
                
            }
        });        
    }


    function parseFunctionBody():RuleExpr{
                var params:Array<RuleExpr> = [];
                var hasVargs:Bool = false;
                var block = new Array<RuleStat>();
                parse(switch stream {
                        case [{tok:POpen}]: {
                            switch stream {
                                case [{tok:Const(c)}]:{
                                    switch c {
                                        case CIdent(s): {
                                            params.push(EIdent(s));
                                        };
                                        case _:
                                    }

                                    var _params:Array<Dynamic> = [];
                                    parseParamList(_params);
                                    for(p in _params){
                                        if(Std.is(p, String) && p == "..."){
                                            hasVargs = true;
                                        } else {
                                            params.push(p);
                                        }
                                    }

                                    switch stream {
                                        case [{tok:TriplDot}]:{
                                            hasVargs = true;
                                        }
                                        case [_ => v]:{
                                            switch v.tok {
                                                case PClose:{
                                                    block.concat(parseStatements(block));
                                                    switch stream {
                                                        case [_ => k]:{
                                                            switch k.tok {
                                                                case Kwd(KwdEnd):{}
                                                                case _:{
                                                                    throw "Parse Error: Function body not closed";
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                case _:{
                                                    throw "Parse Error: expected ')', invalid function";
                                                }
                                            }
                                        }
                                    }
                                    
                                };
                                case _:                            
                            }
                        };
                        case _:
                    }
                ); 

                return EFunction(params, hasVargs, block);     
    }






    // function parseKeyword(k:Keyword, pos:hxparse.Position):Array<AST> {
    //     return switch k {
    //         case KwdLocal: {
    //             parseLocalAssignment();
    //         };
    //         case KwdFunction: {
    //             //parseFunc();
    //             [];
    //         };
    //         case KwdAnd: [];
    //         case KwdDo: [];
    //         case KwdBreak: [];
    //         case KwdElse: [];
    //         case KwdIf: [];
    //         case KwdElseIf: [];
    //         case KwdTrue: [];
    //         case KwdFalse: [];
    //         case KwdNil: [];
    //         case KwdNot: [];
    //         case KwdOr: [];
    //         case KwdThen: [];
    //         case KwdReturn: [];
    //         case KwdRepeat: [];
    //         case KwdFor: [];
    //         case KwdWhile: [];
    //         case KwdUntil: [];
    //         case KwdIn: [];
    //         case KwdEnd: [];
    //     }
    // }


    // function parseLocalAssignment():Array<AST> {
    //     var localExp = new LocalAssignStmt();
    //     localExp.exprs = new Array<xlua.ast.Expr>();
    //     localExp.names = new Array<String>();
        
    //     parse(switch stream {
    //         case [{tok:Const(CIdent(s))}]: {
    //             localExp.names.push(s);
    //             var moreNames = function (){};
    //             var moreExprs = function (){};
    //             moreExprs = function () {
    //                                     switch stream {
    //                                         case [{tok:Comma}]: {
    //                                             switch stream {
    //                                                 case [{tok:Const(x)}]:{
    //                                                     //CIdent(ident) | CInt(in) | CFloat(in)
    //                                                     switch x {
    //                                                         case CInt(d) | CFloat(d): {
    //                                                             var number = new NumberExpr();
    //                                                             number.value = d;
    //                                                             localExp.exprs.push(number);
    //                                                         }
    //                                                         case CIdent(d): {
    //                                                             var id = new IdentExpr();
    //                                                             id.value = d;
    //                                                             localExp.exprs.push(id);
    //                                                         }
    //                                                         case _ :
    //                                                     }
    //                                                 };
    //                                                 case [{tok:Eof}]:
    //                                             }
    //                                             moreExprs();
    //                                         }; 
    //                                         case [{tok:Eof}]:                           
    //                                     }
    //             };
                
    //             moreNames = function () {
    //                 switch stream {
    //                     case [{tok:Comma}]: {
    //                         switch stream {
    //                             case [{tok:Const(CIdent(s1))}]:{
    //                                 trace(s1);
    //                                 localExp.names.push(s1);
    //                             };
    //                             case [{tok:Eof}]:
    //                         }
    //                         moreNames();
    //                     };
    //                     case [{tok:Binop(op)}] : {
    //                         switch stream {
    //                             case [{tok:Const(CIdent(s1) | CInt(s1) | CFloat(s1))}]: {
    //                                 var id = new IdentExpr();
    //                                 id.value = s1;
    //                                 localExp.exprs.push(id);
    //                                 moreExprs();
    //                             };
    //                             case [{tok:Kwd(k)}]: {
    //                                 switch k {
    //                                     case KwdFunction:{
    //                                         var func = parseFuncExpr();
    //                                         localExp.exprs.push(func);
    //                                     }
    //                                     case _:
    //                                 }
                                    
    //                             };
    //                         }
                            
    //                     };
    //                     case [{tok:Eof}]:
    //                 }
    //             };

    //             moreNames();
    //         };
    //     });
       
    //     ast.push({stmt: localExp, pos:this.curPos().pmin});
    //     return ast;
    // }


    // function parseFuncExpr():FunctionExpr{
    //     var fun = new FunctionExpr();
    //     var parlist = {
    //         hasVargs:false,
    //         names: new Array<String>()
    //     };
    //     fun.parList = parlist;
    //     fun.stmts = new Array<Stmt>();
    //     parse(switch stream {
    //         case [{tok:POpen}]:{
    //             var funcNames = function (){};
    //             funcNames = function (){
    //                 switch stream {
    //                     case [{tok:Const(CIdent(x))}]:  {
    //                         fun.parList.names.push(x);
    //                         funcNames();
    //                     }
    //                     case [{tok:Comma}]:{
    //                         funcNames();
    //                     }
    //                     case [{tok:PClose}]:{
    //                         //close func bracket
    //                         switch stream {
    //                             case [{tok:Kwd(k)}]:{
    //                                 var ast = parseKeyword(k, this.curPos());
    //                                 for(v in ast){
    //                                     fun.stmts.push(v.stmt);
    //                                 }
    //                             }
    //                         }
                            
    //                     }
    //                     case [{tok:Eof}]:{

    //                     }
    //                 }
    //             }

    //             funcNames();
    //         };
    //     });

    //     return fun;
    // }
}