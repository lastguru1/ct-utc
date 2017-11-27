# Cryptotrader Universal Trading Constructor bot
# Copyright (c) 2017, Dmitry Golubev
# All rights reserved.
# 
# This software uses BSD 2-clause "Simplified" License: https://github.com/lastguru1/ct-utc/blob/master/LICENSE
# Although attribution is not required by the license, if you use this code in your software, please be nice.
# 
# Donations are always welcome. BTC: 1Gnv7zAm5pyhydheUzEuVRRT4BpCJASFsg, ETH: 0xB643711A58b0b84Ed317BA3E6Cf9BEFf91E27587
# 
# Newest version of the software is available here: https://github.com/lastguru1/ct-utc

talib = require "talib"
trading = require "trading"
params = require 'params'

# Strategy definition. If entered, all other options are ignored. Used for fast parameter reuse and sharing.
# STRATEGY = params.add 'Strategy definition', ''

# What data input to use for MAs that only take one input: Close Price or Weighted Close Price
DATA_INPUT = params.addOptions 'Data input', ['Close', 'Typical', 'Weighted'], 'Close'

# The following MAs can be used:
# SMA  - Simple Moving Average
# EMA - Exponential Moving Average
# WMA - Weighted Moving Average
# DEMA - Double Exponential Moving Average
# TEMA - Triple Exponential Moving Average
# TRIMA - Triangular Moving Average
# KAMA - Kaufman Adaptive Moving Average
# MAMA - MESA Adaptive Moving Average (parameters: fast limit (0..1, Ehlers used 0.5), slow limit (0..1, Ehlers used 0.05))
# FAMA - Following Adaptive Moving Average (parameters: fast limit (0..1, Ehlers used 0.5), slow limit (0..1, Ehlers used 0.05))
# T3 - Triple Exponential Moving Average (parameters: period, vFactor (0..1, default 0.7)
# HMA - Hull Moving Average
# EHMA - Exponential Hull Moving Average (same as HMA, but with EMA instead of WMA)
# ZLEMA - Zero-lag EMA
# HT - Hilbert Transform - Instantaneous Trendline
# Laguerre - Four Element Laguerre Filter (parameter: gamma (0..1, Ehlers used 0.8))
# FRAMA - Fractal Adaptive Moving Average (parameters: length, slow period)
# WRainbow - Weighted Rainbow Moving Average (similar to regular Rainbow MA, but with WMA as its base)
# EVWMA - Elastic Volume Weighted Moving Average

