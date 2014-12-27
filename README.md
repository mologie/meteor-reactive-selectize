reactive-selectize
==================

**Here be dragons.** This is a work-in-progress helper library for
`mologie:autoform-selectize`. It appears to work just fine, but has
not been extensively tested. Some selectize.js features are currently
unsupported (option groups, placeholders, possibly more).

This package integrates selectize.js controls with Meteor. It provides
a wrapper class, `ReactiveSelectizeController` which takes care of
synchronizing the select field's options with a data source passed to
the wrapper. Additionally, a small jQuery plugin is provided. The
jQuery plugin will register itself with Blaze and automatically stop
its live queries when the template is destroyed.

Usage
-----

`ReactiveSelectizeController` wraps selectize.js's API and takes care
of synchronizing your data source with the selectize control. The class
expects its settings as only argument. The control is not relevant when
constructing an instance of the class. Call the class's `attach`
function and pass it a jQuery instance of the target select control once
ready. Call the class's `stop` function without arguments when done to
terminate live queries and reactive computations.

The class's settings are mostly indicical to that of selectize.js (and
it will in fact pass through any unknown options). Head over to the
[selectize.js repository](https://github.com/brianreavis/selectize.js)
and make yourself familiar with its examples and
[usage document](https://github.com/brianreavis/selectize.js/blob/master/docs/usage.md)
first.

This package introduces the following extensions to selectize.js's
settings:

<table width="100%">
	<tr>
		<th valign="top" colspan="4" align="left"><a href="#general" name="general">ReactiveSelectizeController extensions</a></th>
	</tr>
	<tr>
		<th valign="top" width="120px" align="left">Option</th>
		<th valign="top" align="left">Description</th>
		<th valign="top" width="60px" align="left">Type</th>
		<th valign="top" width="60px" align="left">Default</th>
	</tr>
	<tr>
		<td valign="top"><code>options</code></td>
		<td valign="top"><i>Required.</i> A function returning either an array of options, or a <code>Mongo.Cursor</code>. The function is re-evaluated automatically using <code>Tracker</code> when its reactive data sources change.</td>
		<td valign="top"><code>function</code></td>
		<td valign="top"><code>undefined</code></td>
	</tr>
	<tr>
		<td valign="top"><code>placeholder</code></td>
		<td valign="top"><i>Optional.</i> A placeholder option with empty value will be added as first element of the options collection. It can be used with selectize.js's <code>allowEmptyOption</code> setting.</td>
		<td valign="top"><code>object</code></td>
		<td valign="top"><code>undefined</code></td>
	</tr>
	<tr>
		<td valign="top"><code>selected</code></td>
		<td valign="top"><i>Optional.</i> An array of strings containing the identifying values of options to be marked as selected. Should this array contain values which are not present in the initial result of <code>options</code>, and if <code>create</code> is set, the options will be added as if the user created them. Your custom <code>create</code> callback, if any, will be invoked for each unknown option. The order of the array is kept.</td>
		<td valign="top"><code>[String]</code></td>
		<td valign="top"><code>undefined</code></td>
	</tr>
	<tr>
		<td valign="top"><code>remotePersist</code></td>
		<td valign="top">
			<i>Optional</i> and only relevant if <code>create</code> is set. When an option disappears from the result of <code>options</code>, this setting will used for determining the appropriate reaction.<br />
			<code>always</code>: All options should be kept in the select field's dropdown list until it is destroyed. Requires <code>persist</code> to work like you want it to.<br />
			<code>selected</code>: Delete the option only if it is not selected. If it is selected, the option will be marked as user-created and fall under the control of the <code>persist</code> setting.<br />
			<code>never</code>: Deselect options prior to deleting them and make your users wonder what is going on.
		</td>
		<td valign="top"><code>String</code></td>
		<td valign="top"><code>"selected"</code></td>
	</tr>
	<tr>
		<th valign="top" colspan="4" align="left"><a href="#general" name="general">jQuery plugin extensions</a></th>
	</tr>
	<tr>
		<th valign="top" width="120px" align="left">Option</th>
		<th valign="top" align="left">Description</th>
		<th valign="top" width="60px" align="left">Type</th>
		<th valign="top" width="60px" align="left">Default</th>
	</tr>
	<tr>
		<td valign="top"><code>automaticTeardown</code></td>
		<td valign="top">The jQuery plugin will attach itself to destroyed-event of the Blaze view which contains the target select controls. If you are using this library outside of Meteor's templating system, this behavior may break things and can be disabled using this option.</td>
		<td valign="top"><code>Boolean</code></td>
		<td valign="top"><code>true</code></td>
	</tr>
</table>


Example
-------

Assuming you have a collection of posts, accessible through `Posts`,
and wish to display a select field which uses the post's database
identifier as value and the post title as label:

```html
<body>
	<select id="postSelect"></select>
</body>
```

```js
Template.body.rendered = ->
	@postSelect = @$('#postSelect').reactiveSelectize(
		options: -> Posts.find()
		valueField: '_id'
		labelField: 'title'
	)[0].reactiveSelectize

Template.body.events
	'change #postSelect': -> (event, tpl)
		postId = tpl.postSelect.getValue()
		# Use the post ID
```


License
-------

This project is licensed under the MIT license.
