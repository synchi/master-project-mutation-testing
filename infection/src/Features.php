<?php


namespace Infection;


/**
 * Class Features
 * @package Infection
 */
class Features
{
    private string $location;
    private string $mutOperator;
    private int $numMutStmt;
    private string $nodeType;
    private string $stmtType;
    private int $lineNum;
    private int $metStmtTotal;
    private int $metStmtIdx;
    private int $metStmtSucc;
    private int $numTests;
    private string $returnType;
    private int $tryCatch;
    private int $retByRef;
    private int $metParaCount;
    private int $metMagic;
    private int $detected;

    /**
     * Features constructor.
     * @param string $location
     */
    public function __construct(string $location)
    {
        $this->location = $location;

        // Default values
        $this->mutOperator  = "none";
        $this->numMutStmt   = 0;
        $this->stmtType     = "none";
        $this->lineNum      = 0;
        $this->metStmtTotal = 0;
        $this->metStmtIdx   = 0;
        $this->metStmtSucc  = 0;
        $this->numTests     = 0;
        $this->returnType   = "none";
        $this->tryCatch     = 0;
        $this->retByRef     = 0;
        $this->metParaCount = 0;
        $this->metMagic     = 0;
        $this->detected     = 0;
    }


    /**
     * @return string
     */
    public function getLocation(): string
    {
        return $this->location;
    }

    /**
     * @param string $location
     */
    public function setLocation(string $location): void
    {
        $this->location = $location;
    }

    /**
     * @return string
     */
    public function getMutOperator(): string
    {
        return $this->mutOperator;
    }

    /**
     * @param string $mutOperator
     */
    public function setMutOperator(string $mutOperator): void
    {
        $this->mutOperator = $mutOperator;
    }

    /**
     * @return int
     */
    public function getNumMutStmt(): int
    {
        return $this->numMutStmt;
    }

    /**
     * @param int $numMutStmt
     */
    public function setNumMutStmt(int $numMutStmt): void
    {
        $this->numMutStmt = $numMutStmt;
    }

    /**
     * @return string
     */
    public function getStmtType(): string
    {
        return $this->stmtType;
    }

    /**
     * @param string $stmtType
     */
    public function setStmtType(string $stmtType): void
    {
        $this->stmtType = $stmtType;
    }

    /**
     * @return int
     */
    public function getLineNum(): int
    {
        return $this->lineNum;
    }

    /**
     * @param int $lineNum
     */
    public function setLineNum(int $lineNum): void
    {
        $this->lineNum = $lineNum;
    }

    /**
     * @return int
     */
    public function getMetStmtTotal(): int
    {
        return $this->metStmtTotal;
    }

    /**
     * @param int $metStmtTotal
     */
    public function setMetStmtTotal(int $metStmtTotal): void
    {
        $this->metStmtTotal = $metStmtTotal;
    }

    /**
     * @return int
     */
    public function getMetStmtIdx(): int
    {
        return $this->metStmtIdx;
    }

    /**
     * @param int $metStmtIdx
     */
    public function setMetStmtIdx(int $metStmtIdx): void
    {
        $this->metStmtIdx = $metStmtIdx;
    }

    /**
     * @return int
     */
    public function getMetStmtSucc(): int
    {
        return $this->metStmtSucc;
    }

    /**
     * @param int $metStmtSucc
     */
    public function setMetStmtSucc(int $metStmtSucc): void
    {
        $this->metStmtSucc = $metStmtSucc;
    }

    /**
     * @return int
     */
    public function getNumTests(): int
    {
        return $this->numTests;
    }

    /**
     * @param int $numTests
     */
    public function setNumTests(int $numTests): void
    {
        $this->numTests = $numTests;
    }

    /**
     * @return string
     */
    public function getReturnType(): string
    {
        return $this->returnType;
    }

    /**
     * @param string $returnType
     */
    public function setReturnType(string $returnType): void
    {
        $this->returnType = $returnType;
    }

    /**
     * @return int
     */
    public function getTryCatch(): int
    {
        return $this->tryCatch;
    }

    /**
     * @param int $tryCatch
     */
    public function setTryCatch(int $tryCatch): void
    {
        $this->tryCatch = $tryCatch;
    }

    /**
     * @return int
     */
    public function getRetByRef(): int
    {
        return $this->retByRef;
    }

    /**
     * @param int $retByRef
     */
    public function setRetByRef(int $retByRef): void
    {
        $this->retByRef = $retByRef;
    }

    /**
     * @return int
     */
    public function getMetParaCount(): int
    {
        return $this->metParaCount;
    }

    /**
     * @param int $metParaCount
     */
    public function setMetParaCount(int $metParaCount): void
    {
        $this->metParaCount = $metParaCount;
    }

    public static function printHeader()
    {
        echo("Location,MutOperator,NumMutStmt,NodeType,StmtType,LineNum,MetStmtTotal,MetStmtIdx,MetStmtSucc,NumTests,ReturnType,TryCatch,RetByRef,MetParaCount,MetMagic\n");
    }

    public function printRow()
    {
        echo("$this->location,$this->mutOperator,$this->numMutStmt,$this->nodeType,$this->stmtType,$this->lineNum,$this->metStmtTotal,$this->metStmtIdx,$this->metStmtSucc,$this->numTests,$this->returnType,$this->tryCatch,$this->retByRef,$this->metParaCount,$this->metMagic\n");
    }

    /**
     * @return int
     */
    public function getMetMagic(): int
    {
        return $this->metMagic;
    }

    /**
     * @param int $metMagic
     */
    public function setMetMagic(int $metMagic): void
    {
        $this->metMagic = $metMagic;
    }

    /**
     * @return string
     */
    public function getNodeType(): string
    {
        return $this->nodeType;
    }

    /**
     * @param string $nodeType
     */
    public function setNodeType(string $nodeType): void
    {
        $this->nodeType = $nodeType;
    }

    /**
     * @return int
     */
    public function getDetected(): int
    {
        return $this->detected;
    }

    /**
     * @param int $detected
     */
    public function setDetected(int $detected): void
    {
        $this->detected = $detected;
    }
}
