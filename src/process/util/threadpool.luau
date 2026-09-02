const free_threads: { thread } = {}

const function run<T...>(f: (T...) -> (), thread: thread, ...)
	f(...)
	table.insert(free_threads, thread)
end

const function yielder()
	while true do
		(run :: any)(coroutine.yield())
	end
end

const function spawn<T...>(f: (T...) -> ...any, ...: T...): thread
	local thread
	if #free_threads > 0 then
		thread = free_threads[#free_threads]
		free_threads[#free_threads] = nil
	else
		thread = coroutine.create(yielder)
		coroutine.resume(thread)
	end

	return task.spawn(thread, f, thread, ...)
end

const function spawn_callbacks<Args...>(callbacks: { (Args...) -> ...any }, ...: Args...)
	for _, callback in callbacks do
		spawn(callback, ...)
	end
end

return {
	spawn = spawn,
	spawn_callbacks = spawn_callbacks,
}
