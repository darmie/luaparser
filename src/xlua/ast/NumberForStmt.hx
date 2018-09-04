package xlua.ast;

class NumberForStmt extends StmtBase {
	public var name:String;
	public var init:Expr;
	public var limit:Expr;
	public var step:Expr;
	public var stmts:Array<Stmt>; 
}