#
# mologie:autoform-selectize
# Copyright 2014 Oliver Kuckertz <oliver.kuckertz@mologie.de>
# See COPYING for license information.
#
# Abstract: Makes selectize.js's "options" property work like you would expect
# it to work in a Meteor application with little to no side effects and a mostly
# unmodified selectize.js API.
#
# This package integrates selectize.js controls with Meteor's reactive data
# sources. It specifically implements synchronizing Mongo.Cursor instances,
# but can also handle the results of arbitrary reactive computations.
#
# Selectize option extensions:
#   options      required, function returning either a Mongo.Cursor or an array
#   optionsMap   optional, works like .map for cursors
#   placeholder  optional, an object like your options but without value
#   selected     optional, an array of values that are selected
#   valueField   optional, defaults to "value"
#   labelField   optional, defaults to "label"
#

# TODO Option groups
# TODO Reactive placeholder (for localization)
# TODO Reactive default value (for crazy people)

class @ReactiveSelectizeController
	constructor: (args) ->
		@config = _.clone args
		@config.valueField ?= "value"
		@config.labelField ?= "label"
		
		@optionsDataSource = @config.options ? []
		@selectedItems = @config.selected ? []
	
	attach: ($el) ->
		if @selectize
			return
		view = $el.selectize(@_selectizeOptions())[0].selectize
		@_beginUpdatingView view
	
	stop: ->
		@_endReceivingDataUpdates() if @dataComputation?
		@_stopObservingChangesInDataSource() if @liveQuery?
	
	_selectizeOptions: ->
		_.omit @config, 'options', 'optionsMap', 'placeholder', 'selected'
	
	_beginUpdatingView: (selectize) ->
		@selectize = selectize
		@_addPlaceholder() if @config.placeholder
		@_populateFromDataSource()
	
	_optionValue: (option) ->
		option[@config.valueField] ? ""
	
	_mapOption: (option) ->
		if typeof @config.optionsMap is "function"
			option = _.clone option
			@config.optionsMap option
		else
			option
	
	_makeOption: (id, fields) ->
		option = _.clone fields
		option._id = id
		@_mapOption option
	
	_makeUserOption: (value) ->
		if typeof @config.create is "function"
			@config.create value
		else
			option = {}
			option[@config.valueField] = value
			option[@config.labelField] = value
			option
	
	_markPersistent: (option) ->
		# FIXME For the persist option to work correctly, the previously
		# created option must not be marked as "created by user". However,
		# selectize.js's API does not expose such a feature yet and assumes
		# that all options created through addOptions are user options.
		delete @selectize.userOptions[@_optionValue option]
	
	_addPlaceholder: ->
		placeholderOption = {}
		placeholderOption[@config.valueField] = ""
		placeholderOption[@config.labelField] = ""
		@selectize.addOption placeholderItem
		# TODO use placeholder value
		# TODO update placehodler value reactively if function
	
	_dataChanged: ->
		previousSnapshot = @dataSnapshot
		@dataSnapshot = @optionsDataSource()
		if @updateControlOnDataChange
			@_synchronizeWithDataSource previousSnapshot, @dataSnapshot
	
	_beginReceivingDataUpdates: ->
		@dataComputation = Tracker.autorun => @_dataChanged()
	
	_endReceivingDataUpdates: ->
		@dataComputation.stop()
		delete @dataComputation
	
	_populateFromDataSource: ->
		if typeof @optionsDataSource is "function"
			# Handle reactive data sources
			@_beginReceivingDataUpdates()
			options = @dataSnapshot
			
			# Handle Mongo cursors more efficiently (like Blaze)
			if options instanceof Mongo.Cursor
				@_endReceivingDataUpdates()
				cursor = options
				options = cursor.fetch()
				@liveQuery = @_observeChangesInDataSource cursor
			
			# Sanity check
			if not _.isArray options
				throw "reactive-selectize expected data source to return array"
		else
			# Handle static data sources
			options = @optionsDataSource
		
		# Apply map function
		if @config.optionsMap
			options = (@_mapOption option for option in options)
		
		# Register options from data source
		for option in options
			@selectize.addOption option
			@_markPersistent option
		@selectize.refreshOptions false
		
		# Set values
		predefinedOptions = _.pluck options, @config.valueField
		@_setInitialValues predefinedOptions
		
		# Begin updating control reactively
		@updateControlOnDataChange = true
	
	_synchronizeWithDataSource: (previousSnapshot, currentSnapshot) ->
		# Extract keys
		previousKeys = _.pluck previousSnapshot, @config.valueField
		currentKeys = _.pluck currentSnapshot, @config.valueField
		
		# Map objects to keys
		previous = []
		current = []
		for option in previousSnapshot
			previous[@_optionValue config] = item
		for option in currentSnapshot
			current[@_optionValue option] = item
		
		# Diff keys
		addedKeys = _.difference currentKeys, previousKeys
		removedKeys = _.difference previousKeys, currentKeys
		changedKeys = _.intersection previousSnapshot, currentSnapshot
		
		# Update control
		for value in addedKeys
			option = @_mapOption current[value]
			@selectize.addOption option
			@_markPersistent option
		for value in removedKeys
			@selectize.removeOption value
		for value in changedKeys
			item = @_mapOption current[value]
			@selectize.updateOption value, item
		
		# Render changes
		@selectize.refreshOptions false
	
	_setInitialValues: (predefinedValues) ->
		for itemValue in @selectedItems
			if itemValue in predefinedValues
				@selectize.addItem itemValue
			else if @config.create
				option = @_makeUserOption itemValue
				@selectize.addOption option
				@selectize.addItem itemValue
		@selectize.refreshOptions false
		@selectize.refreshItems()
	
	_observeChangesInDataSource: (cursor) -> cursor.observeChanges
		added: (id, fields) =>
			option = @_makeOption id, fields
			@selectize.addOption option
			@_markPersistent option
			@selectize.refreshOptions false
		
		changed: (id, fields) =>
			option = @_makeOption id, fields
			@selectize.updateOption @_optionValue option, option
		
		removed: (id) =>
			option = @_makeOption id, fields
			@selectize.removeOption @_optionValue option
			@selectize.refreshOptions false
	
	_stopObservingChangesInDataSource: ->
		@liveQuery.stop()
		delete @liveQuery
