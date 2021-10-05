/**
 * UniswapPriceOracle class.
 *
 * @constructor
 * @param provider
 */

 	function UniswapPriceOracle (provider) {
		this.ethGetStorageAt = getStorageAtFactory(provider);
		this.ethGetBlockByNumber = getBlockByNumberFactory(provider);
  }

  UniswapPriceOracle.prototype.getTokenPrice = async function(uniPairAddress, denominationToken, blockNumber) {
		const getAccumulatorValue = async (innerBlockNumber, timestamp) => {
			const token0 = await this.ethGetStorageAt(uniPairAddress, 6n, innerBlockNumber)
			const token1 = await this.ethGetStorageAt(uniPairAddress, 7n, innerBlockNumber)
			const reservesAndTimestamp = await this.ethGetStorageAt(uniPairAddress, 8n, innerBlockNumber)
			const accumulator0 = await this.ethGetStorageAt(uniPairAddress, 9n, innerBlockNumber)
			const accumulator1 = await this.ethGetStorageAt(uniPairAddress, 10n, innerBlockNumber)
			const blockTimestampLast = reservesAndTimestamp >> (112n + 112n)
			const reserve1 = (reservesAndTimestamp >> 112n) & (2n**112n - 1n)
			const reserve0 = reservesAndTimestamp & (2n**112n - 1n)
			if (token0 !== denominationToken && token1 !== denominationToken) throw new Error(`Denomination token ${addressToString(denominationToken)} is not one of the tokens for exchange ${exchangeAddress}`)
			if (reserve0 === 0n) throw new Error(`Exchange ${addressToString(uniPairAddress)} does not have any reserves for token0.`)
			if (reserve1 === 0n) throw new Error(`Exchange ${addressToString(uniPairAddress)} does not have any reserves for token1.`)
			if (blockTimestampLast === 0n) throw new Error(`Exchange ${addressToString(uniPairAddress)} has not had its first accumulator update (or it is year 2106).`)
			if (accumulator0 === 0n) throw new Error(`Exchange ${addressToString(uniPairAddress)} has not had its first accumulator update (or it is 136 years since launch).`)
			if (accumulator1 === 0n) throw new Error(`Exchange ${addressToString(uniPairAddress)} has not had its first accumulator update (or it is 136 years since launch).`)
			const numeratorReserve = (token0 === denominationToken) ? reserve0 : reserve1
			const denominatorReserve = (token0 === denominationToken) ? reserve1 : reserve0
			const accumulator = (token0 === denominationToken) ? accumulator1 : accumulator0
			const timeElapsedSinceLastAccumulatorUpdate = timestamp - blockTimestampLast
			const priceNow = numeratorReserve * 2n**112n / denominatorReserve
			return accumulator + timeElapsedSinceLastAccumulatorUpdate * priceNow
		}

		const latestBlock = await this.ethGetBlockByNumber('latest')
		if (latestBlock === null) throw new Error(`Block 'latest' does not exist.`)
		const historicBlock = await this.ethGetBlockByNumber(blockNumber)
		if (historicBlock === null) throw new Error(`Block ${blockNumber} does not exist.`)
		const latestAccumulator = await getAccumulatorValue(latestBlock.number, latestBlock.timestamp)
		const historicAccumulator = await getAccumulatorValue(blockNumber, historicBlock.timestamp)
		const accumulatorDelta = latestAccumulator - historicAccumulator
		const timeDelta = latestBlock.timestamp - historicBlock.timestamp
		return accumulatorDelta / timeDelta
  };

	const getBlockByNumberFactory = (provider) =>{
		const requestProvider = normalizeProvider(provider)
		return async (blockNumber) => {
			const stringifiedBlockNumber = typeof blockNumber === 'bigint' ? `0x${blockNumber.toString(16)}` : blockNumber
			const block = await requestProvider.request('eth_getBlockByNumber', [stringifiedBlockNumber, false])
			assertPlainObject(block)
			assertProperty(block, 'parentHash', 'string')
			assertProperty(block, 'sha3Uncles', 'string')
			assertProperty(block, 'miner', 'string')
			assertProperty(block, 'stateRoot', 'string')
			assertProperty(block, 'transactionsRoot', 'string')
			assertProperty(block, 'receiptsRoot', 'string')
			assertProperty(block, 'logsBloom', 'string')
			assertProperty(block, 'difficulty', 'string')
			assertProperty(block, 'number', 'string')
			assertProperty(block, 'gasLimit', 'string')
			assertProperty(block, 'gasUsed', 'string')
			assertProperty(block, 'timestamp', 'string')
			assertProperty(block, 'extraData', 'string')
			assertProperty(block, 'mixHash', 'string')
			assertProperty(block, 'nonce', 'string')
			return {
				parentHash: stringToBigint(block.parentHash),
				sha3Uncles: stringToBigint(block.sha3Uncles),
				miner: stringToBigint(block.miner),
				stateRoot: stringToBigint(block.stateRoot),
				transactionsRoot: stringToBigint(block.transactionsRoot),
				receiptsRoot: stringToBigint(block.receiptsRoot),
				logsBloom: stringToBigint(block.logsBloom),
				difficulty: stringToBigint(block.difficulty),
				number: stringToBigint(block.number),
				gasLimit: stringToBigint(block.gasLimit),
				gasUsed: stringToBigint(block.gasUsed),
				timestamp: stringToBigint(block.timestamp),
				extraData: stringToByteArray(block.extraData),
				mixHash: stringToBigint(block.mixHash),
				nonce: stringToBigint(block.nonce),
			}
		}
	}

	const getStorageAtFactory = (provider) => {
		const requestProvider = normalizeProvider(provider)
		return async (address, position, block) => {
			const encodedAddress = bigintToHexAddress(address)
			const encodedPosition = bigintToHexQuantity(position)
			const encodedBlockTag = block === 'latest' ? 'latest' : bigintToHexQuantity(block)
			const result = await requestProvider.request('eth_getStorageAt', [encodedAddress, encodedPosition, encodedBlockTag])
			if (typeof result !== 'string') throw new Error(`Expected eth_getStorageAt to return a string but instead returned a ${typeof result}`)
			return stringToBigint(result)
		}
	}

	const normalizeProvider = (provider) => {
		if ('request' in provider) {
			return provider
		} else if('sendAsync' in provider) {
			return {
				request: async (method, params) => {
					return new Promise((resolve, reject) => {
						provider.sendAsync({ jsonrpc: '2.0', id: 1, method, params }, (error, response) => {
							if (error !== null && error !== undefined) return reject(unknownErrorToJsonRpcError(error, { request: { method, params } }))
							if (!isJsonRpcLike(response)) return reject(new Error(-32000, `Received something other than a JSON-RPC response from provider.sendAsync.`, { request: { method, params }, response}))
							if ('error' in response) return reject(new Error(response.error.code, response.error.message, response.error.data))
							return resolve(response.result)
						})
					})
				}
			}
		} else if ('send' in provider) {
			return {
				request: async (method, params) => provider.send(method, params)
			}
		} else {
			throw new Error(`expected an object with a 'request', 'sendAsync' or 'send' method on it but received ${JSON.stringify(provider)}`)
		}
	}

	const unknownErrorToJsonRpcError = (error, extraData) => {
		if (error instanceof Error) {
			// sketchy, but probably fine
			const mutableError = error
			mutableError.code = mutableError.code || -32603
			mutableError.data = mutableError.data || extraData
			if (isPlainObject(mutableError.data)) mergeIn(mutableError.data, extraData)
			return error
		}
		// if someone threw something besides an Error, wrap it up in an error
		return new Error(-32603, `Unexpected thrown value.`, mergeIn({ error }, extraData))
	}

	const mergeIn = (target, source) => {
		for (const key in source) {
			const targetValue = target[key]
			const sourceValue = source[key]
			if (targetValue === undefined || targetValue === null) {
				target[key] = sourceValue
			} else if (isPlainObject(targetValue) && isPlainObject(sourceValue)) {
				mergeIn(targetValue, sourceValue)
			} else {
				// drop source[key], don't want to override the target value
			}
		}
		return target
	}

	const isPlainObject = (maybe) =>{
		if (typeof maybe !== 'object') return false
		if (maybe === null) return false
		if (Array.isArray(maybe)) return false
		// classes can get complicated so don't try to merge them.  What does it mean to merge two Promises or two Dates?
		if (Object.getPrototypeOf(maybe) !== Object.prototype) return false
		return true
	}

	const assertPlainObject = (maybe) => {
		if (typeof maybe !== 'object') throw new Error(`Expected an object but received a ${typeof maybe}`)
		if (maybe === null) throw new Error(`Expected an object but received null.`)
		if (Array.isArray(maybe)) throw new Error(`Expected an object but received an array.`)
		if (Object.getPrototypeOf(maybe) !== Object.prototype) throw new Error(`Expected a plain object, but received a class instance.`)
	}

	const assertProperty = (maybe, propertyName, expectedPropertyType) => {
		if (!(propertyName in maybe)) throw new Error(`Object does not contain a ${propertyName} property.`)
		const propertyValue = maybe[propertyName]
		// CONSIDER: DRY with `assertType`
		if (expectedPropertyType === 'string' && typeof propertyValue === 'string') return
		if (expectedPropertyType === 'array' && Array.isArray(propertyValue)) return
		if (expectedPropertyType === 'object' && typeof propertyValue === 'object' && propertyValue !== null && !Array.isArray(propertyValue)) return
		throw new Error(`Object.${propertyName} is of type ${typeof propertyValue} instead of expected type ${expectedPropertyType}`)
	}

	const isJsonRpcLike = (maybe) =>{
		if (typeof maybe !== 'object') return false
		if (maybe === null) return false
		if ('error' in maybe) {
			if (!('code' in maybe)) return false
			if (typeof maybe.code !== 'number') return false
			if (!('message' in maybe)) return false
			if (typeof maybe.message !== 'string') return false
			return true
		}
		if ('result' in maybe) return true
		return false
	}

	const stringToBigint = (hex) => {
		const match = /^(?:0x)?([a-fA-F0-9]*)$/.exec(hex)
		if (match === null) throw new Error(`Expected a hex string encoded number with an optional '0x' prefix but received ${hex}`)
		const normalized = match[1]
		return BigInt(`0x${normalized}`)
	}

	const stringToByteArray = (hex) => {
		const match = /^(?:0x)?([a-fA-F0-9]*)$/.exec(hex)
		if (match === null) throw new Error(`Expected a hex string encoded byte array with an optional '0x' prefix but received ${hex}`)
		const normalized = match[1]
		if (normalized.length % 2) throw new Error(`Hex string encoded byte array must be an even number of charcaters long.`)
		const bytes = []
		for (let i = 0; i < normalized.length; i += 2) {
			bytes.push(Number.parseInt(`${normalized[i]}${normalized[i + 1]}`, 16))
		}
		return new Uint8Array(bytes)
	}

	const bigintToHexAddress = (value) => {
		return `0x${value.toString(16).padStart(40, '0')}`
	}

	const bigintToHexQuantity = (value) => {
		return `0x${value.toString(16)}`
	}

	const addressToString = (value) => {
		return `0x${value.toString(16).padStart(40, '0')}`
	}

	module.exports = { UniswapPriceOracle };


