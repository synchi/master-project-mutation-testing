<?php
/**
 * This code is licensed under the BSD 3-Clause License.
 *
 * Copyright (c) 2017, Maks Rafalko
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 *
 * * Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

declare(strict_types=1);

namespace Infection;

use Infection\Mutation\Mutation;
use Infection\PhpParser\MutatedNode;
use PhpParser\Node\Stmt;
use PhpParser\Node\Stmt\ClassMethod;
use function explode;
use Infection\AbstractTestFramework\TestFrameworkAdapter;
use Infection\Configuration\Configuration;
use Infection\Console\ConsoleOutput;
use Infection\Event\ApplicationExecutionWasFinished;
use Infection\Event\EventDispatcher\EventDispatcher;
use Infection\Metrics\MetricsCalculator;
use Infection\Metrics\MinMsiChecker;
use Infection\Metrics\MinMsiCheckFailed;
use Infection\Mutation\MutationGenerator;
use Infection\PhpParser\Visitor\IgnoreNode\NodeIgnorer;
use Infection\Process\Runner\InitialTestsFailed;
use Infection\Process\Runner\InitialTestsRunner;
use Infection\Process\Runner\MutationTestingRunner;
use Infection\Resource\Memory\MemoryLimiter;
use Infection\TestFramework\Coverage\CoverageChecker;
use Infection\TestFramework\IgnoresAdditionalNodes;
use Infection\TestFramework\ProvidesInitialRunOnlyOptions;
use Infection\TestFramework\TestFrameworkExtraOptionsFilter;
use Infection\Time;

/**
 * @internal
 */
final class Engine
{
    private Configuration $config;
    private TestFrameworkAdapter $adapter;
    private CoverageChecker $coverageChecker;
    private EventDispatcher $eventDispatcher;
    private InitialTestsRunner $initialTestsRunner;
    private MemoryLimiter $memoryLimiter;
    private MutationGenerator $mutationGenerator;
    private MutationTestingRunner $mutationTestingRunner;
    private MinMsiChecker $minMsiChecker;
    private ConsoleOutput $consoleOutput;
    private MetricsCalculator $metricsCalculator;
    private TestFrameworkExtraOptionsFilter $testFrameworkExtraOptionsFilter;

    public static array $featuresMap = [];

    public function __construct(
        Configuration $config,
        TestFrameworkAdapter $adapter,
        CoverageChecker $coverageChecker,
        EventDispatcher $eventDispatcher,
        InitialTestsRunner $initialTestsRunner,
        MemoryLimiter $memoryLimiter,
        MutationGenerator $mutationGenerator,
        MutationTestingRunner $mutationTestingRunner,
        MinMsiChecker $minMsiChecker,
        ConsoleOutput $consoleOutput,
        MetricsCalculator $metricsCalculator,
        TestFrameworkExtraOptionsFilter $testFrameworkExtraOptionsFilter
    ) {
        $this->config = $config;
        $this->adapter = $adapter;
        $this->coverageChecker = $coverageChecker;
        $this->eventDispatcher = $eventDispatcher;
        $this->initialTestsRunner = $initialTestsRunner;
        $this->memoryLimiter = $memoryLimiter;
        $this->mutationGenerator = $mutationGenerator;
        $this->mutationTestingRunner = $mutationTestingRunner;
        $this->minMsiChecker = $minMsiChecker;
        $this->consoleOutput = $consoleOutput;
        $this->metricsCalculator = $metricsCalculator;
        $this->testFrameworkExtraOptionsFilter = $testFrameworkExtraOptionsFilter;
    }

    /**
     * @throws InitialTestsFailed
     * @throws MinMsiCheckFailed
     */
    public function execute(): void
    {
        $nanoStart = hrtime(true);

        $this->runInitialTestSuite();
        $this->runMutationAnalysis();

        $this->minMsiChecker->checkMetrics(
            $this->metricsCalculator->getTestedMutantsCount(),
            $this->metricsCalculator->getMutationScoreIndicator(),
            $this->metricsCalculator->getCoveredCodeMutationScoreIndicator(),
            $this->consoleOutput
        );

        $this->eventDispatcher->dispatch(new ApplicationExecutionWasFinished());

        $nanoEnd = hrtime(true);

        Time::logTime("Total runtime", $nanoStart, $nanoEnd);
    }

