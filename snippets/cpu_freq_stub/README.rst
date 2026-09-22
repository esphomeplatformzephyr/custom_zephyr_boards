cpu_freq_stub snippet
######################

Adds a synthetic ``performance-states`` node so Zephyr's CPU Frequency
Scaling subsystem (``subsys/cpu_freq``) has P-states to select between.

No board ESPHome currently targets has a real ``cpu_freq`` driver
(``HAS_CPU_FREQ``), so ``CPU_FREQ_PSTATE_SET`` falls back to its stub
setter: policy decisions run and log, but no frequency change is ever
actually applied.

Test-only. Mirrors Zephyr's own
``samples/subsys/cpu_freq/on_demand/pstate-stub.overlay``.
