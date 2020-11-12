package org.pitest.mutationtest.tooling;

import org.pitest.mutationtest.DetectionStatus;
import org.pitest.mutationtest.build.CompoundMutationInterceptor;
import org.pitest.mutationtest.engine.MutationDetails;
import org.pitest.mutationtest.engine.MutationIdentifier;

public class Features {

    private final String mutOperator;
    private final int    numMutInstr;
    private final int    opcode;
    private final int    lineNum;
    private final int    blockNum;
    private final int    metInstrTotal;
    private final int    metInstrIdx;
    private final int    metInstrSucc;
    private final int    numTests;
    private final String returnType;
    private final int    localVars;
    private final int    tryCatch;

    private boolean detected;

    public Features(MutationDetails details) {
        // Extract mutation operator name
        String mutator = details.getMutator();
        String mutOperator = (mutator.substring(mutator.lastIndexOf(".") + 1));

        // Extract grouped number of mutants of the instruction
        MutationIdentifier id = details.getId();
        MutationIdentifier instr = new MutationIdentifier(id.getLocation(), id.getIndexes(), "");
        int numMutInstr = CompoundMutationInterceptor.mutantCounter.get(instr);

        this.mutOperator   = mutOperator;
        this.numMutInstr   = numMutInstr;
        this.opcode        = details.getOpcode();
        this.lineNum       = details.getLineNumber();
        this.blockNum      = details.getBlock();
        this.metInstrTotal = details.getTotalInstrMethod();
        this.metInstrIdx   = details.getFirstIndex();
        this.metInstrSucc  = this.metInstrTotal - this.metInstrIdx;
        this.numTests      = details.getTestsInOrder().size();
        this.returnType    = details.getReturnType();
        this.localVars     = details.getLocalVars();
        this.tryCatch      = details.getTryCatchBlocks();
    }

    public static void printHeader() {
        System.out.println("MutOperator,NumMutInstr,Opcode,LineNum,BlockNum,MetInstrTotal,MetInstrIdx,MetInstrSucc,NumTests,ReturnType,LocalVars,TryCatch,Detected");
    }

    public void printRow() {
        System.out.printf("%s,%d,%d,%d,%d,%d,%d,%d,%d,%s,%d,%d,%d\n",
                this.mutOperator,
                this.numMutInstr,
                this.opcode,
                this.lineNum,
                this.blockNum,
                this.metInstrTotal,
                this.metInstrIdx,
                this.metInstrSucc,
                this.numTests,
                this.returnType,
                this.localVars,
                this.tryCatch,
                this.detected ? 1 : 0
        );
    }

    public void setDetected(boolean detected) {
        this.detected = detected;
    }

    public boolean getDetected() {
        return detected;
    }
}
