package xlua;

import xlua.Data.RuleExpr;
import xlua.Data.Token;
import xlua.Data.TokenDef;
import hxparse.Parser.parse as parse;

using haxe.EnumTools;

class Parser extends hxparse.Parser<hxparse.LexerTokenSource<Token>, Token> {
	public function new(ts:hxparse.LexerTokenSource<Token>) {
		super(ts);
	}

	public function parseExpr(?e:RuleExpr):RuleExpr {
		return parse(switch stream {
			case [{tok: Const(c)}]:
				{
					switch c {
						case CIdent(s): {

								parseComplexExpr(EIdent(s));
							}
						case CInt(v): {
								parseComplexExpr(ENumber(v));
							}
						case CFloat(f): {
								parseComplexExpr(ENumber(f));
							}
						case _:
							null;
					}
				};
			case [{tok: POpen}]:
				{
					var exp = e;
					e = parseComplexExpr(e);
					var args = [];
					switch stream {
						case [{tok:Comma}]:{
							parseExprList(args);
							e;
						};
						case [_ => v]:{
							switch v {
								case {tok:PClose}:{
									if (exp != null){
										args.push(e);
										e = parseExpr(EFunctionCall(null, exp, null, args, false));
									}
									e;
								};
								case _:
									throw "Parse error: expectec ')'";
							}
						}
					}
				};
            case [{tok: Binop(op)}]:{
                parseComplexExpr(parseBinopExpr(e, Binop(op)));
            };
            case [{tok:BkOpen}]:{
                var ex = parseAttrGetExpr(e);
                var e2 = parseComplexExpr(ex);
                if(e2 != null){
                       ex = e2;
                }
                parseComplexExpr(ex);
            }
			case _:
                e;
		});
	}

	function parseComplexExpr(e:RuleExpr):RuleExpr {
		var exp = e;
		var token = this.peek(this.curPos().pmin);
		return switch token {
			case {tok: BkOpen}:
				{
                   
                   var e = parseAttrGetExpr(exp);
                   var e2 = parseExpr(e);
                   if(e2 != null){
                       e = e2;
                   }
                   e;
				};
            case {tok: Binop(op)} :
                {
			 		parseBinopExpr(exp, Binop(op));
			 	};
			case {tok: Dot} | {tok: Col} :
				{
					parseTableExpr(exp);
				};
			case {tok: POpen} :
				{
					var args = [];
					parseExprList(args);
					var ex = parseExpr(EFunctionCall(null, exp, null, args, false));
					ex;
				};
			default:
				var ex = parseExpr(e);
                if(ex == null){
                    ex = e;
                }
                ex;
		}
	}

	function parseExprList(exps:Array<RuleExpr>):Array<RuleExpr> {
		var key = null;
		return parse(switch stream {
			case [{tok: POpen}]:
				{
                    
					switch stream {
						case [{tok: Const(c)}]:
							{
                                
								switch c {
									case CIdent(s): {
											key = parseExpr(EIdent(s));
                                           
										}
									case CInt(v): {
											key = parseExpr(ENumber(v));
										}
									case CFloat(f): {
											key = parseExpr(ENumber(f));
										}
									case _:
                                        
								} 
                            
                            
                        	exps.push(key);
                    		parseExprList(exps);
							//parseComplexExpr(null);
							switch stream {
								case [{tok:PClose}]:{
									//ex = parseExpr(ex);
									exps;
								}
								case _:{
									throw "Parse error: expected ')'";
								};
							};
                    		//exps;
                        
						};
						case [_ => v]:{
                            null;
                        }
					}
                    
					
				};
			case [{tok: Comma}]:
				{
					exps.push(parseExpr());
					parseExprList(exps);
					exps;
				};
			case _:
		});
	}

	function parseAttrGetExpr(ident:RuleExpr):RuleExpr {
        var key = null;
		return parse(switch stream {
			case [{tok: BkOpen}]:
				{
					switch stream {
						case [{tok: Const(c)}]:
							{
                                
								switch c {
									case CIdent(s): {
											key = parseExpr(EIdent(s));
                                           
										}
									case CInt(v): {
											key = parseExpr(ENumber(v));
										}
									case CFloat(f): {
											key = parseExpr(ENumber(f));
										}
									case _:
                                        
								} 
                            switch stream {
                                case [{tok:BkClose}]:{}
                                case _:
                                    throw "Parse error: expected ']'";
                            }
                            
                            EAttrGet(ident, key);
                        
						};
						case [_ => v]:{
                            null;
                        }
					}
				};
            case [{tok: Const(c)}]:
							{
								switch c {
									case CIdent(s): {
											key = parseExpr(EIdent(s));
										}
									case CInt(v): {
											key = parseExpr(ENumber(v));
										}
									case CFloat(f): {
											key = parseExpr(ENumber(f));
										}
									case _:
                                        
								} 
                            switch stream {
                                case [{tok:BkClose}]:{}
                                case _:
                                    throw "Parse error: expected ']'";
                            }
                            
                            parseComplexExpr(EAttrGet(ident, key));
                        
						};
			case _:
                null;
                
				
		});
	}

	function parseBinopExpr(e:RuleExpr, tok:TokenDef):RuleExpr {
					return switch tok {
						case Binop(op):
							{
                              return switch op {
                                  case OpAdd | OpMult | OpSub | OpDiv:{
                                        var val = null;
                                        parse(switch stream {
                                            case [{tok: Const(c)}]:
                                                {
                                                    switch c {
                                                        case CIdent(s): {
                                                                val = parseComplexExpr(EIdent(s));
                                                            }
                                                        case CInt(v): {
                                                               
                                                                val = parseExpr(ENumber(v));
                                                            }
                                                        case CFloat(f): {
                                                                val = parseExpr(ENumber(f));
                                                            }
                                                        case _:
                                                            
                                                    } 
													
                                                   var ex = parseComplexExpr(EArithmeticOp(e, val, Std.string(op)));
												  
												   ex;
												
                                            };
                                            case [_ => v]:
                                                switch v {
                                                    case {tok: Binop(op)}:{
                                                        parseBinopExpr(e, tok);
                                                    };
                                                    case _:
                                                        null;
                                                }       
                                        });
                                  };
                                  case _:
                                    null;
                              }
							};
						case _:
							null;
					}
	}

	function parseTableExpr(e:RuleExpr):RuleExpr {
		return null;
	}

	// function parseParentExpr(e:RuleExpr):RuleExpr {
    //     trace(e);
	// 	return parse(switch stream {
	// 		case [{tok: PClose}]:
	// 			{
	// 				e;
	// 			};
	// 		case _:
	// 	});
	// }
	// function parseArithOpExpr():RuleExpr{
	//     return parse(switch stream {
	//         case [{tok:Binop(op)}]:{
	//         }
	//         case _:
	//     });
	// }
}
