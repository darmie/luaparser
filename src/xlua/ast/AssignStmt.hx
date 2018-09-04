package xlua.ast;

class AssignStmt extends StmtBase {
    public function new(){
        super();
    }
    public var lhs:Array<Expr>;
    public var rhs:Array<Expr>;
}