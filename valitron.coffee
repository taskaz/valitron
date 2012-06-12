( ($) ->

	valitron_name = 'valitron';

	translate = ->
		return "bb"

	methods =
		init: (opts) ->
			return this.each ->
				$this = $(this)
				data = $this.data(valitron_name)
				# check if plugin already initialized on object
				if not data
					# no data, need to set up
					# extend default options
					$this.options = $.extend {}, $.fn.valitron.defaults, opts
					#put rules from element
					$this.options.rules = methods._parseRules $this.data $.fn.valitron.config.ruleDataElement
					$this.data valitron_name, $this

		_resolveValue: (el) ->
			if el.is "input:text, input:password, input:hidden"
				return el.val()
			if el.is "input:checkbox, input:radio"
				return el.is ":checked"
			else 
				return el.text()

		_parseRules: (rules) ->
			rule = []
			_tmp = rules?.split $.fn.valitron.config.ruleDelimiter # split rules to array
			# apply each rule to element
			if !_tmp 
				return rule
			$.each _tmp, (idx, value) ->
				# check if there is any rule, and its string
				if typeof value =='string' and value.length > 0
					# split rule into method name and its parameters
					_t = value.split $.fn.valitron.config.ruleMethodDelimiter 
					_t[0] = _t[0].trim()
					_t[1] = if _t[1] != undefined and _t[1] != null then _t[1].split $.fn.valitron.config.ruleParamDelimiter else null
					rule.push _t
			return rule


		_validateOne : (el, method, parameters) ->
			validations[method]?.call el.valitron, el, parameters, methods._resolveValue(el)

		validate: (options) ->
			# console.log this
			return this.each (options) ->
				# console.log this
				_tmp = null
				$this = $(this)
				data = $this.data valitron_name
				opts = data.options
				_rls = methods._parseRules options.rules, $.fn.valitron.config.ruleDataElement
				_rls = _rls.concat(opts.rules);
				$.extend( true, opts, options)
				opts.rules = _rls
				# applie rules
				$.each opts.rules, (idx, value) ->
					_re = methods._validateOne($this, value[0], value[1])
					if _re != null and _re != undefined # check if something is returned
						# console.log $this.valitron.ruleReturns
						# validation passed
						if _re.result == true 
							# if if element validation has success callback execute it
							if typeof opts.success == "function"
								# call element validation callback, if returns something call globalSuccess colback too
								_ret = opts.success?.call($this, _re.message) 
							# if not execute global callback
							else 
								$.fn.valitron.config.globSuccess?.call($this, _re.message)
							# if element success callback returns anything call globalSuccess too
							if _ret
								$.fn.valitron.config.globSuccess?.call($this, _re.message)
						# failed test, same checks as success case
						else
							if typeof opts.error == "function"
								_ret = opts.error?.call($this, _re.message)
							else $.fn.valitron.config.globError?.call($this, _re.message)
							if _ret
								$.fn.valitron.config.globError?.call($this, _re.message)
					return

	validations = 
		# validation rule declaration
		max : (el, parameters, value) ->
			# console.log this
			if value > parameters[0]
				return this.invalidMsg null, "Number is bigger then #{parameters}!"
			else
				return this.validMsg  null, "Grats man"

		min: (el, parameters, value) ->
			if value < parameters[0]
				return this.invalidMsg null, "Number is smaller then #{parameters}!"
			else
				return this.validMsg null, "Grats man"

		required: (el, parameters, value) ->
			console.log typeof value, value
			if value == null or value == undefined
				return this.invalidMsg null, "Value must be set to something!"
			else if typeof value == "string" and (value.length <= 0 or value == "")
				return this.invalidMsg null, "Value must be set to something!"
			else if typeof value == "boolean" or typeof value == "number"
				return if Boolean(value) then this.validMsg null, "Grats man" else this.invalidMsg null, "Value must be set to something!"
			else return this.validMsg null, "Grats man"


	# valitron function
	$.fn.valitron = (method)->
		
		# console.log "Method: #{method}"
		init = methods.init.apply this, arguments
		if methods[method] and method.charAt 0 != "_"
			return methods[method].apply this, Array.prototype.slice.call arguments, 1
		else if not method or typeof method == 'object'
			return methods.init.apply this, arguments
		else
			$.error "Method #{method} does not exists on jQuery.valitron"

		return


	# this is passed to valiation option some parameters might be predefined :)
	$.fn.valitron.defaults =
		rules: null # rules to check, default "|" delimiter, ":" parameters, ex: max:5|min:2
		language : 'en' # default language to use for errors, somehow should be loaded :)
		# passes jQuery element and message, function(message) {}, this refers to jquery object
		# global success will not be fired! return value witch evolutes to tru to fire it!
		success : null 
		# passes jQuery element and message, function(messagae) {}, this refers to jquery object
		# global error will not be fired! return value witch evolutes to tru to fire it!
		error : null

	$.fn.valitron.config =
		globSuccess : (msg) -> # global success, this refers to jquery object
			console.log msg
			this.removeClass "error"
		globError : (msg) -> # global error, this refers to jquery object
			console.log msg
			this.addClass "error"
		ruleDelimiter : "|"
		ruleMethodDelimiter : ":"
		ruleParamDelimiter: ","
		ruleDataElement: 'validation'

	# a hellper to set return data for validation methods
	$.fn.valitron.ruleMsg = (res, transl, msg) ->
		_r =
			result : res
			translation : transl
			message : msg

		# if transl?
			# do translation and put it to message
		return _r
	# hellper to return positive result from validation rule
	$.fn.valitron.validMsg = (transl, msg) ->
		return this.ruleMsg true, transl, msg
	# hellper to return error results from validation rule
	$.fn.valitron.invalidMsg = (transl, msg) ->
		return this.ruleMsg false, transl, msg

	return
) jQuery