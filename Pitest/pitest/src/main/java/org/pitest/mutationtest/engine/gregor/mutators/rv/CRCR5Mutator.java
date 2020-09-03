package org.pitest.mutationtest.engine.gregor.mutators.rv;


import org.objectweb.asm.MethodVisitor;
import org.pitest.mutationtest.engine.gregor.MethodInfo;
import org.pitest.mutationtest.engine.gregor.MethodMutatorFactory;
import org.pitest.mutationtest.engine.gregor.MutationContext;

/**
 * Mutator that replaces an inline constant with constant + 1
 * Does not mutate if precision would make the mutant equivalent;
 */
public enum CRCR5Mutator implements MethodMutatorFactory {

    CRCR_5_MUTATOR;

    private final class CRCRVisitor1 extends AbstractCRCRVisitor {

        CRCRVisitor1(final MutationContext context,
                     final MethodVisitor delegateVisitor) {
            super(context, delegateVisitor, CRCR5Mutator.this);
        }

        void mutate(final Double constant) {
            final Double replacement = constant + 1D;

            if ((! constant.equals(replacement)) && shouldMutate(constant, replacement)) {
                translateToByteCode(replacement);
            } else {
                translateToByteCode(constant);
            }
        }

        void mutate(final Float constant) {
            final Float replacement = constant + 1F;

            if ((! constant.equals(replacement)) && shouldMutate(constant, replacement)) {
                translateToByteCode(replacement);
            } else {
                translateToByteCode(constant);
            }
        }

        void mutate(final Integer constant) {
            final Integer replacement = constant + 1;

            if ((! constant.equals(replacement)) && shouldMutate(constant, replacement)) {
                translateToByteCode(replacement);
            } else {
                translateToByteCode(constant);
            }
        }

        void mutate(final Long constant) {
            final Long replacement = constant + 1L;

            if ((! constant.equals(replacement)) && shouldMutate(constant, replacement)) {
                translateToByteCode(replacement);
            } else {
                translateToByteCode(constant);
            }

        }
    }

    public MethodVisitor create(final MutationContext context,
                                final MethodInfo methodInfo, final MethodVisitor methodVisitor) {
        return new CRCRVisitor1(context, methodVisitor);
    }

    public String getGloballyUniqueId() {
        return this.getClass().getName();
    }

    public String getName() {
        return name();
    }

}