    private function runInitialTestSuite(): void
    {
        if ($this->config->shouldSkipInitialTests()) {
            $this->consoleOutput->logSkippingInitialTests();
            $this->coverageChecker->checkCoverageExists();

            return;
        }

        $initialTestSuiteProcess = $this->initialTestsRunner->run(
            $this->config->getTestFrameworkExtraOptions(),
            $this->getInitialTestsPhpOptionsArray(),
            $this->config->shouldSkipCoverage()
        );

        if (!$initialTestSuiteProcess->isSuccessful()) {
            throw InitialTestsFailed::fromProcessAndAdapter($initialTestSuiteProcess, $this->adapter);
        }

        $this->coverageChecker->checkCoverageHasBeenGenerated(
            $initialTestSuiteProcess->getCommandLine(),
            $initialTestSuiteProcess->getOutput()
        );

        /*
         * Limit the memory used for the mutation processes based on the memory
         * used for the initial test run.
         */
        $this->memoryLimiter->limitMemory($initialTestSuiteProcess->getOutput(), $this->adapter);
    }

    /**
     * @return string[]
     */
    private function getInitialTestsPhpOptionsArray(): array
    {
        return explode(' ', (string) $this->config->getInitialTestsPhpOptions());
    }

    private function runMutationAnalysis(): void
    {
        // SARA
        /** @var \Traversable $mutations */
        $mutations = $this->mutationGenerator->generate(
            $this->config->mutateOnlyCoveredCode(),
            $this->getNodeIgnorers()
        );

        $muCounter = [];

        $copyMutations = [];

        /** @var Mutation $m */
        foreach ($mutations as $m) {
            $copyMutations[] = $m;
            $location = $m->getOriginalFilePath() . ":" . $m->getOriginalStartingLine();
            if(isset($muCounter[$location])) {
                $muCounter[$location]++;
            } else {
                $muCounter[$location] = 1;
            }
        }



        /** @var Mutation $mutant */
        foreach ($copyMutations as $mutant) {
            $location = $mutant->getOriginalFilePath() . ":" . $mutant->getOriginalStartingLine();
            $features = new Features($location);

            $operator = $mutant->getMutatorName();

            $features->setMutOperator($operator);
            $features->setNumTests(count($mutant->getAllTests()));
            $features->setLineNum($mutant->getOriginalStartingLine());
            $features->setNumMutStmt($muCounter[$location] ?? 0);
            $features->setNodeType($mutant->getMutatedNodeClass());


            // Extract function info
            /** @var ClassMethod $scope */
            $unwrap = $mutant->getMutatedNode()->unwrap();
            $node = is_array($unwrap) ? $unwrap[0] : $unwrap;
            $scope = $node->getAttributes()['functionScope'] ?? null;

            if($scope) {
                $features->setRetByRef($scope->returnsByRef() ? 1 : 0);
                $features->setMetParaCount(count($scope->getParams()));
                $features->setReturnType($scope->getReturnType() ?: 'none');
                $features->setMetStmtTotal(count($scope->getStmts()));
                $features->setMetMagic(method_exists($scope, 'isMagic') && $scope->isMagic() ? 1 : 0);

                $tryCatchCount = 0;
                $stmtIdx = -1;
                foreach($scope->getStmts() as $statement) {
                    $stmtIdx++;
                    $sType = get_class($statement);
                    $sLine = $statement->getStartLine();
                    $mLine = $features->getLineNum();

                    if(str_contains($sType, "TryCatch")) {
                        $tryCatchCount++;
                    }

                    if($sLine == $mLine) {
                        $features->setStmtType($sType);
                        $features->setMetStmtIdx($stmtIdx);
                    }
                }
                $lastStmtIdx = $stmtIdx;
                $features->setMetStmtSucc($lastStmtIdx - $stmtIdx);
                $features->setTryCatch($tryCatchCount);

            }
            self::$featuresMap["$location.$operator"] = $features;
        }

       $nanoStartRun = hrtime(true);

        $this->mutationTestingRunner->run(
            $copyMutations,
            $this->getFilteredExtraOptionsForMutant()
        );

        $nanoEndRun = hrtime(true);
        Time::logTime("Runmutes", $nanoStartRun, $nanoEndRun);

        Features::printHeader();
        /** @var Features $f */
        foreach (self::$featuresMap as $f) {
            $f->printRow();
        }
    }

    /**
     * @return NodeIgnorer[]
     */
    private function getNodeIgnorers(): array
    {
        if ($this->adapter instanceof IgnoresAdditionalNodes) {
            return $this->adapter->getNodeIgnorers();
        }

        return [];
    }

    private function getFilteredExtraOptionsForMutant(): string
    {
        if ($this->adapter instanceof ProvidesInitialRunOnlyOptions) {
            return $this->testFrameworkExtraOptionsFilter->filterForMutantProcess(
                $this->config->getTestFrameworkExtraOptions(),
                $this->adapter->getInitialRunOnlyOptions()
            );
        }

        return $this->config->getTestFrameworkExtraOptions();
    }
}
