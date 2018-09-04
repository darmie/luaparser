package xlua.ast;

class ConditionalStmt extends StmtBase {
    public var condition:Expr;
	public var stmts:Array<Stmt>;  
}