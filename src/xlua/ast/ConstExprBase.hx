package xlua.ast;

class ConstExprBase implements ConstExpr {

	private var _line:Int;
	private var _lastline:Int;

    public function new(){}

    public function line():Int {
        return _line;
    }

    public function setLine(line:Int):Void {
        this._line = line;
    }

    public function lastLine():Int {
        return _lastline;
    }

    public function setLastLine(line:Int) {
        this._lastline = line;
    }   

    private function exprMarker():Void {}

    private function constExprMarker():Void {}
}