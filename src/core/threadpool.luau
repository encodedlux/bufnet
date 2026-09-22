local free_threads: { thread } = {}

const function run<T...>(f: (T...) -> (), thread: thread, ...)
	f(...)
	table.insert(free_threads, thread)
end

const function yielder()
	while true do
		run(coroutine.yield())
	end
end

const function spawn<T...>(f: (T...) -> (), ...: T...)
	local thread
	if #free_threads > 0 then
		thread = free_threads[#free_threads]
		free_threads[#free_threads] = nil
	else
		thread = coroutine.create(yielder)
		coroutine.resume(thread)
	end

	task.spawn(thread, f, thread, ...)
end

const function spawn_callbacks<T...>(callbacks: { (T...) -> () }, ...: T...)
	for _, callback in callbacks do
		spawn(callback, ...)
	end
end

return {
	spawn = spawn,
	spawn_callbacks = spawn_callbacks,
}
