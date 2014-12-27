Package.describe({
	name:    'mologie:reactive-selectize',
	summary: 'Keeps selectize.js\'s options in sync with a reactive data source',
	version: '0.0.3',
	git:     'https://github.com/mologie/meteor-reactive-selectize'
});

var clientDependencies = [
	'coffeescript',
	'jquery',
	'underscore'
];

var clientFiles = [
	'data-source-observer.coffee',
	'reactive-selectize.coffee'
];

var clientExports = [
	'ReactiveSelectizeController'
];

Package.onUse(function(api) {
	api.versionsFrom('1.0');
	api.use(clientDependencies, 'client');
	api.addFiles(clientFiles, 'client');
	api.export(clientExports, 'client');
});
