package xlua.ast;

class ArithmeticOpExpr extends ExprBase {
 	public var operator:String;
	public var lhs:Expr;
	public var rhs:Expr;    
}