# Short MA. If you choose NONE, trading on crossings will be disabled
SHORT_MA_T = params.addOptions 'Short MA type', ['NONE', 'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'EHMA', 'ZLEMA', 'HT', 'Laguerre', 'FRAMA', 'WRainbow', 'VWMA', 'EVWMA'], 'EMA'
SHORT_MA_P = params.add 'Short MA period or parameters', '12'

# Long MA
LONG_MA_T = params.addOptions 'Long MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'EHMA', 'ZLEMA', 'HT', 'Laguerre', 'FRAMA', 'WRainbow', 'VWMA', 'EVWMA'], 'EMA'
LONG_MA_P = params.add 'Long MA period or parameters', '26'

# Feedback can be applied on the price data or MA used by MA calculations
# Feedback works like that:
# - calculate Feedback line using the given MA
# - calculate Short-Feedback delta
# - optionally: modify the delta using normalized volume information
# - add the resulting delta to the price data to be used by Short and/or Long MA later, or to the MA results
# The feedback can be modified (reduced) before being added
FEED_APPLY = params.addOptions 'Apply feedback to', ['Short MA price', 'Long MA price', 'Both prices', 'Short MA', 'Long MA', 'Both MA'], 'Long MA'
FEED_DELTA_T = params.addOptions 'Feedback reduction type (NONE disables this feedback)', ['NONE', 'Division', 'Root', 'Logarithm'], 'NONE'
FEED_DELTA_P = params.add 'Feedback reduction value', 1
FEED_MA_T = params.addOptions 'Feedback MA type', ['SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'EHMA', 'ZLEMA', 'HT', 'Laguerre', 'FRAMA', 'WRainbow', 'VWMA', 'EVWMA'], 'SMA'
FEED_MA_P = params.add 'Feedback MA period or parameters', '10'

# Volume normalization: Stochastic or Laguerre
# Volume is then normalized to (1-weight)..1 and serve as a multiplicator for the delta
FEED_VOLUME_T = params.addOptions 'Volume feedback normalization', ['NONE', 'Stochastic', 'Laguerre'], 'NONE'
FEED_VOLUME_P = params.add 'Volume feedback period (gamma (0..1) for Laguerre)', '14'
FEED_VOLUME_W = params.add 'Volume feedback weight (0..1)', 0.2

# MACD will calculate MA from the resulting ShortLongDelta (the result is MACD Signal line)
# MACD will act on the ShortLongDelta crossing MACD Signal line, instead of Zero line
MACD_MA_T = params.addOptions 'MACD MA type', ['NONE', 'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'EHMA', 'ZLEMA', 'HT', 'Laguerre', 'FRAMA', 'WRainbow', 'VWMA', 'EVWMA'], 'EMA'
MACD_MA_P = params.add 'MACD MA period or parameters', '9'

# High and low thresholds in percentage of the closing price
HI_THRESHOLD = params.add 'High threshold', 0.075
LO_THRESHOLD = params.add 'Low threshold', -0.05

# We can use crossings and/or oscillator to detect opportunities.
# Draw only - no oscillator trading - just draw it in the chart
# Regular - trade with oscillator signals
# Thresholds - same as Regular, but disables oscillator trade signals if MA delta is within the thresholds
# Zones - disallows buys if oscillator is high, and disallows sells if oscillator is low
# Reverse thresholds - if oscillator is outside its thresholds, allow buys or sells early - within the crossing thresholds
OSC_MODE = params.addOptions 'Oscillator mode', ['NONE', 'Draw only', 'Regular', 'Thresholds', 'Zones', 'Reverse thresholds'], 'NONE'

# We may want to smooth the data before making an oscillator
OSC_MAP_T = params.addOptions 'Oscillator preprocessing MA type', ['NONE', 'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'EHMA', 'ZLEMA', 'HT', 'Laguerre', 'FRAMA', 'WRainbow', 'VWMA', 'EVWMA'], 'NONE'
OSC_MAP_P = params.add 'Oscillator preprocessing MA period or parameters', '0'

# The following oscillators can be used:
# Stochastic - Stochastic oscillator
# RSI - Relative Strength Index
# MFI - Money Flow Index (same as RSI, but including volume data, so more responsive to large trades)
# LRSI - Laguerre Relative Strength Index (RSI with Four Element Laguerre Filter) (parameter: gamma (0..1, Ehlers used 0.5))
# LMFI - Laguerre Money Flow Index (MFI with Four Element Laguerre Filter) (parameter: gamma (0..1, Ehlers used 0.5))
# FT - Fisher Transform, compressed with Inverse Fisher Transformation (parameters: period, gamma (0..1, Ehlers used 0.33))
OSC_TYPE = params.addOptions 'Oscillator type', ['Stochastic', 'RSI', 'MFI', 'LRSI', 'LMFI', 'FT'], 'MFI'
OSC_THRESHOLD = params.add 'Oscillator cutoff', 20
OSC_PERIOD = params.add 'Oscillator period (gamma (0..1) for Laguerre)', '14'

# We may want to smooth the oscillator results a bit
OSC_MA_T = params.addOptions 'Oscillator MA type', ['NONE', 'SMA', 'EMA', 'WMA', 'DEMA', 'TEMA', 'TRIMA', 'KAMA', 'MAMA', 'FAMA', 'T3', 'HMA', 'EHMA', 'ZLEMA', 'HT', 'Laguerre', 'FRAMA', 'WRainbow', 'VWMA', 'EVWMA'], 'NONE'
OSC_MA_P = params.add 'Oscillator MA period or parameters', '0'

# Oscillator normalization: Stochastic or Inverse Fisher Transformation
OSC_NORM = params.addOptions 'Oscillator normalization', ['NONE', 'Stochastic', 'IFT'], 'NONE'

# What trigger to use for oscillator
# Early: trigger once crossed
# Extreme: trigger once change direction (provisional top/bottom) after crossing
# Late: trigger when back within the bounds after crossing
# NB: this has no effect if oscillator mode is "Zones"
OSC_TRIGGER = params.addOptions 'Oscillator trigger', ['Early', 'Extreme', 'Late', 'Buy early, sell late', 'Buy late, sell early'], 'Late'

# Which type of orders to use for trading
ORDER_TYPE = params.addOptions 'Order type', ['market', 'limit', 'iceberg'], 'limit'

# For limit orders, we will not get the ticker price, so we try to increase/decrease the price
ORDER_PRICE = params.add 'Trade at [Market Price x]', 1.003

# TODO: Check if Coppock curve (extremes only - not crossings; thresholds could be needed) is useful

REDUCE_BY = 1

LINIT = [0,0,0,0]
LGAMMA = 0
FRAMA_LEN = 0
FRAMA_SLOW = 0
FRAMA_PREV = 0
STOCH_LEN = 0
FT_LEN = 0
FT_GAMMA = 1
FT_PREV = 0
FT_V1 = 0
EV_LEN = 0
EV_PREV = 0
CURR_HI_THRESHOLD = 0
CURR_LO_THRESHOLD = 0

feedbackSign = (n) ->
	return Math.sign(n)

feedbackAdd = (n) ->
	return n + REDUCE_BY

feedbackDivide = (n) ->
	return n/REDUCE_BY

feedbackMultiply = (n) ->
	return n*REDUCE_BY

feedbackRoot = (n) ->
	return Math.sign(n) * Math.pow(Math.abs(n), 1/REDUCE_BY)

feedbackLog = (n) ->
	return Math.sign(n) * Math.log(Math.abs(n)) / Math.log(REDUCE_BY)

fixLength = (first, second) ->
	if first.length > second.length
		first = _.drop(first, first.length - second.length)
	if second.length > first.length
		second = _.drop(second, second.length - first.length)
	return [first, second]

EVWMA = (n, i, instrument) ->
	if i is 0
		EV_PREV = 0
	cumv = 0
	switch DATA_INPUT
		when 'Close'
			price = n.close
		when 'Typical'
			price = (n.close + n.low + n.high) / 3
		when 'Weighted'
			price = (n.close*2 + n.low + n.high) / 4
	if i < (EV_LEN - 1)
		flen = i + 1
	else
		flen = EV_LEN
	for x in [(i - flen + 1)..i]
		cumv = cumv + instrument[x].volume
	if cumv is 0
		cumv = 1
	evwma = (EV_PREV*(cumv-n.volume) + price*n.volume)/cumv
	EV_PREV = evwma
	return evwma

LaguerreMA = (n, i) ->
	if i is 0 then LINIT = [0,0,0,0]
	L0 = (1 - LGAMMA) * n + LGAMMA * LINIT[0]
	L1 = -LGAMMA * L0 + LINIT[0] + LGAMMA * LINIT[1]
	L2 = -LGAMMA * L1 + LINIT[1] + LGAMMA * LINIT[2]
	L3 = -LGAMMA * L2 + LINIT[2] + LGAMMA * LINIT[3]
	LINIT = [L0, L1, L2, L3]
	return (L0 + 2*L1 + 2*L2 + L3) / 6

LaguerreRSI = (n, i) ->
	if i is 0 then LINIT = [0,0,0,0]
	L0 = (1 - LGAMMA) * n + LGAMMA * LINIT[0]
	L1 = -LGAMMA * L0 + LINIT[0] + LGAMMA * LINIT[1]
	L2 = -LGAMMA * L1 + LINIT[1] + LGAMMA * LINIT[2]
	L3 = -LGAMMA * L2 + LINIT[2] + LGAMMA * LINIT[3]
	LINIT = [L0, L1, L2, L3]
	cu = 0
	cd = 0
	if L0 >= L1
		cu = L0 - L1
	else
		cd = L1 - L0
	if L1 >= L2
		cu = cu + L1 - L2
	else
		cd = cd + L2 - L1
	if L2 >= L3
		cu = cu + L2 - L3
	else
		cd = cd + L3 - L2
	if cu + cd is 0
		lrsi = 0
	else
		lrsi = 100 * cu / (cu + cd)
	return lrsi

Stochastic = (n, i, instrument) ->
	switch DATA_INPUT
		when 'Close'
			price = n.close
		when 'Typical'
			price = (n.close + n.low + n.high) / 3
		when 'Weighted'
			price = (n.close*2 + n.low + n.high) / 4
	if i < (STOCH_LEN - 1)
		slen = i + 1
	else
		slen = STOCH_LEN
	for x in [(i - slen + 1)..i]
		if not fh? or instrument[x].high > fh then fh = instrument[x].high
		if not fl? or instrument[x].low < fl then fl = instrument[x].low
	if not fh? or not fl? or (fh - fl) is 0
		sto = 0
	else
		sto = 100 * (price - fl) / (fh - fl)
	return sto

SimpleStochastic = (n, i, instrument) ->
	if i < (STOCH_LEN - 1)
		slen = i + 1
	else
		slen = STOCH_LEN
	for x in [(i - slen + 1)..i]
		if not fh? or instrument[x] > fh then fh = instrument[x]
		if not fl? or instrument[x] < fl then fl = instrument[x]
	if not fh? or not fl? or (fh - fl) is 0
		sto = 0
	else
		sto = 100 * (n - fl) / (fh - fl)
	return sto

IFT = (n) ->
	n = (n - 50) / 10
	ift = (Math.exp(2*n) - 1) / (Math.exp(2*n) + 1)
	ift = (ift + 1) * 50
	return ift

FT = (n, i, instrument) ->
	if i is 0
		FT_PREV = 0
		FT_V1 = 0
	switch DATA_INPUT
		when 'Close'
			price = n.close
		when 'Typical'
			price = (n.close + n.low + n.high) / 3
		when 'Weighted'
			price = (n.close*2 + n.low + n.high) / 4
	if i < (FT_LEN - 1)
		flen = i + 1
	else
		flen = FT_LEN
	for x in [(i - flen + 1)..i]
		if not fh? or instrument[x].high > fh then fh = instrument[x].high
		if not fl? or instrument[x].low < fl then fl = instrument[x].low
	if not fh? or not fl? or (fh - fl) is 0
		sto = 0
	else
		sto = (price - fl) / (fh - fl)
	value1 = FT_GAMMA * 2 * (sto - 0.5) + (1 - FT_GAMMA) * FT_V1
	if value1 > 0.99 then value1 = 0.999
	if value1 < -0.99 then value1 = -0.999
	FT_V1 = value1
	fish = 0.5 * Math.log((1 + value1) / (1 - value1)) + 0.5 * FT_PREV
	FT_PREV = fish
	fish = (Math.exp(2*fish) - 1) / (Math.exp(2*fish) + 1)
	fish = (fish + 1) * 50
	return fish

FRAMA = (n, i, instrument) ->
	switch DATA_INPUT
		when 'Close'
			price = n.close
		when 'Typical'
			price = (n.close + n.low + n.high) / 3
		when 'Weighted'
			price = (n.close*2 + n.low + n.high) / 4
	if i < (FRAMA_LEN - 1)
		FRAMA_PREV = price
		return price
	for x in [(i - FRAMA_LEN + 1)..i]
		if not fh? or instrument[x].high > fh then fh = instrument[x].high
		if not fl? or instrument[x].low < fl then fl = instrument[x].low
	n3 = (fh - fl) / FRAMA_LEN
	for x in [(i - FRAMA_LEN + 1)..(i - FRAMA_LEN / 2)]
		if not lh? or instrument[x].high > lh then lh = instrument[x].high
		if not ll? or instrument[x].low < ll then ll = instrument[x].low
	n1 = (lh - ll) / (FRAMA_LEN / 2)
	for x in [(i - FRAMA_LEN / 2 + 1)..i]
		if not hh? or instrument[x].high > hh then hh = instrument[x].high
		if not hl? or instrument[x].low < hl then hl = instrument[x].low
	n2 = (hh - hl) / (FRAMA_LEN / 2)
	if n1 > 0 and n2 > 0 and n3 > 0 then dimen=(Math.log(n1 + n2) - Math.log(n3)) / Math.log(2)
	w = Math.log(2/(FRAMA_SLOW + 1))
	alpha = Math.exp(w * (dimen - 1))
	if alpha < (2 / (FRAMA_SLOW + 1)) then alpha = 2 / (FRAMA_SLOW + 1)
	if alpha > 1 then alpha = 1
	filt = alpha * price + (1-alpha) * FRAMA_PREV
	FRAMA_PREV = filt
	return filt

sigRound = (n, sig) ->
	mult = Math.pow(10, sig - Math.floor(Math.log(n) / Math.LN10) - 1)
	Math.round(n * mult) / mult

processMA = (selector, period, instrument, secondary = false) ->
	if secondary
		sInstrument = ['low', 'high', 'close', 'volumes']
		sInstrument.low = instrument
		sInstrument.high = instrument
		sInstrument.close = instrument
		sInstrument.volumes = @data.instruments[0].volumes
		sInstrument.volumes = _.drop(sInstrument.volumes, sInstrument.volumes.length - sInstrument.high.length)
	else
		sInstrument = instrument
	
	switch DATA_INPUT
		when 'Close'
			sInput = sInstrument.close
		when 'Typical'
			sInput = talib.TYPPRICE
				high: sInstrument.high
				low: sInstrument.low
				close: sInstrument.close
				startIdx: 0
				endIdx: sInstrument.close.length-1
		when 'Weighted'
			sInput = talib.WCLPRICE
				high: sInstrument.high
				low: sInstrument.low
				close: sInstrument.close
				startIdx: 0
				endIdx: sInstrument.close.length-1
	
	switch selector
		when 'NONE'
			sInput
		when 'SMA'
			talib.SMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'EMA'
			talib.EMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'WMA'
			talib.WMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'DEMA'
			talib.DEMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'TEMA'
			talib.TEMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'TRIMA'
			talib.TRIMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'KAMA'
			talib.KAMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
		when 'MAMA'
			# MAMA Fast (0.5) and Slow (0.05) limits
			limits = "#{period}".split " "
			if limits[0]? and limits[0] < 1
				MAMA_FAST = limits[0]
			else
				MAMA_FAST = 0.5
			if limits[1]? and limits[1] < 1
				MAMA_SLOW = limits[1]
			else
				MAMA_SLOW = 0.05
			mama = talib.MAMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInFastLimit: MAMA_FAST
				optInSlowLimit: MAMA_SLOW
			mama.outMAMA
		when 'FAMA'
			# MAMA Fast (0.5) and Slow (0.05) limits
			limits = "#{period}".split " "
			if limits[0]? and limits[0] < 1
				MAMA_FAST = limits[0]
			else
				MAMA_FAST = 0.5
			if limits[1]? and limits[1] < 1
				MAMA_SLOW = limits[1]
			else
				MAMA_SLOW = 0.05
			mama = talib.MAMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInFastLimit: MAMA_FAST
				optInSlowLimit: MAMA_SLOW
			mama.outFAMA
		when 'T3'
			# Triple Exponential Moving Average period and vFactor
			limits = "#{period}".split " "
			if limits[0]?
				T3_LEN = limits[0]
			else
				T3_LEN = 16
			if limits[1]? and limits[1] < 1
				T3_V = limits[1]
			else
				T3_V = 0.7
			talib.T3
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: T3_LEN
				optInVFactor: T3_V
		when 'HMA'
			halfWMA = talib.WMA
				inReal: sInput
				startIdx: period
				endIdx: sInput.length-1
				optInTimePeriod: Math.round(period/2)
			fullWMA = talib.WMA
				inReal: sInput
				startIdx: period
				endIdx: sInput.length-1
				optInTimePeriod: period
			twiceWMA = talib.ADD
				inReal0: halfWMA
				inReal1: halfWMA
				startIdx: 0
				endIdx: halfWMA.length-1
			avgWMA = talib.SUB
				inReal0: twiceWMA
				inReal1: fullWMA
				startIdx: 0
				endIdx: twiceWMA.length-1
			talib.WMA
				inReal: avgWMA
				startIdx: 0
				endIdx: avgWMA.length-1
				optInTimePeriod: Math.round(Math.sqrt(period))
		when 'EHMA'
			halfEMA = talib.EMA
				inReal: sInput
				startIdx: period
				endIdx: sInput.length-1
				optInTimePeriod: Math.round(period/2)
			fullEMA = talib.EMA
				inReal: sInput
				startIdx: period
				endIdx: sInput.length-1
				optInTimePeriod: period
			twiceEMA = talib.ADD
				inReal0: halfEMA
				inReal1: halfEMA
				startIdx: 0
				endIdx: halfEMA.length-1
			avgEMA = talib.SUB
				inReal0: twiceEMA
				inReal1: fullEMA
				startIdx: 0
				endIdx: twiceEMA.length-1
			talib.EMA
				inReal: avgEMA
				startIdx: 0
				endIdx: avgEMA.length-1
				optInTimePeriod: Math.round(Math.sqrt(period))
		when 'HT'
			talib.HT_TRENDLINE
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
		when 'Laguerre'
			# Laguerre gamma (0.8)
			if period < 1
				LGAMMA = period
			else
				LGAMMA = 0.8
			_.map(sInput, LaguerreMA)
		when 'FRAMA'
			# FRAMA length and slow period
			limits = "#{period}".split " "
			if limits[0]?
				FRAMA_LEN = 1*limits[0]
				if FRAMA_LEN % 2 isnt 0 then FRAMA_LEN = FRAMA_LEN + 1
			else
				FRAMA_LEN = 16
			if limits[1]?
				FRAMA_SLOW = 1*limits[1]
			else
				FRAMA_SLOW = 200
			fInstrument = []
			for x in [0..sInstrument.high.length-1]
				fInstrument[x] = {close: sInstrument.close[x], low: sInstrument.low[x], high: sInstrument.high[x]}
			_.map(fInstrument, FRAMA)
		when 'ZLEMA'
			ema1 = talib.EMA
				inReal: sInput
				startIdx: 0
				endIdx: sInput.length-1
				optInTimePeriod: period
			ema2 = talib.EMA
				inReal: ema1
				startIdx: 0
				endIdx: ema1.length-1
				optInTimePeriod: period
			if ema1.length > ema2.length
				ema1 = _.drop(ema1, ema1.length - ema2.length)
			if ema2.length > ema1.length
				ema2 = _.drop(ema2, ema2.length - ema1.length)
			emad = talib.SUB
				inReal0: ema1
				inReal1: ema2
				startIdx: 0
				endIdx: ema1.length-1
			talib.ADD
				inReal0: ema1
				inReal1: emad
				startIdx: 0
				endIdx: ema1.length-1
		when 'WRainbow'
			wma = sInput
			i = 0
			for x in [0..period-1]
				wma = talib.WMA
					inReal: wma
					startIdx: 0
					endIdx: wma.length-1
					optInTimePeriod: 2
				if x < period/2
					REDUCE_BY = period/2 - x
					i = i + period/2 - x
					mwma = _.map(wma, feedbackMultiply)
				else
					i = i + 1
					mwma = wma
				if wr?
					wr = _.drop(wr, wr.length - mwma.length)
					wr = talib.ADD
						inReal0: wr
						inReal1: mwma
						startIdx: 0
						endIdx: wr.length-1
				else
					wr = mwma
			REDUCE_BY = i
			_.map(wr, feedbackDivide)
		when 'VWMA'
			vp = talib.MULT
				inReal0: sInput
				inReal1: sInstrument.volumes
				startIdx: 0
				endIdx: sInput.length-1
			svp = talib.SMA
				inReal: vp
				startIdx: 0
				endIdx: vp.length-1
				optInTimePeriod: period
			sv = talib.SMA
				inReal: sInstrument.volumes
				startIdx: 0
				endIdx: sInstrument.volumes.length-1
				optInTimePeriod: period
			talib.DIV
				inReal0: svp
				inReal1: sv
				startIdx: 0
				endIdx: sv.length-1
		when 'EVWMA'
			EV_LEN = period
			eInstrument = []
			for x in [0..sInstrument.high.length-1]
				eInstrument[x] = {close: sInstrument.close[x], low: sInstrument.low[x], high: sInstrument.high[x], volume: sInstrument.volumes[x]}
			_.map(eInstrument, EVWMA)

processOSC = (selector, period, instrument, secondary = false) ->
	if secondary
		sInstrument = ['low', 'high', 'close']
		sInstrument.low = instrument
		sInstrument.high = instrument
		sInstrument.close = instrument
	else
		sInstrument = instrument
	
	switch selector
		when 'NONE'
			instrument
		when 'Stochastic'
			STOCH_LEN = period
			fInstrument = []
			for x in [0..sInstrument.high.length-1]
				fInstrument[x] = {close: sInstrument.close[x], low: sInstrument.low[x], high: sInstrument.high[x]}
			_.map(fInstrument, Stochastic)
		when 'FT'
			# Fisher Transform length and gamma
			limits = "#{period}".split " "
			if limits[0]?
				FT_LEN = limits[0]
			else
				FT_LEN = 10
			if limits[1]? and limits[1] < 1
				FT_GAMMA = limits[1]
			else
				FT_GAMMA = 0.33
			fInstrument = []
			for x in [0..sInstrument.high.length-1]
				fInstrument[x] = {close: sInstrument.close[x], low: sInstrument.low[x], high: sInstrument.high[x]}
			_.map(fInstrument, FT)
		when 'IFT'
			_.map(sInstrument.close, IFT)
		when 'MFI'
			talib.MFI
				high: sInstrument.high
				low: sInstrument.low
				close: sInstrument.close
				volume: sInstrument.volumes
				startIdx: 0
				endIdx: sInstrument.close.length-1
				optInTimePeriod: period
		when 'RSI'
			talib.RSI
				inReal: processMA('NONE', 0, sInstrument)
				startIdx: 0
				endIdx: sInstrument.close.length-1
				optInTimePeriod: period
		when 'LRSI'
			LGAMMA = period
			price = processMA('NONE', 0, sInstrument)
			_.map(price, LaguerreRSI)		
		when 'LMFI'
			LGAMMA = period
			price = talib.MULT
				inReal0: processMA('NONE', 0, sInstrument)
				inReal1: sInstrument.volumes
				startIdx: 0
				endIdx: sInstrument.volumes.length-1
			_.map(price, LaguerreRSI)

makeDelta = (instrument) ->
	delta = []
	short = processMA(SHORT_MA_T, SHORT_MA_P, instrument)
	if FEED_DELTA_T isnt 'NONE'
		feedback = processMA(FEED_MA_T, FEED_MA_P, instrument)
		[feedback, short] = fixLength(feedback, short)
		shortFeedbackDelta = talib.SUB
			inReal0: short
			inReal1: feedback
			startIdx: 0
			endIdx: feedback.length-1
		
		if FEED_VOLUME_T isnt 'NONE'
			switch FEED_VOLUME_T
				when 'Stochastic'
					STOCH_LEN = FEED_VOLUME_P
					volume = _.map(instrument.volumes, SimpleStochastic)
				when 'Laguerre'
					LGAMMA = FEED_VOLUME_P
					volume = _.map(instrument.volumes, LaguerreRSI)
			[shortFeedbackDelta, volume] = fixLength(shortFeedbackDelta, volume)
			REDUCE_BY = 100/FEED_VOLUME_W
			volume = _.map(volume, feedbackDivide)
			REDUCE_BY = 1-FEED_VOLUME_W
			volume = _.map(volume, feedbackAdd)
			shortFeedbackDelta = talib.MULT
				inReal0: shortFeedbackDelta
				inReal1: volume
				startIdx: 0
				endIdx: volume.length-1
		
		REDUCE_BY = FEED_DELTA_P
		switch FEED_DELTA_T
			when 'Division'
				feedDelta = _.map(shortFeedbackDelta, feedbackDivide)
			when 'Root'
				feedDelta = _.map(shortFeedbackDelta, feedbackRoot)
			when 'Logarithm'
				feedDelta = _.map(shortFeedbackDelta, feedbackLog)
		
		switch FEED_APPLY
			when 'Short MA price'
				lInput = processMA('NONE', 0, instrument)
				[lInput, feedDelta] = fixLength(lInput, feedDelta)
				lInput = talib.ADD
					inReal0: lInput
					inReal1: feedDelta
					startIdx: 0
					endIdx: feedDelta.length-1
				short = processMA(SHORT_MA_T, SHORT_MA_P, lInput, true)
				long = processMA(LONG_MA_T, LONG_MA_P, instrument)
				delta['correctedPrice'] = _.last(lInput)
			when 'Long MA price'
				lInput = processMA('NONE', 0, instrument)
				[lInput, feedDelta] = fixLength(lInput, feedDelta)
				lInput = talib.ADD
					inReal0: lInput
					inReal1: feedDelta
					startIdx: 0
					endIdx: feedDelta.length-1
				long = processMA(LONG_MA_T, LONG_MA_P, lInput, true)
				delta['correctedPrice'] = _.last(lInput)
			when 'Both MA prices'
				lInput = processMA('NONE', 0, instrument)
				[lInput, feedDelta] = fixLength(lInput, feedDelta)
				lInput = talib.ADD
					inReal0: lInput
					inReal1: feedDelta
					startIdx: 0
					endIdx: feedDelta.length-1
				short = processMA(SHORT_MA_T, SHORT_MA_P, lInput, true)
				long = processMA(LONG_MA_T, LONG_MA_P, lInput, true)
				delta['correctedPrice'] = _.last(lInput)
			when 'Short MA'
				[short, feedDelta] = fixLength(short, feedDelta)
				short = talib.ADD
					inReal0: short
					inReal1: feedDelta
					startIdx: 0
					endIdx: feedDelta.length-1
				long = processMA(LONG_MA_T, LONG_MA_P, instrument)
			when 'Long MA'
				long = processMA(LONG_MA_T, LONG_MA_P, instrument)
				[long, feedDelta] = fixLength(long, feedDelta)
				long = talib.ADD
					inReal0: long
					inReal1: feedDelta
					startIdx: 0
					endIdx: feedDelta.length-1
			when 'Both MA'
				[short, feedDelta] = fixLength(short, feedDelta)
				short = talib.ADD
					inReal0: short
					inReal1: feedDelta
					startIdx: 0
					endIdx: feedDelta.length-1
				long = processMA(LONG_MA_T, LONG_MA_P, instrument)
				[long, feedDelta] = fixLength(long, feedDelta)
				long = talib.ADD
					inReal0: long
					inReal1: feedDelta
					startIdx: 0
					endIdx: feedDelta.length-1
	else
		long = processMA(LONG_MA_T, LONG_MA_P, instrument)
	
	[long, short] = fixLength(long, short)
	shortLongDelta = talib.SUB
		inReal0: short
		inReal1: long
		startIdx: 0
		endIdx: long.length-1
	delta['short'] = _.last(short)
	delta['long'] = _.last(long)
	delta['shortLongDelta'] = _.last(shortLongDelta)
	deltaResult = _.last(shortLongDelta)
	
	if FEED_DELTA_T isnt 'NONE'
		delta['feedback'] = _.last(feedback)
		delta['shortFeedbackDelta'] = _.last(shortFeedbackDelta)	
	
	if MACD_MA_T isnt 'NONE'
		macd = processMA(MACD_MA_T, MACD_MA_P, shortLongDelta, true)
		[macd, shortLongDelta] = fixLength(macd, shortLongDelta)
		macdDelta = talib.SUB
			inReal0: shortLongDelta
			inReal1: macd
			startIdx: 0
			endIdx: macd.length-1
		delta['macdSignal'] = _.last(macd)
		delta['macdDelta'] = _.last(macdDelta)
		deltaResult = _.last(macdDelta)
	
	storage.lastDeltaPos = storage.DeltaPos
	delta['deltaResult'] = deltaResult
	if deltaResult > CURR_HI_THRESHOLD and deltaResult > CURR_LO_THRESHOLD
		storage.DeltaPos = 1
	else if deltaResult < CURR_HI_THRESHOLD and deltaResult < CURR_LO_THRESHOLD
		storage.DeltaPos = -1
	else
		storage.DeltaPos = 0
	return delta

makeOsc = (instrument) ->
	if OSC_MAP_T isnt 'NONE'
		osc = processMA(OSC_MAP_T, OSC_MAP_P, instrument)
		sInstrument = ['low', 'high', 'close', 'volumes']
		sInstrument.low = osc
		sInstrument.high = osc
		sInstrument.close = osc
		sInstrument.volumes = instrument.volumes
		sInstrument.volumes = _.drop(sInstrument.volumes, sInstrument.volumes.length - osc.length)
	else
		sInstrument = instrument
	osc = processOSC(OSC_TYPE, OSC_PERIOD, sInstrument)
	osc = processMA(OSC_MA_T, OSC_MA_P, osc, true)
	osc = processOSC(OSC_NORM, OSC_PERIOD, osc, true)
	oscResult = _.last(osc)
	
	storage.lastOscPos = storage.OscPos
	if oscResult < OSC_THRESHOLD
		storage.OscPos = 1
	else if oscResult > (100 - OSC_THRESHOLD)
		storage.OscPos = -1
	else
		storage.OscPos = 0
	return _.last(osc)

getAction = (delta, osc) ->
	dscore = 0
	oscore = 0
	if OSC_MODE is 'NONE' or OSC_MODE is 'Regular' or OSC_MODE is 'Thresholds'
		if storage.lastDeltaPos <= 0 and storage.DeltaPos is 1
			dscore = 1
		else if storage.lastDeltaPos >= 0 and storage.DeltaPos is -1
			dscore = -1
		else
			dscore = 0
	else if OSC_MODE is 'Zones'
		if storage.lastDeltaPos <= 0 and storage.DeltaPos is 1 and storage.OscPos isnt -1
			dscore = 1
		else if storage.lastDeltaPos >= 0 and storage.DeltaPos is -1 and storage.OscPos isnt 1
			dscore = -1
		else
			dscore = 0
	else if OSC_MODE is 'Reverse thresholds'
		if storage.lastDeltaPos <= 0 and storage.DeltaPos is 1 and storage.OscPos isnt 1
			dscore = 1
		else if storage.lastDeltaPos <= 0 and storage.DeltaPos isnt -1 and storage.OscPos is 1
			dscore = 1
		else if storage.lastDeltaPos >= 0 and storage.DeltaPos is -1 and storage.OscPos isnt -1
			dscore = -1
		else if storage.lastDeltaPos >= 0 and storage.DeltaPos isnt 1 and storage.OscPos is -1
			dscore = -1
		else
			dscore = 0
	
	if OSC_MODE is 'Regular' or OSC_MODE is 'Thresholds'
		switch OSC_TRIGGER
			when 'Early'
				if storage.OscPos is 1 and storage.lastOscPos isnt 1
					oscore = 1
				else if storage.OscPos is -1 and storage.lastOscPos isnt -1
					oscore = -1
				else
					oscore = 0
			when 'Extreme'
				if storage.OscPos is 1 and storage.lastOsc <= osc
					oscore = 1
				else if storage.OscPos is -1 and storage.lastOsc >= osc
					oscore = -1
				else
					oscore = 0
			when 'Late'
				if storage.OscPos isnt 1 and storage.lastOscPos is 1
					oscore = 1
				else if storage.OscPos isnt -1 and storage.lastOscPos is -1
					oscore = -1
				else
					oscore = 0
			when 'Buy early, sell late'
				if storage.OscPos is 1 and storage.lastOscPos isnt 1
					oscore = 1
				else if storage.OscPos isnt -1 and storage.lastOscPos is -1
					oscore = -1
				else
					oscore = 0
			when 'Buy late, sell early'
				if storage.OscPos isnt 1 and storage.lastOscPos is 1
					oscore = 1
				else if storage.OscPos is -1 and storage.lastOscPos isnt -1
					oscore = -1
				else
					oscore = 0
	
	if OSC_MODE is 'Thresholds' and SHORT_MA_T isnt 'NONE' and storage.DeltaPos is 0
		oscore = 0
	
	return dscore + oscore

init: ->
	# All the plotlines
	setPlotOptions
		# Short MA on data
		Short:
			color: 'darkblue'
		# Feedback MA on data
		Feedback:
			color: 'lightred'
		# Short-Feedback delta		
		ShortFeedbackDelta:
			color: 'lightgreen'
			secondary: true
		# Delta added to price
		CorrectedPrice:
			color: 'lightpink'
		# Long MA on corrected data
		Long:
			color: 'darkred'
		# Short-Long delta
		ShortLongDelta:
			color: 'darkgreen'
			secondary: true
		# MACD MA on Short-Long delta
		MACDSignal:
			color: 'magenta'
			secondary: true
		# MACD MA and Short-Long delta delta
		MACD:
			color: 'pink'
			secondary: true
		Zero:
			color: 'darkgrey'
			secondary: true
		HighThreshold:
			color: 'darkseagreen'
			secondary: true
		LowThreshold:
			color: 'lightpink'
			secondary: true
		HighOsc:
			color: 'orange'
		LowOsc:
			color: 'orange'
		Oscillator:
			color: 'orange'
		Score:
			color: 'red'
			secondary: true
	
	info "Welcome to Cryptotrader Universal Trading Constructor bot by lastguru"
	info "Newest code is available here: https://github.com/lastguru1/ct-utc"

handle: ->
	instrument = @data.instruments[0]
	close = instrument.close[instrument.close.length-1]
	CURR_HI_THRESHOLD = close * HI_THRESHOLD / 100
	CURR_LO_THRESHOLD = close * LO_THRESHOLD / 100

	# Starting state
	storage.botStartedAt ?= data.at
	storage.lastBuyPrice ?= 0
	storage.lastSellPrice ?= 0
	storage.lastDelta ?= 0
	storage.lastOsc ?= 0
	storage.lastAction ?= 0
	storage.lastDeltaPos ?= 0
	storage.lastOscPos ?= 0
	storage.DeltaPos ?= 0
	storage.OscPos ?= 0
	storage.wonTrades ?= 0
	storage.lostTrades ?= 0
	storage.startBase ?= @portfolios[instrument.market].positions[instrument.base()].amount
	storage.startAsset ?= @portfolios[instrument.market].positions[instrument.asset()].amount
	storage.startPrice ?= close
	# Current state
	baseName = instrument.base().toUpperCase()
	assetName = instrument.asset().toUpperCase()
	curBase = @portfolios[instrument.market].positions[instrument.base()].amount
	curAsset = @portfolios[instrument.market].positions[instrument.asset()].amount
	startBaseEquiv = storage.startBase + storage.startAsset * storage.startPrice
	startAssetEquiv = storage.startAsset + storage.startBase / storage.startPrice
	curBaseEquiv = curBase + curAsset * close
	curAssetEquiv = curAsset + curBase / close
	gainBH = 100 * (close / storage.startPrice - 1)
	gainBot = 100 * (curBaseEquiv / startBaseEquiv - 1)
	
	# Printing state
	info "========== Lastguru's UTC bot =========="
	debug "Starting " + baseName + ": " + _.round(storage.startBase, 2) + " | Starting " + assetName + ": " + _.round(storage.startAsset, 2) + " | Starting " + baseName + " equivalent: " + _.round(startBaseEquiv, 2)
	debug "Current " + baseName + ": " + _.round(curBase, 2) + " | Current " + assetName + ": " + _.round(curAsset, 2) + " | Current " + baseName + " equivalent: " + _.round(curBaseEquiv, 2)
	debug "Starting price: " + sigRound(storage.startPrice, 5) + " | Current price: " + sigRound(close, 5)
	debug "Trades: " + (storage.wonTrades + storage.lostTrades) + " | Won: " + storage.wonTrades + " | Lost: " + storage.lostTrades + " | W/L: " + _.round(100 * storage.wonTrades / (storage.wonTrades + storage.lostTrades), 2) + "%"
	debug "Buy and Hold efficiency: " + _.round(gainBH, 2) + "% | Bot efficiency: " + _.round(gainBot, 2) + "%"
	# Set oscillator scale and position
	storage.oscHigh ?= close * 0.75
	storage.oscLow ?= close * 0.65
	
	plot
		Zero: 0
	
	if SHORT_MA_T isnt 'NONE'
		delta = makeDelta(instrument)
		plot
			HighThreshold: CURR_HI_THRESHOLD
			LowThreshold: CURR_LO_THRESHOLD
			Short: delta.short
			Long: delta.long
			ShortLongDelta: delta.shortLongDelta
		if FEED_DELTA_T isnt 'NONE'
			plot
				Feedback: delta.feedback
				ShortFeedbackDelta: delta.shortFeedbackDelta
		if delta.correctedPrice
			plot
				CorrectedPrice: delta.correctedPrice
		if MACD_MA_T isnt 'NONE'
			plot
				MACDSignal: delta.macdSignal
				MACD: delta.macdDelta
	
	if OSC_MODE isnt 'NONE'
		osc = makeOsc(instrument)
		plot
			HighOsc: storage.oscHigh - OSC_THRESHOLD * (storage.oscHigh - storage.oscLow) / 100
			LowOsc: storage.oscLow + OSC_THRESHOLD * (storage.oscHigh - storage.oscLow) / 100
			Oscillator: storage.oscLow + osc * (storage.oscHigh - storage.oscLow) / 100
	action = getAction(delta.deltaResult, osc)
	storage.lastDelta = delta.deltaResult
	storage.lastOsc = osc
	
#	plot
#		Score: action
	if action > 0 and storage.lastAction isnt 1
		storage.lastAction = 1
		if curBase isnt 0
			ticker = trading.getTicker instrument
			price = ticker.sell*ORDER_PRICE
			amount = curBase/price
			trading.buy instrument, ORDER_TYPE, amount, price, 60 * @config.interval
			storage.lastBuyPrice = price
			if price <= storage.lastSellPrice
				storage.wonTrades = storage.wonTrades + 1
			else
				storage.lostTrades = storage.lostTrades + 1
	if action < 0 and storage.lastAction isnt -1
		storage.lastAction = -1
		if curAsset isnt 0
			ticker = trading.getTicker instrument
			price = ticker.buy/ORDER_PRICE
			amount = curAsset
			trading.sell instrument, ORDER_TYPE, amount, price, 60 * @config.interval
			storage.lastSellPrice = price
			if price >= storage.lastBuyPrice
				storage.wonTrades = storage.wonTrades + 1
			else
				storage.lostTrades = storage.lostTrades + 1
