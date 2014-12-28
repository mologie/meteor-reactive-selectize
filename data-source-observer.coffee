# mologie:reactive-selectize
# Copyright 2014 Oliver Kuckertz <oliver.kuckertz@mologie.de>
# See COPYING for license information.

# The DataSourceObserver class provides an API very similar to that of
# Mongo.Cursor for all reactive computations, given that all result sets share
# a unique identifying property. It also provides specific support for
# Mongo.Cursor objects for reducing overhead.

makeObject = (id, fields) ->
	object = _.clone fields
	object._id = id
	object

class DataSourceObserver
	constructor: (@_provider, @_valueField, @_callbacks) ->
		@_start()
	
	stop: ->
		if @_computation?
			@_computation.stop()
			delete @_computation
		
		if @_liveQuery?
			@_liveQuery.stop()
			delete @_liveQuery
		
		delete @_previousSnapshot
		delete @_snapshot
	
	getSnapshot: ->
		if @_snapshot instanceof Mongo.Cursor
			Tracker.nonreactive => @_snapshot.fetch()
		else
			@_snapshot
	
	_start: ->
		if typeof @_provider is "function"
			# Provider is a reactive data source
			@_computation = Tracker.autorun => @_takeSnapshot()
		else if _.isArray @_provider
			# Provider is a static data source
			@_snapshot = @_provider
		else
			# Oink
			throw new Error "DataSourceObserver provider must be either an array or a function returning an array"
	
	_takeSnapshot: ->
		@_previousSnapshot = @_snapshot
		@_snapshot = @_provider()
		
		if @_snapshot instanceof Mongo.Cursor
			# Begin receiving stream of results using live query interface
			@_ensureResultTypeUnchanged "cursor"
			@_liveQuery.stop() if @_liveQuery?
			@_liveQuery = @_observeChangesInQuery @_snapshot
		else if _.isArray @_snapshot
			# Diff current snapshot against previous snapshot, if any
			@_ensureResultTypeUnchanged "array"
			if @_previousSnapshot
				@_diffSnapshots @_previousSnapshot, @_snapshot
			else
				@_addAll @_snapshot
		else
			throw new Error "DataSourceObserver provider function must return an array or a Mongo.Cursor instance"
	
	_ensureResultTypeUnchanged: (type) ->
		# Sorry about this. :/ Changing result types are is supported because
		# this class does not keep track of what is actually being returned by
		# Mongo.Cursor's observe function. Maybe another time.
		if @_resultType?
			if type is not @_resultType
				throw new Error("DataSourceObserver provider must not change result type")
		else
			@_resultType = type
	
	_addAll: (collection) ->
		@_callbacks.batchBegin() if @_callbacks.batchBegin?
		if not @_callbacks.added?
			return
		for doc in collection
			@_callbacks.added doc
		@_callbacks.batchEnd() if @_callbacks.batchEnd?
	
	_observeChangesInQuery: (cursor) ->
		watchers = {}
		if @_callbacks.added? then watchers.added = (doc) => @_callbacks.added doc
		if @_callbacks.changed? then watchers.changed = (newDoc, oldDoc) => @_callbacks.changed newDoc, oldDoc
		if @_callbacks.removed? then watchers.removed = (oldDoc) => @_callbacks.removed oldDoc
		cursor.observe watchers
	
	_objectValue: (object) ->
		object[@_valueField] ? ""
	
	_diffSnapshots: (previousSnapshot, currentSnapshot) ->
		# Extract keys
		previousKeys = _.pluck previousSnapshot, @_valueField
		currentKeys = _.pluck currentSnapshot, @_valueField
		
		# Map objects to keys
		previous = []
		current = []
		for object in previousSnapshot
			previous[@_objectValue object] = object
		for object in currentSnapshot
			current[@_objectValue object] = object
		
		# Begin batch update
		@_callbacks.batchBegin() if @_callbacks.batchBegin?
		
		# Find added documents
		if @_callbacks.added?
			addedKeys = _.difference currentKeys, previousKeys
			for value in addedKeys
				@_callbacks.added current[value]
		
		# Find changed documents
		if @_callbacks.changed?
			changedKeys = _.intersection previousSnapshot, currentSnapshot
			for value in changedKeys
				@_callbacks.changed current[value], previous[value]
		
		# Find removed documents
		if @_callbacks.removed?
			removedKeys = _.difference previousKeys, currentKeys
			for value in removedKeys
				@_callbacks.removed previous[value]
		
		# End batch update
		@_callbacks.batchEnd() if @_callbacks.batchEnd?


@DataSourceObserver = DataSourceObserver
