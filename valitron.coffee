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
			if el.is "SPAN"
				return el.text()

		_parseRules: (rules) ->
			rule = []
			_tmp = rules.split $.fn.valitron.config.ruleDelimiter # split rules to array
			# apply each rule to element
			$.each _tmp, (idx, value) ->
				# check if there is any rule, and its string
				if value != null and typeof value =='string' and value.length > 0
					# split rule into method name and its parameters
					_t = value.split $.fn.valitron.config.ruleMethodDelimiter 
					_t[0] = _t[0].trim()
					_t[1] = if _t[1] != undefined and _t[1] != null then _t[1].split $.fn.valitron.config.ruleParamDelimiter else null
					rule.push _t
			return rule


		_validateOne : (el, method, parameters) ->
			validations[method]? el, parameters, methods._resolveValue(el)

		validate: (options) ->
			_tmp = null
			$this = $(this)
			data = $this.data valitron_name
			opts = data.options
			_rls = methods._parseRules options.rules, $.fn.valitron.config.ruleDataElement
			_rls = _rls.concat(opts.rules);
			$.extend( true, opts, options)
			opts.rules = _rls
			console.log opts
			# applie rules
			$.each opts.rules, (idx, value) ->
				_re = methods._validateOne($this, value[0], value[1])
				if _re != null and _re != undefined # check if something is returned
					console.log typeof _re, _re, typeof opts.success
					if _re[0] == true
						_ret = opts.success?.call($this, _re[1])
					else
						_ret = opts.error?.call($this, _re[1])
					if _ret?
						consle.log "more"
				return
			return

	validations = 
		# validation rule declaration
		max : (el, parameters, value) ->
			_e = [
				false
				"Number is bigger then #{parameters}!"
			]
			_s = [
				true
				"Grats man"
			]
			console.log this
			if value > parameters[0]
				return _e
			else
				return _s

		min: (el, parameters, value) ->
			_e = [
				false
				"Number is smaller then #{parameters}!"
			]
			_s = [
				true
				"Grats man"
			]
			if value < parameters[0]
				return _e
			else
				return _s

	# valitron function
	$.fn.valitron = (method)->
		
		console.log "Metthod: #{method}"
		methods.init.apply this, arguments
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
		globSuccess : null # global success, this refers to jquery object
		globError : null # global error, this refers to jquery object
		ruleDelimiter : "|"
		ruleMethodDelimiter : ":"
		ruleParamDelimiter: ","
		ruleDataElement: 'validation'

	return
) jQuery