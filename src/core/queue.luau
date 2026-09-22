type Entry = {
	value: any,
	next: Entry?,
}

export type Queue = {
	head: Entry?,
	tail: Entry?,
}

local function create(): Queue
	return {
		head = nil,
		tail = nil,
	}
end

local function pop(queue: Queue): any
	local head = queue.head
	if head == nil then
		return
	end

	queue.head = head.next
	return head.value
end

local function push(queue: Queue, value: any)
	local entry: Entry = {
		value = value,
		next = nil,
	}

	if queue.tail ~= nil then
		queue.tail.next = entry
	end

	queue.tail = entry

	if queue.head == nil then
		queue.head = entry
	end
end

return {
	create = create,
	pop = pop,
	push = push,
}
