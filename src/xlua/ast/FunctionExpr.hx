package xlua.ast;

class FunctionExpr extends ExprBase {
    public var parList:ParList;
    public var stmts:Array<Stmt>;
}