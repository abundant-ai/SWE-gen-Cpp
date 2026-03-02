Crow applications are not independent from each other when multiple app instances exist in the same process. The cause is that the timer mechanism used for scheduling connection-related timeouts (used by the HTTP server/connection code and by the app) relies on shared global/static state, so one app’s timer ticks influence another app’s scheduled tasks.

When two separate app/server instances are running concurrently, timers and timeouts should be isolated per app instance. Currently, time-based tasks can execute earlier/later than intended (or be delayed) because all instances share the same tick delay and scheduling loop.

Replace the existing timer queue with a per-instance timer component called `task_timer` and update the server/app/connection code to use it. The new timer must:

- Be instantiable per app/server so there is no global/static tick shared across instances.
- Support scheduling tasks with a custom timeout per scheduled task (instead of using one fixed global tick/timeout).
- Own/encapsulate the IO service / event-loop integration needed to execute scheduled tasks, rather than requiring external code to manage that timer IO logic.
- Provide an API equivalent to what the server/connection code needs for scheduling and canceling timeouts.

After the change, running multiple apps in the same process must no longer cause timer-driven behavior in one app to affect the other. Timeouts for keep-alive connections and other scheduled tasks must be determined by the timeout passed when scheduling, not by a single shared global delay.

This work is also intended to lay groundwork for supporting HTTP `Keep-Alive` parameters such as `timeout` and `max`, so the timer should be able to represent per-connection/per-task timeout values accurately.