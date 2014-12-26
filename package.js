Package.describe({
	name:    'mologie:reactive-selectize',
	summary: 'Keeps selectize.js\'s options in sync with a reactive data source',
	version: '0.1.0',
	git:     'TODO'
});

Package.onUse(function(api) {
	api.versionsFrom('1.0.2.1');
	api.use('coffeescript');
	api.use('jquery');
	api.addFiles('reactive-selectize.coffee', 'client');
	api.addFiles('reactive-selectize.html', 'client');
	api.export('ReactiveSelectizeController', 'client');
});
