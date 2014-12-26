# reactive-selectize

**Here be dragons.** This is a work-in-progress helper library for
`mologie:autoform-selectize`. It appears to work just fine, but has
not been extensively tested and lacks proper documentation.

This package integrates selectize.js controls with Meteor. It provides
a wrapper class which takes care of synchronizing the select field's
options with a data source provided when constructing the wrapper.

## Example

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
  @controller = new ReactiveSelectizeController
    options: -> Posts.find()
    valueField: '_id'
    labelField: 'title'
  @controller.attach @$('#postSelect')

Tempalte.body.destroyed = ->
  @controller.stop()

Template.body.events
  'change #postSelect': -> (event, tpl)
    postId = tpl.controller.selectize.getValue()
    # Use the post ID
```


## License

This project is licensed under the MIT license.
