spdlog’s registry currently supports modifying existing loggers via spdlog::apply_all(...), but there is no way to react when new loggers are registered after the application’s initial setup (e.g., loggers created by dynamically loaded plugins). As a result, applications that want to automatically redirect every newly created/registered logger (for example, by tweaking its sinks) must either call apply_all repeatedly or accept that late-registered loggers won’t be configured.

Add support for registering one or more callbacks that are invoked whenever a logger is registered with the spdlog registry. The API should allow users to add a callback (a callable receiving std::shared_ptr<spdlog::logger>) so that, after a logger becomes registered and retrievable via spdlog::get(name), the callback is called and can mutate the logger (e.g., update its sinks).

The new behavior must work for loggers registered through normal creation paths (e.g., spdlog::create<...>(name) and spdlog::register_logger(logger)). When a logger is dropped or all loggers are dropped, subsequent callbacks should only run for future registrations (dropping should not itself trigger callbacks). Multiple callbacks may be added and should all be invoked for each newly registered logger.

Example desired usage:

auto cb = [](std::shared_ptr<spdlog::logger> l) {
    // customize sinks/levels/etc for any newly registered logger
};
spdlog::registry::instance().add_logger_register_callback(cb);

After this, if a plugin later calls spdlog::create<...>("plugin_logger"), the callback must run for that logger registration.

Ensure existing registry behavior remains unchanged: registering duplicate logger names should still fail as before (throwing spdlog::spdlog_ex when exceptions are enabled), and spdlog::apply_all(...) should still iterate only currently registered loggers and reflect drop/drop_all correctly.