package org.pitest.mutationtest.build;

import static java.util.Comparator.comparing;

import java.util.*;

import org.objectweb.asm.Type;
import org.objectweb.asm.tree.AbstractInsnNode;
import org.pitest.bytecode.analysis.ClassTree;
import org.pitest.bytecode.analysis.MethodTree;
import org.pitest.mutationtest.engine.Mutater;
import org.pitest.mutationtest.engine.MutationDetails;
import org.pitest.mutationtest.engine.MutationIdentifier;

public class CompoundMutationInterceptor implements MutationInterceptor {

  private final List<MutationInterceptor> children = new ArrayList<>();

  private ClassTree classTree;

  public static HashMap<MutationIdentifier, Integer> mutantCounter = new HashMap<>();

  public CompoundMutationInterceptor(List<? extends MutationInterceptor> interceptors) {
    this.children.addAll(interceptors);
    this.children.sort(comparing(MutationInterceptor::type));
  }

  public static MutationInterceptor nullInterceptor() {
    return new CompoundMutationInterceptor(Collections.emptyList());
  }

  @Override
  public void begin(ClassTree clazz) {
    this.classTree = clazz;
    this.children.forEach(each -> each.begin(clazz));
  }

  @Override
  public Collection<MutationDetails> intercept(
      Collection<MutationDetails> mutations, Mutater m) {
    Collection<MutationDetails> modified = mutations;

    // Machine learning features collection [SARA]
    for(MutationDetails details : modified) {

      // Count mutations on instruction
      MutationIdentifier instr = new MutationIdentifier(details.getId().getLocation(), details.getId().getIndexes(), "");
      int count = mutantCounter.getOrDefault(instr, 0);
      mutantCounter.put(instr, count + 1);

      // Find method of this mutant
      for(MethodTree methodTree : classTree.methods()) {
         if (methodTree.asLocation().equals(details.getId().getLocation())) {
           AbstractInsnNode instruction = methodTree.instruction(details.getInstructionIndex());

           // Determine return type
           String signature = methodTree.rawNode().signature;
           String returnType = "none";
           if (signature != null) {
             int i = signature.lastIndexOf(")") + 1;
             returnType = (signature.substring(i, i+1));
           }

           details.setOpcode(instruction.getOpcode());
           details.setTotalInstrMethod(methodTree.instructions().size());
           details.setReturnType(returnType);
           details.setLocalVars(methodTree.rawNode().localVariables.size());
           details.setTryCatchBlocks(methodTree.rawNode().tryCatchBlocks.size());
         }
      }
    }

    for (final MutationInterceptor each : this.children) {
      modified = each.intercept(modified, m);
    }
    return modified;
  }

  @Override
  public void end() {
    this.children.forEach(MutationInterceptor::end);
  }

  @Override
  public InterceptorType type() {
    return InterceptorType.OTHER;
  }

}
