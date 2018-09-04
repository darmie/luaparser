package xlua.ast;

class RelationalOpExpr extends ExprBase {
 	public var operator:String;
	public var lhs:Expr;
	public var rhs:Expr;
}