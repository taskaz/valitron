( ($, window, document ) ->

	valitron_name = 'valitron';

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

	config =
		globSuccess : (msg) -> # global success, this refers to jquery object
			$(this).removeClass "error"
		globError : (msg) -> # global error, this refers to jquery object
			$(this).addClass "error"
		ruleDelimiter : "|"
		ruleMethodDelimiter : ":"
		ruleParamDelimiter: ","
		ruleDataElement: 'validation'

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

		check : ( method, parameters, options ) ->
			# check if there is before callback

			if typeof options.beforeValidate == "function"
				_val = options.beforeValidate.call this.el, method, parameters, options
			if _val == null or _val ==undefined # check if before validation callback returns anything, if not parse value
				_val = this._resolveValue(this.$el)

			_re = this.validations[method]?.call this, this.$el, parameters, _val
			if _re != null and _re != undefined # check if something is returned
				# console.log $this.valitron.ruleReturns
				# validation passed
				if _re.result == true
					# if if element validation has success callback execute it
					if typeof options.success == "function"
						# call element validation callback, if returns something call globalSuccess colback too
						_ret = options.success?.call(this.el, _re.message, method, parameters) 
					# if not execute global callback
					else 
						config.globSuccess?.call(this.el, _re.message, method, parameters)
					# if element success callback returns anything call globalSuccess too
					if _ret
						config.globSuccess?.call(this.el, _re.message, method, parameters)
				# failed test, same checks as success case
				else
					if typeof options.error == "function"
						_ret = options.error?.call(this.el, _re.message, method, parameters)
					else config.globError?.call(this.el, _re.message, method, parameters)
					if _ret
						config.globError?.call(this.el, _re.message, method, parameters)
				if typeof options.afterValidate == "function"
					options.afterValidate.call this.el, _re.result, _re.message, method, parameters
			return _re;

		_ruleMsg : (res, transl, msg) ->
			_r =
				result : res
				translation : transl
				message : msg

			# if transl?
				# do translation and put it to message
			return _r

		# # hellper to return positive result from validation rule
		_validMsg : (transl, msg) ->
			return this._ruleMsg true, transl, msg

		# hellper to return error results from validation rule
		_invalidMsg : (transl, msg) ->
			return this._ruleMsg false, transl, msg

		_extendRules : (rules) ->
			_rls = this._parseRules(rules)
			if this.options?.rules?
				_rls = this.options.rules.concat _rls
			return _rls

		_extendOptions : (options) ->
			if options == null or typeof options == "undefined" then return $.extend(true, {}, defaults)
			# Extend current rules and save to temp var
			_rls = this._extendRules(options?.rules?)

			# Extend current options
			_t_opts = $.extend(true, {}, this.options, options)
			# Save extended rules to temorary options object
			_t_opts.rules = _rls
			return _t_opts


		# initialization logic
		init : ->
			# console.log "Init"
			return

		validate : (options) ->
			this.options = this._extendOptions(options)
			# applie rules
			self = this;
			_valid = true
			$.each.call this, this.options.rules, (idx, value) ->
				# Validate the rule
				_re = self.check value[0], value[1], self.options
				if _re.result == false
					_valid = false
					return

			this.options.valid = _valid
			return this.$el # for chainability

		isValid : ->
			return this.options.valid

		isInvalid : ->
			return !this.options.valid

		debug : ->
			console.log this.el
			console.log this.options
			console.log config


	Valitron.prototype.validations =
			# validate max value
			max : (el, parameters, value) ->
				if typeof value == "number" and value > parameters[0]
					return this._invalidMsg null, "Number is bigger then #{parameters}!"
				else if typeof value == "string" and value.length > parameters[0]
					this._invalidMsg null, "String is to long, should be max:#{parameters}!"
				else
					return this._validMsg  null, "Grats man"
			# validate min value
			min: (el, parameters, value) ->
				if typeof value == "number" and value < parameters[0]
					return this._invalidMsg null, "Number is smaller then #{parameters}!"
				else if typeof value == "string" and value.length < parameters[0]
					this._invalidMsg null, "String should be at least #{parameters} characters length!"
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
				pattern = "/^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/g";
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
				pattern = '/^([a-z])+$/i'
				if typeof value == "string"
					if pattern.test value
						return this._validMsg null, "This is alpha only"
					else return this._invalidMsg null, "Invalid value, can be only letters"
				else return this._invalidMsg null, "Cant check this type of value"

			# validate letters and numbers only
			alpha_num : (el, parameters, value) ->
				pattern = '/^([a-z0-9])+$/i'
				if typeof value == "string"
					if pattern.test value
						return this._validMsg null, "This is alpha only"
					else return this._invalidMsg null, "Invalid value, can be only letters"
				else return this._invalidMsg null, "Cant check this type of value"

			# validate letters numbers and dashes
			alpha_dash : (el, parameters, value) ->
				pattern = '/^([-a-z0-9_-])+$/i'
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

	# valitron function
	$.fn[valitron_name] = (method, opts)->
		# create plugin instances for each selected element
		options = opts
		return this.each ->
			# check if its created on selected element
			_val = $.data this, valitron_name
			if !_val
				$.data this, valitron_name, _val = new Valitron( this )

			if typeof _val[method] == "function" and method.charAt 0 != "_"
				return _val[method] options
			else if typeof method == 'object' # passing only options :)
				return _val.setOptions method
			else
				$.error "Method #{method} does not exists on jQuery.valitron"

		# return
	
	$.valitron = (cfg, options)->
		if options? and typeof options != undefined
			if cfg == "config"
				return $.extend(true, config, options)
			if cfg == "rule_defaults"
				return $.extend(true, defaults, options)
		else
			if cfg == "config"
				return config
			if cfg == "rule_defaults"
				return defaults

	return

) jQuery, window, document