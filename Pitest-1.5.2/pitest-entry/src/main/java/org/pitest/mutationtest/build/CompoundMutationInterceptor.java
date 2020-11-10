package org.pitest.mutationtest.build;

import static java.util.Comparator.comparing;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;

import org.objectweb.asm.tree.AbstractInsnNode;
import org.pitest.bytecode.analysis.ClassTree;
import org.pitest.bytecode.analysis.MethodTree;
import org.pitest.mutationtest.engine.Mutater;
import org.pitest.mutationtest.engine.MutationDetails;

public class CompoundMutationInterceptor implements MutationInterceptor {

  private final List<MutationInterceptor> children = new ArrayList<>();

  private ClassTree classTree;

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
    for(MutationDetails details : modified) {
      for(MethodTree methodTree : classTree.methods()) {
         if (methodTree.asLocation().equals(details.getId().getLocation())) {
           AbstractInsnNode instruction = methodTree.instruction(details.getInstructionIndex());
           details.setOpcode(instruction.getOpcode());
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
