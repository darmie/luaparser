package xlua.ast;

class LogicalOpExpr extends ExprBase {
 	public var operator:String;
	public var lhs:Expr;
	public var rhs:Expr;
}