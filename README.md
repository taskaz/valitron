valitron
========

jQuery validation plugin for [Laravel](http://www.laravel.com/), with Twitter bootstrap markup support.

Valitron name credits goes to [daylerees](http://daylerees.com/) :)

Version: might be 0.1 beta!

## What can it do?

- Obviously validate user input data using different rules.
- Apply validation while user typing.
- Automaticaly mark invalid fields with "error" class
- Can grab validation rules declared in html data-validation element.

## What can I do?

- Add new validation rules.
- Configure invalid field marking.
- Declare error and success validation callbacks.
- Change default options and default config.

# Some examples
Text input with some rules declared for validation:
```html
<input id="test" type="text" data-validation="required|min:2|max:30">
```
A JavaScript part for validation, hook a live validation, 
data-validation rules will be applied after 500ms cooldown then user stops typing.
```javascript
$("#test").valitron('live');
```
Need to cache successfull of failed validation? Just pass some callbacks
```javascript
$("#test").valitron('live', {
	error : function(messages) {	// you get an array of validation messages, happens if at least one rule fails
		for ( var msg in messages )
		{
			console.log(
				msg.result,		// True/false validation results
				msg.rule,		// A rule applied
				msg.parameters,	// Rule parameters
				msg.message,	// Validation rule message, either translated or default one
				msg.translation // feature support
			);
		}
		// this refers to input DOM element
		$(this).addClass("error");
	},
	success : function(messages)
	{
		$(this).removeClass("error");
	},
	timeout: 1000 // timout to trigger validation in ms
}
});
```
If you return anything from callbacks that evolutes to true, globalError or globalSuccess will be called too

### Need to validate on button click?
```html
<input id="test" type="text" data-validation="required|min:2|max:30">
<button id="do_check" type="button">Validate!</button>
```
```javascript
$("#do_check").on('click', function()
{
	$("#test").valitron('validate');
})
```
## Validate an live validation support such options
- rules: [] # rules to check, default "|" delimiter, ":" parameters, ex: max:5|min:2
- language : 'en' # default language to use for errors, somehow should be loaded :)
  passes jQuery element and message, function(message) {}, this refers to jquery object
  global success will not be fired! return value witch evolutes to tru to fire it!
- success : null 
  passes jQuery element and message, function(messagae) {}, this refers to jquery object
  global error will not be fired! return value witch evolutes to tru to fire it!
- error : null
  executes before validation, returned value will be used for testing!
- beforeValidate : null
  executes after validation
- afterValidate : null
  indicates that vield is valid and doesnt contain any errors
- valid : false
  Timeout for live validation
- timeout : 500
  Timer reference
- timer: null

## Whant to change default options or config?
```javascript
$.valitron('options', {
	// supported options goes here
})
```
Changes to global config
```javascript
$.valitron('config', {
	globalSuccess : function(){} // global success, this refers to jquery object, there is actual code inside functions ;)
	globalError : function(){} 	// global error, this refers to jquery object
	ruleDelimiter : "|" 		// Delimiter used to separate rules.
	ruleMethodDelimiter : ":"	// Rule and its parameter delimiter
	ruleParamDelimiter: ","		// Rule parameters delimiter
	ruleDataElement: 'validation'// html data element name witch holds validation rules
})
```