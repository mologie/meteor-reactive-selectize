# mologie:reactive-selectize
# Copyright 2014 Oliver Kuckertz <oliver.kuckertz@mologie.de>
# See COPYING for license information.
#
# jQuery plugin providing the syntax $('select').reactiveSelectize({...})

jQuery.fn.extend reactiveSelectize: (options) -> @each ->
	# Remove options extensions
	selectizeOptions = _.omit options, 'automaticTeardown'
	
	# Attach controller
	@reactiveSelectize = new ReactiveSelectizeController selectizeOptions
	@reactiveSelectize.attach $(this)
	
	# Setup automatic teardown
	unless options.automaticTeardown is false
		view = Blaze.getView this
		view.onViewDestroyed => @reactiveSelectize.stop()
