package xlua;

import haxe.macro.Expr;

enum Keyword {
    KwdFunction;
    KwdAnd;
    KwdDo;
    KwdBreak;
    KwdElse;
    KwdIf;
    KwdElseif;
    KwdTrue;
    KwdFalse;
    KwdLocal;
    KwdNil;
    KwdNot;
    KwdOr;
    KwdThen;
    KwdReturn;
    KwdRepeat;
    KwdFor;
    KwdWhile;
    KwdUntil;
    KwdIn;
    KwdEnd;
}

class KeywordPrinter {
    static public function toString(kwd:Keyword) {
        return switch(kwd){
            case KwdFunction: "function";
            case KwdAnd: "and";
            case KwdDo: "do";
            case KwdBreak: "break";
            case KwdElse: "else";
            case KwdIf: "if";
            case KwdElseif: "elseif";
            case KwdTrue: "true";
            case KwdFalse: "false";
            case KwdLocal: "local";
            case KwdNil: "nil";
            case KwdNot: "not";
            case KwdOr: "or";
            case KwdThen: "then";
            case KwdReturn: "return";
            case KwdRepeat: "repeat";
            case KwdFor: "for";
            case KwdWhile: "while";
            case KwdUntil: "until";
            case KwdIn: "in";
            case KwdEnd: "end";           
        }
    }
}


enum TokenDef {
    Kwd(k:Keyword);
    Const(c:haxe.macro.Expr.Constant);
    Binop(op:haxe.macro.Expr.Binop);
    Unop(op:haxe.macro.Expr.Unop);
    Sharp(s:String);
    Comma;
    Comment(s:String);
	CommentLine(s:String);
	BkOpen;
	BkClose;
	BrOpen;
	BrClose;
	POpen;
	PClose;
    Dot;
    Col;
    TriplDot;
    StrConcat;
    Eof;
}


class TokenDefPrinter {
	static public function toString(def:TokenDef) {
		return switch(def) {
			case Kwd(k): k.getName().substr(3).toLowerCase();
            case Const(CInt(s) | CFloat(s) | CIdent(s)): s;
            case Const(CString(s)): '"$s"';
            case Const(CRegexp(r, opt)): '';
            case Comment(s): '--[$s--]';
            case CommentLine(s): '--$s';
			case Unop(op): new haxe.macro.Printer("").printUnop(op);
			case Binop(op): new haxe.macro.Printer("").printBinop(op);
            case Sharp(s): '#$s';
			case Dot: ".";
			case Col: ":";
            case TriplDot: "...";
            case StrConcat: "..";
			case Comma: ",";
			case BkOpen: "[";
			case BkClose: "]";
			case BrOpen: "{";
			case BrClose: "}";
			case POpen: "(";
			case PClose: ")";
			case Eof: "<eof>";
		}
	}
}



class Token {
	public var tok: TokenDef;
	public var pos: Dynamic;
	#if keep_whitespace
	public var space = "";
	#end
	public function new(tok, pos) {
		this.tok = tok;
		this.pos = pos;
	}

	public function toString() {
		return TokenDefPrinter.toString(tok);
	}
}


// Statement Rules
enum RuleStat {
    SBlock(stmts:Array<RuleStat>);
    SParenthesis(e:Array<RuleExpr>);
    SAssign(lhs:Array<RuleExpr>, rhs:Array<RuleExpr>);
    SLocalAssign(names:Array<RuleExpr>, exprs:Array<RuleExpr>);
    SFunctionCall(e:RuleExpr);
    SWhile(condition:RuleExpr, stmts:Array<RuleStat>);
    SGenericFor(names:Array<String>, exprs:Array<RuleExpr>, stmts:Array<RuleStat>);
    SNumberFor(names:Array<String>, init:RuleExpr, limit:RuleExpr, step:RuleExpr, stmts:Array<RuleStat>);
    SFunctionDef(name:String, func:RuleExpr);
    SFunctionName(func:RuleExpr, receiver:RuleExpr, method:String);
    SRepeat(condition:RuleExpr, stmts:Array<RuleStat>);
    SIfThen(condition:RuleExpr, then:Array<RuleStat>, _else:Array<RuleStat>);
    SReturn(exprs:Array<RuleExpr>);
    SDoBlock(stmts:Array<RuleStat>);
    STable(table:RuleExpr);
    SBreak;
    SEnd;
}

typedef Field = {
	key:Dynamic,
	value:RuleExpr
}

// Expression Rules
enum RuleExpr {
    ENil;
    EFalse;
    ETrue;
    ENumber(value:String);
    EString(value:String);
    EFunction(params:Array<RuleExpr>, hasVargs:Bool, block:Array<RuleStat>);
    EFunctionCall(func:RuleExpr, receiver:RuleExpr, method:RuleExpr, args:Array<RuleExpr>, adjustRet:Bool);
    ETable(fields:Array<Field>);
    ETableConstr(fields:Array<Field>);
    ETrippleDot;
    EUnopNot(e:RuleExpr);
    EUnopMinus(e:RuleExpr);
    EUnopLen(e:RuleExpr);
    ELogicalOp(lhs:RuleExpr, rhs:RuleExpr, op:String);
    EArithmeticOp(lhs:RuleExpr, rhs:RuleExpr, op:String);
    EAttrGet(object:RuleExpr, key:Expr);
    EIdent(value:String);
    EStringConcat(lhs:RuleExpr, rhs:RuleExpr);
}


class Data {}