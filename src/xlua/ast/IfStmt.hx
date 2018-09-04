package xlua.ast;

class IfStmt extends StmtBase {
    public function new(){
        super();
    }
    public var condition:Expr;
	public var then:Array<Stmt>;
    public var Else:Array<Stmt>;  
}