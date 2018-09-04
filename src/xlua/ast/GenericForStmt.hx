package xlua.ast;

class GenericForStmt extends StmtBase {
	public var names:Array<String>;
	public var exprs:Array<Expr>;
	public var stmts:Array<Stmt>;  
}