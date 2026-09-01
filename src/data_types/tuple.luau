const types = require("../types")

type DT<T...> = types.DataType<T...>

type TupleFn =
	(<A>(DT<A>) -> DT<A>)
	& (<A, B>(DT<A>, DT<B>) -> DT<A, B>)
	& (<A, B, C>(DT<A>, DT<B>, DT<C>) -> DT<A, B, C>)
	& (<A, B, C, D>(DT<A>, DT<B>, DT<C>, DT<D>) -> DT<A, B, C, D>)
	& (<A, B, C, D, E>(DT<A>, DT<B>, DT<C>, DT<D>, DT<E>) -> DT<A, B, C, D, E>)
	& (<A, B, C, D, E, F>(DT<A>, DT<B>, DT<C>, DT<D>, DT<E>, DT<F>) -> DT<A, B, C, D, E, F>)
	& (<A, B, C, D, E, F, G>(DT<A>, DT<B>, DT<C>, DT<D>, DT<E>, DT<F>, DT<G>) -> DT<A, B, C, D, E, F, G>)
	& (<A, B, C, D, E, F, G, H>(DT<A>, DT<B>, DT<C>, DT<D>, DT<E>, DT<F>, DT<G>, DT<H>) -> DT<A, B, C, D, E, F, G, H>)
	& (<A, B, C, D, E, F, G, H, I>(
		DT<A>,
		DT<B>,
		DT<C>,
		DT<D>,
		DT<E>,
		DT<F>,
		DT<G>,
		DT<H>,
		DT<I>
	) -> DT<A, B, C, D, E, F, G, H, I>)
	& (<A, B, C, D, E, F, G, H, I, J>(
		DT<A>,
		DT<B>,
		DT<C>,
		DT<D>,
		DT<E>,
		DT<F>,
		DT<G>,
		DT<H>,
		DT<I>,
		DT<J>
	) -> DT<A, B, C, D, E, F, G, H, I, J>)
	& ((...DT<any>) -> DT<...any>)

const function tuple(...: DT<any>): DT<any>
	const definition = { ... }
	const count = #definition
	if count == 1 then
		return definition[1]
	end

	return {
		write = @native function(ctx, ...)
			for i = 1, count do
				definition[i].write(ctx, select(i, ...))
			end
		end,
		read = @native function(ctx)
			const results = table.create(count)
			for i = 1, count do
				results[i] = definition[i].read(ctx)
			end
			return table.unpack(results, 1, count)
		end,
	}
end

return tuple :: TupleFn
