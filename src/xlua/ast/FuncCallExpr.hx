package xlua.ast;

class FuncCallExpr extends ExprBase {
    public var func:Expr;
    public var receiver:Expr;
    public var method:String;
    public var args:Array<Expr>;
    public var adjustRet:Bool;
}