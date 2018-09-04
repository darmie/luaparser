package xlua.ast;

interface PositionHolder {
    public function line():Int;
    public function setLine(line:Int):Void;
    public function lastLine():Int;
    public function setLastLine(line:Int):Void;
}