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
			@_liveQuery.stop() if @_liveQuery?
			@_liveQuery = @_observeChangesInQuery @_snapshot
		
		else if _.isArray @_snapshot
			# Diff against previous snapshot
			@_diffSnapshots @_previousSnapshot, @_snapshot if @_previousSnapshot
		
		else
			throw "DataSource: provider function must return an array or a Mongo.Cursor instance"
	
	_observeChangesInQuery: (cursor) -> cursor.observeChanges
		added: (id, fields) =>
			object = makeObject id, fields
			@_callbacks.added object if @_callbacks.added?
		
		changed: (id, fields) =>
			object = makeObject id, fields
			@_callbacks.changed object if @_callbacks.changed?
		
		removed: (id) =>
			object = makeObject id, fields
			@_callbacks.removed object if @_callbacks.removed?
	
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
		
		# Diff keys
		addedKeys = _.difference currentKeys, previousKeys
		removedKeys = _.difference previousKeys, currentKeys
		changedKeys = _.intersection previousSnapshot, currentSnapshot
		
		# Begin batch update
		@_callbacks.batchBegin() if @_callbacks.batchBegin?
		
		# Notify delegate
		for value in addedKeys
			@_callbacks.added current[value] if @_callbacks.added?
		for value in changedKeys
			@_callbacks.changed current[value], previous[value] if @_callbacks.changed?
		for value in removedKeys
			@_callbacks.removed previous[value] if @_callbacks.removed?
		
		# End batch update
		@_callbacks.batchEnd() if @_callbacks.batchEnd?


@DataSourceObserver = DataSourceObserver
