# All this plugin is inspired by Taylor Otwell laravel framework validation class :)

( ($, window, document ) ->

	# plugin name
	valitron_name = 'valitron';

	# Validation error messages object, defines errors, and replacements
	# example { 'en' : [ "accepted" : "Error message", 
	#					 "between": { "numeric" : "Error on type number" , "string": "error on string type" }
	#					 "custom" : [ /*user defined errors*/ ]
	#					 "attributes" : [ /*user defined attribute replacements*/ ]
	# ]	}
	# 
	translations = {};

	# Custom rule validation transliations
	cust_translations = {};
	# Feature
	# Array of group validation objects, group validation fires error and success callbacks.
	groups = [];

	# this is passed to valiation option some parameters might be predefined :)
	defaults =
		rules: [] # rules to check, default "|" delimiter, ":" parameters, ex: max:5|min:2
		language : 'en' # default language to use for errors, somehow should be loaded :)
		# passes jQuery element and message, function(message) {}, this refers to jquery object
		# global success will not be fired! return value witch evolutes to tru to fire it!
		success : null 
		# passes jQuery element and message, function(messagae) {}, this refers to jquery object
		# global error will not be fired! return value witch evolutes to tru to fire it!
		error : null
		# executes before validation, returned value will be used for testing!
		beforeValidate : null
		# executes after validation
		afterValidate : null
		# indicates that vield is valid and doesnt contain any errors
		valid : false
		# Timeout for live validation
		timeout : 500
		# Timer reference
		timer: null
		# Last validation error messages
		errors : {}
		# Custom error messages, error with same key name as validation rule or attribute_rule notation for specific rule on field
		messages : {}

	config =
		globalSuccess : (msg) -> # global success, this refers to jquery object
			# Only this much is tied with twitter
			if $.valitron "config", "bootstrap"
				parent = $(this).parent()
				if parent.hasClass("controls") == true
					grand = parent.parent()
					if grand.hasClass("control-group")==true
						grand.removeClass "error"
			else $(this).removeClass "error"
			console.log "GLOBAL SUCCESS:", msg, this
		globalError : (msg) -> # global error, this refers to jquery object
			if $.valitron "config", "bootstrap"
				parent = $(this).parent()
				if parent.hasClass("controls") == true
					grand = parent.parent()
					if grand.hasClass("control-group")==true
						grand.addClass "error"
			else $(this).addClass "error"
			console.log "GLOBAL ERROR:", msg, this
		ruleDelimiter : "|"
		ruleMethodDelimiter : ":"
		ruleParamDelimiter: ","
		ruleDataElement: 'validation'
		bootstrap : true

	# valitron constructor, apply default options
	Valitron = ( element, options ) ->
		this.el = element # save DOM element
		this.$el = $(element) # save jQuery object of element
		# grab options from DOM element
		_d_opts = this._parseRules this.$el.data config.ruleDataElement
		# this.options = defaults
		this.options = {}
		this.options = this._extendOptions defaults
		this.options = this._extendOptions options
		if this.options.rules != null or typeof this.options.rules != "undefined"
			this.options.rules = this.options.rules.concat _d_opts
		else this.options.rules = _d_opts
		# keep name for easyer use
		this._name = valitron_name
		# init plugin
		this.init();

		# shared hidden function prefixed with "_"
	Valitron.prototype =

		_resolveValue: (el) ->
			if el.is "input:text, input:password, input:hidden"
				return el.val()
			if el.is "input:checkbox, input:radio"
				return el.is ":checked"
			else 
				return el.text()

		_parseRules: (rules) ->
			rule = []
			if typeof rules != "string"
				return rule
			_tmp = rules?.split config.ruleDelimiter # split rules to array
			# apply each rule to element
			if !_tmp 
				return rule
			$.each _tmp, (idx, value) ->
				# check if there is any rule, and its string
				if typeof value =='string' and value.length > 0
					# split rule into method name and its parameters
					_t = value.split config.ruleMethodDelimiter 
					_t[0] = _t[0].trim()
					_t[1] = if _t[1] != undefined and _t[1] != null then _t[1].split config.ruleParamDelimiter else null
					rule.push _t
			return rule

		# general message constructor function, all rules sohuld return such structure
		_ruleMsg : (res, type, msg) ->
			_r =
				result : res
				type : type
				message : msg
			return _r

		# # hellper to return positive result from validation rule
		_validMsg : (type, msg) ->
			return this._ruleMsg true, type, msg

		# hellper to return error results from validation rule
		_invalidMsg : (type, msg) ->
			return this._ruleMsg false, type, msg

		_condMsg : (cond, type, true_msg, false_smg) ->
			if cond 
				return this._validMsg type, true_msg
			else return this._invalidMsg type, false_smg

		_extendRules : (rules) ->
			_rls = this._parseRules(rules)
			if this.options?.rules?
				_rls = this.options.rules.concat _rls
			return _rls

		_extendOptions : (options) ->
			if this.options == null or typeof this.options == undefined then return $.extend(true, this.options, defaults)
			if options == null or typeof options == undefined then return this.options
			# Extend current rules and save to temp var
			_rls = this._extendRules(options?.rules?)
			
			# Extend current options
			_t_opts = $.extend true, {}, this.options, options
			# Save extended rules to temorary options object
			_t_opts.rules = _rls
			return _t_opts

		_callBefore :  ->
			# check if there is before callback
			if typeof this.options.beforeValidate == "function"
				_r_bfr = this.options.beforeValidate.call this.el this.options
			if _r_bfr == null or _r_bfr ==undefined # check if before validation callback returns anything, if not parse value
				_r_bfr = this._resolveValue(this.$el)	
			return _r_bfr

		# After filter for checking rules, 
		# result is array of checked rules:
		#	{ result:true/false, rule:"rule", paramters:[parameters], message:"message", type:"validated input type" }
		_callAfter : (result)->
			if typeof this.options.afterValidate == "function"
				this.options.afterValidate.call this.el, result
			return

		_callCallbacks : (result, options) ->

			if result != null and result != undefined # check if something is returned
				# console.log $this.valitron.ruleReturns
				# validation passed
				if this.isValid() == true
					# if if element validation has success callback execute it
					if typeof this.options.success == "function"
						# call element validation callback, if returns something call globalSuccess colback too
						_ret = this.options.success?.call(this.el, result) 
					# if not execute global callback
					else 
						config.globalSuccess?.call(this.el, result)
					# if element success callback returns anything call globalSuccess too
					if _ret
						config.globalSuccess?.call(this.el, result)
				# failed test, same checks as success case
				else
					if typeof this.options.error == "function"
						_ret = this.options.error?.call(this.el, result)
					else config.globalError?.call(this.el, result)
					if _ret
						config.globalError?.call(this.el, result)
			return

		_attribute : (attribute, lang)->
			lang = if lang? then lang else this.options.language
			if translations?[lang]?["attributes"]?[attribute]?
				return translations[lang]["attributes"][attribute]
			else return attribute

		_replace : (message, attribute, rule, value, parameters) ->
			# replace attribute name for nicer errors
			message = message.replace(":attribute", this._attribute(attribute))
			message = message.replace(":value", value)
			# now call validation rules replacers, witch should perform even nicer error messages
			if this.replacers[rule]?
				message = this.replacers[rule](message, attribute, rule, parameters)
			return message
		# Check for rule translations in source
		_translate_s : (source, name, type) ->
			if source?[name]?
				msg = source[name]
				# Check if its type specific rule message
				if typeof msg == "object"
					return if type? && msg[type]? then msg[type] else null
				else return msg
			else return null
			return null

		# translate rule error
		_translate : (attribute, rule, lang, value, parameters, type, def) ->
			lang = if lang? then lang else this.options.language
			# First should check for custom attribute messages, no language support tho
			c_name = attribute+"_"+rule;
			msg = this._translate_s this.options.messages, c_name, type
			if msg? then return this._replace msg, attribute, rule, value, parameters
			# Check for custom message in transliation files
			if translations?[lang]?["custom"]?
				_r1 = translations[lang]["custom"]
				msg = this._translate_s _r1, c_name, type
				if msg? then return this._replace msg, attribute, rule, value, parameters

			# Next, check for custom rule message, no matter what attribute was validated
			msg = this._translate_s this.options.messages, rule, type
			if msg? then return this._replace msg, attribute, rule, value, parameters
			# If there was no custom messages, retrun predefined ones
			if translations?[lang]?
				_r1 = translations[lang]
				msg = this._translate_s _r1, rule, type
				if msg? then return this._replace msg, attribute, rule, value, parameters
			return def

		_translate_msg: ( msg, rule, value, parameters) ->
			name = if this.$el.attr("name")? && typeof this.$el.attr("name") != "undefined" then this.$el.attr("name") else this.$el.attr("id")
			msg = this._translate name, rule, null, value, parameters, msg.type, msg.message
			return msg

		_register : ( name, closure ) ->
			if typeof closure == "function"
				this.validations[name] = closure
			else return this.validations[name]
			return this

		# Replacer registration
		_replacer : ( name, closure ) ->
			if typeof closure == "function"
				this.replacers[name] = closure
			else return this.replacers[name]
			return this

		# initialization logic
		init : ->
			# console.log "Init"
			return "Test init"

		validateRule : (el, method, parameters, value)->
			if el?.constructor? == Array
				method = el[1]
				parameters = el[2]
				value = el[3]
				el = el[0]
			# console.log "VR:", el, method, parameters, value
			this.validations[method]?.call this, el, parameters, value

		validate : (options) ->
			this.options = this._extendOptions(options?[0])
			# applied rules
			self = this;
			_result = []
			_valid = true
			_r_bfr = self._callBefore self.options
			$.each.call this, this.options.rules, (idx, value) ->
				# Validate the rule
				_re = self.validateRule.call self, self.$el, value[0], value[1], _r_bfr
				msg = self._translate_msg _re, value[0], _r_bfr, value[1]
				_result.push {
						result:_re.result
						rule: value[0]
						parameters:value[1]
						message: msg
						}
				if _re.result == false
					_valid = false
					# console.log value[0], value[1]
					return
			this.options.valid = _valid
			this.options.errors = _result
			this._callCallbacks _result, this.options
			this._callAfter
			return this.$el # for chainability

		# method to hook live field validation
		live : (options) ->
			self = this; # save valitron instance for event
			# Put hook on element
			_opts = options[0]
			if self.options.timer then return this.$el 
			this.options = this._extendOptions(_opts)
			self.$el.on 'keypress', ->
				if self.options.timer
					clearTimeout self.options.timer
					self.options.timer = null
				
				# pass all arguments to validate function
				self.options.timer = `setTimeout( function() { self.validate() }, self.options.timeout )`
				return
			return this.$el # for chainability

		isValid : ->
			return this.options.valid

		isInvalid : ->
			return !this.options.valid

		translate : (key)->
			return

		debug : ->
			console.log this.el
			console.log this.options
			console.log config
			return this.$el
		# Default rule behaviour options setter/getter
		config : (options) ->
			if options?
				$.extend true, config, options
				return this.$el
			else return config

		options : (options) ->
			if options[0]?
				defaults = this._extendOptions options[0]
				return this.$el
			else return defaults

		# Return errors from last check
		errors : ->
			return this.options.errors

	Valitron.prototype.validations =
		# validate max value
		max : (el, parameters, value) ->
			if typeof value == "number" and value > parameters[0]
				return this._invalidMsg "number", "Number is bigger then #{parameters}!"
			else if typeof value == "string" and value.length > parameters[0]
				this._invalidMsg "string", "String is to long, should be max:#{parameters}!"
			else
				return this._validMsg  null, "Grats man"

		# validate min value
		min: (el, parameters, value) ->
			if typeof value == "number" and value < parameters[0]
				return this._invalidMsg "number", "Number is smaller then #{parameters}!"
			else if typeof value == "string" and value.length < parameters[0]
				this._invalidMsg "string", "String should be at least #{parameters} characters length!"
			else
				return this._validMsg  null, "Grats man"

		# element size is given length
		size : (el, parameters, value) ->
			if value.length == parameters[0]
				return this._validMsg null, "Size is good."
			else return this._invalidMsg null, "Attribute must be required size!"

		# element value is between given values
		between : (el, parameters, value) ->
			if parameters[0]? and parameters[1]?
				if value < parameters[0] or value > parameters[1]
					return this._invalidMsg null, "Value must be between "+parameters[0]+" and "+parameters[1];
				else return this._validMsg null, "Value is between "+parameters[0]+" and "+parameters[1];
			else return this._invalidMsg null, "Bad parameters provided"

		# element value is numeric, so its in or double
		numeric : (el, parameters, value) ->

		#element value is integer type
		integer : (el, parameters, value) ->
			patern = /^\-?\d+$/;
			if patern.test value 
				return this._validMsg null, "Its integer allright."
			else return this._invalidMsg null, "Not integer man."

		# value for element is required
		required : (el, parameters, value) ->
			if value == null or value == undefined
				return this._invalidMsg null, "Value must be set to something!"
			else if typeof value == "string" and (value.length <= 0 or value == "")
				return this._invalidMsg null, "Value must be set to something!"
			else if typeof value == "boolean" or typeof value == "number"
				return if Boolean(value) then this._validMsg null, "Grats man" else this._invalidMsg null, "Value must be set to something!"
			else return this._validMsg null, "Grats man"

		# validates that elements values is same
		same : (el, parameters, value) ->
			for param in parameters
				if value != param
					return this._invalidMsg null, "Values is not same"
			return this._validMsg null, "Great, same values!"
		# value must be evoluted to true
		accepted : (el, parameters, value) ->
			if Boolean value
				return this._validMsg null, "Value is accepted"
			else return this._invalidMsg null, "You must accepts this!"

		# elements values is different
		different : (el, parameters, value) ->

		# validate that value is an array
		in : (el, parameters, value) ->
			if $.inArray(value, parameters[0].split(config.ruleParamDelimiter)) > -1
				return this._validMsg null, "Value is in array."
			else return this._invalidMsg null, "#{value} must be in "+parameters[0]+"!";

		# value is not in array
		not_id : (el, parameters, value) ->
			if $.inArray(value, parameters[0].split(config.ruleParamDelimiter)) > -1
				return this._invalidMsg null, "#{value} must NOT be in "+parameters[0]+"!";
			else return this._validMsg null, "Value is not in array."

		# validate against database, unique value
		unique : (el, parameters, value) ->
			console.log "Working on it..."

		# exists, validate against database, check for value existance
		exists : (el, parameters, value) ->
			console.log "Working on it..."

		# validate ip address
		ipv4 : (el, parameters, value) ->
			pattern = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/g;
			if typeof value == "string"
				if pattern.test value
					return this._validMsg null, "Good IPv4 address"
				else return this._invalidMsg null, "Invalid address"
			else return this._invalidMsg null, "Cant check this type of value"

		# validate email address
		email : (el, parameters, value) ->
			patern = "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?"
			if patern.test value
				return this._validMsg null, "E-mail is valid."
			else return this._invalidMsg null, "Invalid e-mail, please fix it now!"

		# validate url
		url : (el, parameters, value) ->
			console.log "Open for suggestions..."

		# validate that value is letter only
		alpha : (el, parameters, value) ->
			pattern = /^([a-z])+$/i
			if typeof value == "string"
				if pattern.test value
					return this._validMsg null, "This is alpha only"
				else return this._invalidMsg null, "Invalid value, can be only letters"
			else return this._invalidMsg null, "Cant check this type of value"

		# validate letters and numbers only
		alpha_num : (el, parameters, value) ->
			pattern = /^([a-z0-9])+$/i
			if typeof value == "string"
				if pattern.test value
					return this._validMsg null, "This is alpha only"
				else return this._invalidMsg null, "Invalid value, can be only letters"
			else return this._invalidMsg null, "Cant check this type of value"

		# validate letters numbers and dashes
		alpha_dash : (el, parameters, value) ->
			pattern = /^([-a-z0-9_-])+$/i
			if typeof value == "string"
				if pattern.test value
					return this._validMsg null, "This is alpha only"
				else return this._invalidMsg null, "Invalid value, can be only letters"
			else return this._invalidMsg null, "Cant check this type of value"

		# validate regular expression match
		match : (el, parameters, value) ->
			pattern = parameters[0]
			if typeof value == "string"
				if pattern?.test value
					return this._validMsg null, "This is alpha only"
				else return this._invalidMsg null, "Invalid value, can be only letters"
			else return this._invalidMsg null, "Cant check this type of value"

		# validate before date
		before : (el, parameters, value) ->
			if Date value < Date parameters[0]
				return this._validMsg null, "#{value} is before #{parameters[0]}"
			else return this._invalidMsg null, "#{value} must be  before #{parameters[0]}"

		#validate after date
		after : (el, parameters, value) ->
			if Date value > Date parameters[0]
				return this._validMsg null, "#{value} is after "+parameters[0]
			else return this._invalidMsg null, "#{value} must be  after "+parameters[0]

	Valitron.prototype.replacers =
		max : (message, attribute, rule, parameters) ->
			return message.replace(":max", parameters[0])
		min : (message, attribute, rule, parameters) ->
			return message.replace(":min", parameters[0])

	# valitron function
	$.fn[valitron_name] = (method, opts)->
		# create plugin instances for each selected element
		options = opts
		args = Array.prototype.slice.call arguments, 1
		rule_patt = /^rule_/i
		_t = $.map this, (el, idx) ->
			# check if its created on selected element
			_val = $.data el, valitron_name
			if !_val
				$.data el, valitron_name, _val = new Valitron( el )
			# call for pure validation functions no callbacks will be provided, and no chainability support!
			if rule_patt.test method
				return _val.validations[method.substr(5)]?.apply _val, args

			if typeof _val[method] == "function" and method.charAt 0 != "_"
				# console.log method, args
				_ret = _val[method] args
				# console.log "M:", method, options, _ret = _val[method] options
				if _ret?
					return _ret
				else
					return $(el)
			else if typeof method == 'object' # passing only options :)
				_val.setOptions method
				return $(el)
			else
				$.error "Method #{method} does not exists on jQuery.valitron"
			return $(el)
		# console.log "R:", _t[0]
		return _t[0]
	# for weirdos
	$.valitron = (el, options, opt2)->
		if typeof el == "string"
			if el =="config"
				if options? and typeof options == "object"
					$.extend true, config, options
					return this.$el
					# check for single option retrieval
				else if typeof options == "string"
					return config[options]
				else return config
			else if el == "options"
				if options? and typeof options == "object"
					defaults = this._extendOptions options
					return this.$el
				else if typeof options == "string"
					return defaults[options]
				else return defaults
			else if el == "translation"
				if options? and typeof options == "object"
					$.extend(true, translations, options)
					return this.$el
				else if typeof options == "string"
					return translations[options]
				else return translations
			# For new validation rule registration
			else if el == "rule" && typeof options == "string" && typeof opt2 == "function"
				this._register options opt2
			# For replacers registration
			else if el == "replacer" && typeof options == "string" && typeof opt2 == "function"
				this._replacer options opt2

		$.fn[valitron_name].apply el, Array.prototype.slice.call arguments, 1

	return

) jQuery, window, document