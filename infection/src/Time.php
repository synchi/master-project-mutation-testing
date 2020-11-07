<?php
namespace Infection;

class Time {
    public static function logTime($label, $nanoStart, $nanoEnd) {
        $milliDiff = (int)(($nanoEnd - $nanoStart) / 1000000);
        $days = (int)($milliDiff / (1000*60*60*24));
        $hourminsec = gmdate("H:i:s.", (int)($milliDiff / 1000));
        $milliRemainder = $milliDiff % 1000;

        $log = $days . "-" . $hourminsec . sprintf('%03d', $milliRemainder) . " = " . $milliDiff . " ms";
        echo "\n\n$label: $log \n";
    }
}

?>