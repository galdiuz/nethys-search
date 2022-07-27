(function(scope){
'use strict';

function F(arity, fun, wrapper) {
  wrapper.a = arity;
  wrapper.f = fun;
  return wrapper;
}

function F2(fun) {
  return F(2, fun, function(a) { return function(b) { return fun(a,b); }; })
}
function F3(fun) {
  return F(3, fun, function(a) {
    return function(b) { return function(c) { return fun(a, b, c); }; };
  });
}
function F4(fun) {
  return F(4, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return fun(a, b, c, d); }; }; };
  });
}
function F5(fun) {
  return F(5, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return fun(a, b, c, d, e); }; }; }; };
  });
}
function F6(fun) {
  return F(6, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return fun(a, b, c, d, e, f); }; }; }; }; };
  });
}
function F7(fun) {
  return F(7, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return fun(a, b, c, d, e, f, g); }; }; }; }; }; };
  });
}
function F8(fun) {
  return F(8, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) {
    return fun(a, b, c, d, e, f, g, h); }; }; }; }; }; }; };
  });
}
function F9(fun) {
  return F(9, fun, function(a) { return function(b) { return function(c) {
    return function(d) { return function(e) { return function(f) {
    return function(g) { return function(h) { return function(i) {
    return fun(a, b, c, d, e, f, g, h, i); }; }; }; }; }; }; }; };
  });
}

function A2(fun, a, b) {
  return fun.a === 2 ? fun.f(a, b) : fun(a)(b);
}
function A3(fun, a, b, c) {
  return fun.a === 3 ? fun.f(a, b, c) : fun(a)(b)(c);
}
function A4(fun, a, b, c, d) {
  return fun.a === 4 ? fun.f(a, b, c, d) : fun(a)(b)(c)(d);
}
function A5(fun, a, b, c, d, e) {
  return fun.a === 5 ? fun.f(a, b, c, d, e) : fun(a)(b)(c)(d)(e);
}
function A6(fun, a, b, c, d, e, f) {
  return fun.a === 6 ? fun.f(a, b, c, d, e, f) : fun(a)(b)(c)(d)(e)(f);
}
function A7(fun, a, b, c, d, e, f, g) {
  return fun.a === 7 ? fun.f(a, b, c, d, e, f, g) : fun(a)(b)(c)(d)(e)(f)(g);
}
function A8(fun, a, b, c, d, e, f, g, h) {
  return fun.a === 8 ? fun.f(a, b, c, d, e, f, g, h) : fun(a)(b)(c)(d)(e)(f)(g)(h);
}
function A9(fun, a, b, c, d, e, f, g, h, i) {
  return fun.a === 9 ? fun.f(a, b, c, d, e, f, g, h, i) : fun(a)(b)(c)(d)(e)(f)(g)(h)(i);
}

console.warn('Compiled in DEV mode. Follow the advice at https://elm-lang.org/0.19.1/optimize for better performance and smaller assets.');


// EQUALITY

function _Utils_eq(x, y)
{
	for (
		var pair, stack = [], isEqual = _Utils_eqHelp(x, y, 0, stack);
		isEqual && (pair = stack.pop());
		isEqual = _Utils_eqHelp(pair.a, pair.b, 0, stack)
		)
	{}

	return isEqual;
}

function _Utils_eqHelp(x, y, depth, stack)
{
	if (x === y)
	{
		return true;
	}

	if (typeof x !== 'object' || x === null || y === null)
	{
		typeof x === 'function' && _Debug_crash(5);
		return false;
	}

	if (depth > 100)
	{
		stack.push(_Utils_Tuple2(x,y));
		return true;
	}

	/**/
	if (x.$ === 'Set_elm_builtin')
	{
		x = $elm$core$Set$toList(x);
		y = $elm$core$Set$toList(y);
	}
	if (x.$ === 'RBNode_elm_builtin' || x.$ === 'RBEmpty_elm_builtin')
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	/**_UNUSED/
	if (x.$ < 0)
	{
		x = $elm$core$Dict$toList(x);
		y = $elm$core$Dict$toList(y);
	}
	//*/

	for (var key in x)
	{
		if (!_Utils_eqHelp(x[key], y[key], depth + 1, stack))
		{
			return false;
		}
	}
	return true;
}

var _Utils_equal = F2(_Utils_eq);
var _Utils_notEqual = F2(function(a, b) { return !_Utils_eq(a,b); });



// COMPARISONS

// Code in Generate/JavaScript.hs, Basics.js, and List.js depends on
// the particular integer values assigned to LT, EQ, and GT.

function _Utils_cmp(x, y, ord)
{
	if (typeof x !== 'object')
	{
		return x === y ? /*EQ*/ 0 : x < y ? /*LT*/ -1 : /*GT*/ 1;
	}

	/**/
	if (x instanceof String)
	{
		var a = x.valueOf();
		var b = y.valueOf();
		return a === b ? 0 : a < b ? -1 : 1;
	}
	//*/

	/**_UNUSED/
	if (typeof x.$ === 'undefined')
	//*/
	/**/
	if (x.$[0] === '#')
	//*/
	{
		return (ord = _Utils_cmp(x.a, y.a))
			? ord
			: (ord = _Utils_cmp(x.b, y.b))
				? ord
				: _Utils_cmp(x.c, y.c);
	}

	// traverse conses until end of a list or a mismatch
	for (; x.b && y.b && !(ord = _Utils_cmp(x.a, y.a)); x = x.b, y = y.b) {} // WHILE_CONSES
	return ord || (x.b ? /*GT*/ 1 : y.b ? /*LT*/ -1 : /*EQ*/ 0);
}

var _Utils_lt = F2(function(a, b) { return _Utils_cmp(a, b) < 0; });
var _Utils_le = F2(function(a, b) { return _Utils_cmp(a, b) < 1; });
var _Utils_gt = F2(function(a, b) { return _Utils_cmp(a, b) > 0; });
var _Utils_ge = F2(function(a, b) { return _Utils_cmp(a, b) >= 0; });

var _Utils_compare = F2(function(x, y)
{
	var n = _Utils_cmp(x, y);
	return n < 0 ? $elm$core$Basics$LT : n ? $elm$core$Basics$GT : $elm$core$Basics$EQ;
});


// COMMON VALUES

var _Utils_Tuple0_UNUSED = 0;
var _Utils_Tuple0 = { $: '#0' };

function _Utils_Tuple2_UNUSED(a, b) { return { a: a, b: b }; }
function _Utils_Tuple2(a, b) { return { $: '#2', a: a, b: b }; }

function _Utils_Tuple3_UNUSED(a, b, c) { return { a: a, b: b, c: c }; }
function _Utils_Tuple3(a, b, c) { return { $: '#3', a: a, b: b, c: c }; }

function _Utils_chr_UNUSED(c) { return c; }
function _Utils_chr(c) { return new String(c); }


// RECORDS

function _Utils_update(oldRecord, updatedFields)
{
	var newRecord = {};

	for (var key in oldRecord)
	{
		newRecord[key] = oldRecord[key];
	}

	for (var key in updatedFields)
	{
		newRecord[key] = updatedFields[key];
	}

	return newRecord;
}


// APPEND

var _Utils_append = F2(_Utils_ap);

function _Utils_ap(xs, ys)
{
	// append Strings
	if (typeof xs === 'string')
	{
		return xs + ys;
	}

	// append Lists
	if (!xs.b)
	{
		return ys;
	}
	var root = _List_Cons(xs.a, ys);
	xs = xs.b
	for (var curr = root; xs.b; xs = xs.b) // WHILE_CONS
	{
		curr = curr.b = _List_Cons(xs.a, ys);
	}
	return root;
}



var _List_Nil_UNUSED = { $: 0 };
var _List_Nil = { $: '[]' };

function _List_Cons_UNUSED(hd, tl) { return { $: 1, a: hd, b: tl }; }
function _List_Cons(hd, tl) { return { $: '::', a: hd, b: tl }; }


var _List_cons = F2(_List_Cons);

function _List_fromArray(arr)
{
	var out = _List_Nil;
	for (var i = arr.length; i--; )
	{
		out = _List_Cons(arr[i], out);
	}
	return out;
}

function _List_toArray(xs)
{
	for (var out = []; xs.b; xs = xs.b) // WHILE_CONS
	{
		out.push(xs.a);
	}
	return out;
}

var _List_map2 = F3(function(f, xs, ys)
{
	for (var arr = []; xs.b && ys.b; xs = xs.b, ys = ys.b) // WHILE_CONSES
	{
		arr.push(A2(f, xs.a, ys.a));
	}
	return _List_fromArray(arr);
});

var _List_map3 = F4(function(f, xs, ys, zs)
{
	for (var arr = []; xs.b && ys.b && zs.b; xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A3(f, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map4 = F5(function(f, ws, xs, ys, zs)
{
	for (var arr = []; ws.b && xs.b && ys.b && zs.b; ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A4(f, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_map5 = F6(function(f, vs, ws, xs, ys, zs)
{
	for (var arr = []; vs.b && ws.b && xs.b && ys.b && zs.b; vs = vs.b, ws = ws.b, xs = xs.b, ys = ys.b, zs = zs.b) // WHILE_CONSES
	{
		arr.push(A5(f, vs.a, ws.a, xs.a, ys.a, zs.a));
	}
	return _List_fromArray(arr);
});

var _List_sortBy = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		return _Utils_cmp(f(a), f(b));
	}));
});

var _List_sortWith = F2(function(f, xs)
{
	return _List_fromArray(_List_toArray(xs).sort(function(a, b) {
		var ord = A2(f, a, b);
		return ord === $elm$core$Basics$EQ ? 0 : ord === $elm$core$Basics$LT ? -1 : 1;
	}));
});



var _JsArray_empty = [];

function _JsArray_singleton(value)
{
    return [value];
}

function _JsArray_length(array)
{
    return array.length;
}

var _JsArray_initialize = F3(function(size, offset, func)
{
    var result = new Array(size);

    for (var i = 0; i < size; i++)
    {
        result[i] = func(offset + i);
    }

    return result;
});

var _JsArray_initializeFromList = F2(function (max, ls)
{
    var result = new Array(max);

    for (var i = 0; i < max && ls.b; i++)
    {
        result[i] = ls.a;
        ls = ls.b;
    }

    result.length = i;
    return _Utils_Tuple2(result, ls);
});

var _JsArray_unsafeGet = F2(function(index, array)
{
    return array[index];
});

var _JsArray_unsafeSet = F3(function(index, value, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[index] = value;
    return result;
});

var _JsArray_push = F2(function(value, array)
{
    var length = array.length;
    var result = new Array(length + 1);

    for (var i = 0; i < length; i++)
    {
        result[i] = array[i];
    }

    result[length] = value;
    return result;
});

var _JsArray_foldl = F3(function(func, acc, array)
{
    var length = array.length;

    for (var i = 0; i < length; i++)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_foldr = F3(function(func, acc, array)
{
    for (var i = array.length - 1; i >= 0; i--)
    {
        acc = A2(func, array[i], acc);
    }

    return acc;
});

var _JsArray_map = F2(function(func, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = func(array[i]);
    }

    return result;
});

var _JsArray_indexedMap = F3(function(func, offset, array)
{
    var length = array.length;
    var result = new Array(length);

    for (var i = 0; i < length; i++)
    {
        result[i] = A2(func, offset + i, array[i]);
    }

    return result;
});

var _JsArray_slice = F3(function(from, to, array)
{
    return array.slice(from, to);
});

var _JsArray_appendN = F3(function(n, dest, source)
{
    var destLen = dest.length;
    var itemsToCopy = n - destLen;

    if (itemsToCopy > source.length)
    {
        itemsToCopy = source.length;
    }

    var size = destLen + itemsToCopy;
    var result = new Array(size);

    for (var i = 0; i < destLen; i++)
    {
        result[i] = dest[i];
    }

    for (var i = 0; i < itemsToCopy; i++)
    {
        result[i + destLen] = source[i];
    }

    return result;
});



// LOG

var _Debug_log_UNUSED = F2(function(tag, value)
{
	return value;
});

var _Debug_log = F2(function(tag, value)
{
	console.log(tag + ': ' + _Debug_toString(value));
	return value;
});


// TODOS

function _Debug_todo(moduleName, region)
{
	return function(message) {
		_Debug_crash(8, moduleName, region, message);
	};
}

function _Debug_todoCase(moduleName, region, value)
{
	return function(message) {
		_Debug_crash(9, moduleName, region, value, message);
	};
}


// TO STRING

function _Debug_toString_UNUSED(value)
{
	return '<internals>';
}

function _Debug_toString(value)
{
	return _Debug_toAnsiString(false, value);
}

function _Debug_toAnsiString(ansi, value)
{
	if (typeof value === 'function')
	{
		return _Debug_internalColor(ansi, '<function>');
	}

	if (typeof value === 'boolean')
	{
		return _Debug_ctorColor(ansi, value ? 'True' : 'False');
	}

	if (typeof value === 'number')
	{
		return _Debug_numberColor(ansi, value + '');
	}

	if (value instanceof String)
	{
		return _Debug_charColor(ansi, "'" + _Debug_addSlashes(value, true) + "'");
	}

	if (typeof value === 'string')
	{
		return _Debug_stringColor(ansi, '"' + _Debug_addSlashes(value, false) + '"');
	}

	if (typeof value === 'object' && '$' in value)
	{
		var tag = value.$;

		if (typeof tag === 'number')
		{
			return _Debug_internalColor(ansi, '<internals>');
		}

		if (tag[0] === '#')
		{
			var output = [];
			for (var k in value)
			{
				if (k === '$') continue;
				output.push(_Debug_toAnsiString(ansi, value[k]));
			}
			return '(' + output.join(',') + ')';
		}

		if (tag === 'Set_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Set')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Set$toList(value));
		}

		if (tag === 'RBNode_elm_builtin' || tag === 'RBEmpty_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Dict')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Dict$toList(value));
		}

		if (tag === 'Array_elm_builtin')
		{
			return _Debug_ctorColor(ansi, 'Array')
				+ _Debug_fadeColor(ansi, '.fromList') + ' '
				+ _Debug_toAnsiString(ansi, $elm$core$Array$toList(value));
		}

		if (tag === '::' || tag === '[]')
		{
			var output = '[';

			value.b && (output += _Debug_toAnsiString(ansi, value.a), value = value.b)

			for (; value.b; value = value.b) // WHILE_CONS
			{
				output += ',' + _Debug_toAnsiString(ansi, value.a);
			}
			return output + ']';
		}

		var output = '';
		for (var i in value)
		{
			if (i === '$') continue;
			var str = _Debug_toAnsiString(ansi, value[i]);
			var c0 = str[0];
			var parenless = c0 === '{' || c0 === '(' || c0 === '[' || c0 === '<' || c0 === '"' || str.indexOf(' ') < 0;
			output += ' ' + (parenless ? str : '(' + str + ')');
		}
		return _Debug_ctorColor(ansi, tag) + output;
	}

	if (typeof DataView === 'function' && value instanceof DataView)
	{
		return _Debug_stringColor(ansi, '<' + value.byteLength + ' bytes>');
	}

	if (typeof File !== 'undefined' && value instanceof File)
	{
		return _Debug_internalColor(ansi, '<' + value.name + '>');
	}

	if (typeof value === 'object')
	{
		var output = [];
		for (var key in value)
		{
			var field = key[0] === '_' ? key.slice(1) : key;
			output.push(_Debug_fadeColor(ansi, field) + ' = ' + _Debug_toAnsiString(ansi, value[key]));
		}
		if (output.length === 0)
		{
			return '{}';
		}
		return '{ ' + output.join(', ') + ' }';
	}

	return _Debug_internalColor(ansi, '<internals>');
}

function _Debug_addSlashes(str, isChar)
{
	var s = str
		.replace(/\\/g, '\\\\')
		.replace(/\n/g, '\\n')
		.replace(/\t/g, '\\t')
		.replace(/\r/g, '\\r')
		.replace(/\v/g, '\\v')
		.replace(/\0/g, '\\0');

	if (isChar)
	{
		return s.replace(/\'/g, '\\\'');
	}
	else
	{
		return s.replace(/\"/g, '\\"');
	}
}

function _Debug_ctorColor(ansi, string)
{
	return ansi ? '\x1b[96m' + string + '\x1b[0m' : string;
}

function _Debug_numberColor(ansi, string)
{
	return ansi ? '\x1b[95m' + string + '\x1b[0m' : string;
}

function _Debug_stringColor(ansi, string)
{
	return ansi ? '\x1b[93m' + string + '\x1b[0m' : string;
}

function _Debug_charColor(ansi, string)
{
	return ansi ? '\x1b[92m' + string + '\x1b[0m' : string;
}

function _Debug_fadeColor(ansi, string)
{
	return ansi ? '\x1b[37m' + string + '\x1b[0m' : string;
}

function _Debug_internalColor(ansi, string)
{
	return ansi ? '\x1b[36m' + string + '\x1b[0m' : string;
}

function _Debug_toHexDigit(n)
{
	return String.fromCharCode(n < 10 ? 48 + n : 55 + n);
}


// CRASH


function _Debug_crash_UNUSED(identifier)
{
	throw new Error('https://github.com/elm/core/blob/1.0.0/hints/' + identifier + '.md');
}


function _Debug_crash(identifier, fact1, fact2, fact3, fact4)
{
	switch(identifier)
	{
		case 0:
			throw new Error('What node should I take over? In JavaScript I need something like:\n\n    Elm.Main.init({\n        node: document.getElementById("elm-node")\n    })\n\nYou need to do this with any Browser.sandbox or Browser.element program.');

		case 1:
			throw new Error('Browser.application programs cannot handle URLs like this:\n\n    ' + document.location.href + '\n\nWhat is the root? The root of your file system? Try looking at this program with `elm reactor` or some other server.');

		case 2:
			var jsonErrorString = fact1;
			throw new Error('Problem with the flags given to your Elm program on initialization.\n\n' + jsonErrorString);

		case 3:
			var portName = fact1;
			throw new Error('There can only be one port named `' + portName + '`, but your program has multiple.');

		case 4:
			var portName = fact1;
			var problem = fact2;
			throw new Error('Trying to send an unexpected type of value through port `' + portName + '`:\n' + problem);

		case 5:
			throw new Error('Trying to use `(==)` on functions.\nThere is no way to know if functions are "the same" in the Elm sense.\nRead more about this at https://package.elm-lang.org/packages/elm/core/latest/Basics#== which describes why it is this way and what the better version will look like.');

		case 6:
			var moduleName = fact1;
			throw new Error('Your page is loading multiple Elm scripts with a module named ' + moduleName + '. Maybe a duplicate script is getting loaded accidentally? If not, rename one of them so I know which is which!');

		case 8:
			var moduleName = fact1;
			var region = fact2;
			var message = fact3;
			throw new Error('TODO in module `' + moduleName + '` ' + _Debug_regionToString(region) + '\n\n' + message);

		case 9:
			var moduleName = fact1;
			var region = fact2;
			var value = fact3;
			var message = fact4;
			throw new Error(
				'TODO in module `' + moduleName + '` from the `case` expression '
				+ _Debug_regionToString(region) + '\n\nIt received the following value:\n\n    '
				+ _Debug_toString(value).replace('\n', '\n    ')
				+ '\n\nBut the branch that handles it says:\n\n    ' + message.replace('\n', '\n    ')
			);

		case 10:
			throw new Error('Bug in https://github.com/elm/virtual-dom/issues');

		case 11:
			throw new Error('Cannot perform mod 0. Division by zero error.');
	}
}

function _Debug_regionToString(region)
{
	if (region.start.line === region.end.line)
	{
		return 'on line ' + region.start.line;
	}
	return 'on lines ' + region.start.line + ' through ' + region.end.line;
}



// MATH

var _Basics_add = F2(function(a, b) { return a + b; });
var _Basics_sub = F2(function(a, b) { return a - b; });
var _Basics_mul = F2(function(a, b) { return a * b; });
var _Basics_fdiv = F2(function(a, b) { return a / b; });
var _Basics_idiv = F2(function(a, b) { return (a / b) | 0; });
var _Basics_pow = F2(Math.pow);

var _Basics_remainderBy = F2(function(b, a) { return a % b; });

// https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/divmodnote-letter.pdf
var _Basics_modBy = F2(function(modulus, x)
{
	var answer = x % modulus;
	return modulus === 0
		? _Debug_crash(11)
		:
	((answer > 0 && modulus < 0) || (answer < 0 && modulus > 0))
		? answer + modulus
		: answer;
});


// TRIGONOMETRY

var _Basics_pi = Math.PI;
var _Basics_e = Math.E;
var _Basics_cos = Math.cos;
var _Basics_sin = Math.sin;
var _Basics_tan = Math.tan;
var _Basics_acos = Math.acos;
var _Basics_asin = Math.asin;
var _Basics_atan = Math.atan;
var _Basics_atan2 = F2(Math.atan2);


// MORE MATH

function _Basics_toFloat(x) { return x; }
function _Basics_truncate(n) { return n | 0; }
function _Basics_isInfinite(n) { return n === Infinity || n === -Infinity; }

var _Basics_ceiling = Math.ceil;
var _Basics_floor = Math.floor;
var _Basics_round = Math.round;
var _Basics_sqrt = Math.sqrt;
var _Basics_log = Math.log;
var _Basics_isNaN = isNaN;


// BOOLEANS

function _Basics_not(bool) { return !bool; }
var _Basics_and = F2(function(a, b) { return a && b; });
var _Basics_or  = F2(function(a, b) { return a || b; });
var _Basics_xor = F2(function(a, b) { return a !== b; });



var _String_cons = F2(function(chr, str)
{
	return chr + str;
});

function _String_uncons(string)
{
	var word = string.charCodeAt(0);
	return !isNaN(word)
		? $elm$core$Maybe$Just(
			0xD800 <= word && word <= 0xDBFF
				? _Utils_Tuple2(_Utils_chr(string[0] + string[1]), string.slice(2))
				: _Utils_Tuple2(_Utils_chr(string[0]), string.slice(1))
		)
		: $elm$core$Maybe$Nothing;
}

var _String_append = F2(function(a, b)
{
	return a + b;
});

function _String_length(str)
{
	return str.length;
}

var _String_map = F2(function(func, string)
{
	var len = string.length;
	var array = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = string.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			array[i] = func(_Utils_chr(string[i] + string[i+1]));
			i += 2;
			continue;
		}
		array[i] = func(_Utils_chr(string[i]));
		i++;
	}
	return array.join('');
});

var _String_filter = F2(function(isGood, str)
{
	var arr = [];
	var len = str.length;
	var i = 0;
	while (i < len)
	{
		var char = str[i];
		var word = str.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += str[i];
			i++;
		}

		if (isGood(_Utils_chr(char)))
		{
			arr.push(char);
		}
	}
	return arr.join('');
});

function _String_reverse(str)
{
	var len = str.length;
	var arr = new Array(len);
	var i = 0;
	while (i < len)
	{
		var word = str.charCodeAt(i);
		if (0xD800 <= word && word <= 0xDBFF)
		{
			arr[len - i] = str[i + 1];
			i++;
			arr[len - i] = str[i - 1];
			i++;
		}
		else
		{
			arr[len - i] = str[i];
			i++;
		}
	}
	return arr.join('');
}

var _String_foldl = F3(function(func, state, string)
{
	var len = string.length;
	var i = 0;
	while (i < len)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		i++;
		if (0xD800 <= word && word <= 0xDBFF)
		{
			char += string[i];
			i++;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_foldr = F3(function(func, state, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		state = A2(func, _Utils_chr(char), state);
	}
	return state;
});

var _String_split = F2(function(sep, str)
{
	return str.split(sep);
});

var _String_join = F2(function(sep, strs)
{
	return strs.join(sep);
});

var _String_slice = F3(function(start, end, str) {
	return str.slice(start, end);
});

function _String_trim(str)
{
	return str.trim();
}

function _String_trimLeft(str)
{
	return str.replace(/^\s+/, '');
}

function _String_trimRight(str)
{
	return str.replace(/\s+$/, '');
}

function _String_words(str)
{
	return _List_fromArray(str.trim().split(/\s+/g));
}

function _String_lines(str)
{
	return _List_fromArray(str.split(/\r\n|\r|\n/g));
}

function _String_toUpper(str)
{
	return str.toUpperCase();
}

function _String_toLower(str)
{
	return str.toLowerCase();
}

var _String_any = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (isGood(_Utils_chr(char)))
		{
			return true;
		}
	}
	return false;
});

var _String_all = F2(function(isGood, string)
{
	var i = string.length;
	while (i--)
	{
		var char = string[i];
		var word = string.charCodeAt(i);
		if (0xDC00 <= word && word <= 0xDFFF)
		{
			i--;
			char = string[i] + char;
		}
		if (!isGood(_Utils_chr(char)))
		{
			return false;
		}
	}
	return true;
});

var _String_contains = F2(function(sub, str)
{
	return str.indexOf(sub) > -1;
});

var _String_startsWith = F2(function(sub, str)
{
	return str.indexOf(sub) === 0;
});

var _String_endsWith = F2(function(sub, str)
{
	return str.length >= sub.length &&
		str.lastIndexOf(sub) === str.length - sub.length;
});

var _String_indexes = F2(function(sub, str)
{
	var subLen = sub.length;

	if (subLen < 1)
	{
		return _List_Nil;
	}

	var i = 0;
	var is = [];

	while ((i = str.indexOf(sub, i)) > -1)
	{
		is.push(i);
		i = i + subLen;
	}

	return _List_fromArray(is);
});


// TO STRING

function _String_fromNumber(number)
{
	return number + '';
}


// INT CONVERSIONS

function _String_toInt(str)
{
	var total = 0;
	var code0 = str.charCodeAt(0);
	var start = code0 == 0x2B /* + */ || code0 == 0x2D /* - */ ? 1 : 0;

	for (var i = start; i < str.length; ++i)
	{
		var code = str.charCodeAt(i);
		if (code < 0x30 || 0x39 < code)
		{
			return $elm$core$Maybe$Nothing;
		}
		total = 10 * total + code - 0x30;
	}

	return i == start
		? $elm$core$Maybe$Nothing
		: $elm$core$Maybe$Just(code0 == 0x2D ? -total : total);
}


// FLOAT CONVERSIONS

function _String_toFloat(s)
{
	// check if it is a hex, octal, or binary number
	if (s.length === 0 || /[\sxbo]/.test(s))
	{
		return $elm$core$Maybe$Nothing;
	}
	var n = +s;
	// faster isNaN check
	return n === n ? $elm$core$Maybe$Just(n) : $elm$core$Maybe$Nothing;
}

function _String_fromList(chars)
{
	return _List_toArray(chars).join('');
}




function _Char_toCode(char)
{
	var code = char.charCodeAt(0);
	if (0xD800 <= code && code <= 0xDBFF)
	{
		return (code - 0xD800) * 0x400 + char.charCodeAt(1) - 0xDC00 + 0x10000
	}
	return code;
}

function _Char_fromCode(code)
{
	return _Utils_chr(
		(code < 0 || 0x10FFFF < code)
			? '\uFFFD'
			:
		(code <= 0xFFFF)
			? String.fromCharCode(code)
			:
		(code -= 0x10000,
			String.fromCharCode(Math.floor(code / 0x400) + 0xD800, code % 0x400 + 0xDC00)
		)
	);
}

function _Char_toUpper(char)
{
	return _Utils_chr(char.toUpperCase());
}

function _Char_toLower(char)
{
	return _Utils_chr(char.toLowerCase());
}

function _Char_toLocaleUpper(char)
{
	return _Utils_chr(char.toLocaleUpperCase());
}

function _Char_toLocaleLower(char)
{
	return _Utils_chr(char.toLocaleLowerCase());
}



/**/
function _Json_errorToString(error)
{
	return $elm$json$Json$Decode$errorToString(error);
}
//*/


// CORE DECODERS

function _Json_succeed(msg)
{
	return {
		$: 0,
		a: msg
	};
}

function _Json_fail(msg)
{
	return {
		$: 1,
		a: msg
	};
}

function _Json_decodePrim(decoder)
{
	return { $: 2, b: decoder };
}

var _Json_decodeInt = _Json_decodePrim(function(value) {
	return (typeof value !== 'number')
		? _Json_expecting('an INT', value)
		:
	(-2147483647 < value && value < 2147483647 && (value | 0) === value)
		? $elm$core$Result$Ok(value)
		:
	(isFinite(value) && !(value % 1))
		? $elm$core$Result$Ok(value)
		: _Json_expecting('an INT', value);
});

var _Json_decodeBool = _Json_decodePrim(function(value) {
	return (typeof value === 'boolean')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a BOOL', value);
});

var _Json_decodeFloat = _Json_decodePrim(function(value) {
	return (typeof value === 'number')
		? $elm$core$Result$Ok(value)
		: _Json_expecting('a FLOAT', value);
});

var _Json_decodeValue = _Json_decodePrim(function(value) {
	return $elm$core$Result$Ok(_Json_wrap(value));
});

var _Json_decodeString = _Json_decodePrim(function(value) {
	return (typeof value === 'string')
		? $elm$core$Result$Ok(value)
		: (value instanceof String)
			? $elm$core$Result$Ok(value + '')
			: _Json_expecting('a STRING', value);
});

function _Json_decodeList(decoder) { return { $: 3, b: decoder }; }
function _Json_decodeArray(decoder) { return { $: 4, b: decoder }; }

function _Json_decodeNull(value) { return { $: 5, c: value }; }

var _Json_decodeField = F2(function(field, decoder)
{
	return {
		$: 6,
		d: field,
		b: decoder
	};
});

var _Json_decodeIndex = F2(function(index, decoder)
{
	return {
		$: 7,
		e: index,
		b: decoder
	};
});

function _Json_decodeKeyValuePairs(decoder)
{
	return {
		$: 8,
		b: decoder
	};
}

function _Json_mapMany(f, decoders)
{
	return {
		$: 9,
		f: f,
		g: decoders
	};
}

var _Json_andThen = F2(function(callback, decoder)
{
	return {
		$: 10,
		b: decoder,
		h: callback
	};
});

function _Json_oneOf(decoders)
{
	return {
		$: 11,
		g: decoders
	};
}


// DECODING OBJECTS

var _Json_map1 = F2(function(f, d1)
{
	return _Json_mapMany(f, [d1]);
});

var _Json_map2 = F3(function(f, d1, d2)
{
	return _Json_mapMany(f, [d1, d2]);
});

var _Json_map3 = F4(function(f, d1, d2, d3)
{
	return _Json_mapMany(f, [d1, d2, d3]);
});

var _Json_map4 = F5(function(f, d1, d2, d3, d4)
{
	return _Json_mapMany(f, [d1, d2, d3, d4]);
});

var _Json_map5 = F6(function(f, d1, d2, d3, d4, d5)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5]);
});

var _Json_map6 = F7(function(f, d1, d2, d3, d4, d5, d6)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6]);
});

var _Json_map7 = F8(function(f, d1, d2, d3, d4, d5, d6, d7)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7]);
});

var _Json_map8 = F9(function(f, d1, d2, d3, d4, d5, d6, d7, d8)
{
	return _Json_mapMany(f, [d1, d2, d3, d4, d5, d6, d7, d8]);
});


// DECODE

var _Json_runOnString = F2(function(decoder, string)
{
	try
	{
		var value = JSON.parse(string);
		return _Json_runHelp(decoder, value);
	}
	catch (e)
	{
		return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'This is not valid JSON! ' + e.message, _Json_wrap(string)));
	}
});

var _Json_run = F2(function(decoder, value)
{
	return _Json_runHelp(decoder, _Json_unwrap(value));
});

function _Json_runHelp(decoder, value)
{
	switch (decoder.$)
	{
		case 2:
			return decoder.b(value);

		case 5:
			return (value === null)
				? $elm$core$Result$Ok(decoder.c)
				: _Json_expecting('null', value);

		case 3:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('a LIST', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _List_fromArray);

		case 4:
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			return _Json_runArrayDecoder(decoder.b, value, _Json_toElmArray);

		case 6:
			var field = decoder.d;
			if (typeof value !== 'object' || value === null || !(field in value))
			{
				return _Json_expecting('an OBJECT with a field named `' + field + '`', value);
			}
			var result = _Json_runHelp(decoder.b, value[field]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, field, result.a));

		case 7:
			var index = decoder.e;
			if (!_Json_isArray(value))
			{
				return _Json_expecting('an ARRAY', value);
			}
			if (index >= value.length)
			{
				return _Json_expecting('a LONGER array. Need index ' + index + ' but only see ' + value.length + ' entries', value);
			}
			var result = _Json_runHelp(decoder.b, value[index]);
			return ($elm$core$Result$isOk(result)) ? result : $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, index, result.a));

		case 8:
			if (typeof value !== 'object' || value === null || _Json_isArray(value))
			{
				return _Json_expecting('an OBJECT', value);
			}

			var keyValuePairs = _List_Nil;
			// TODO test perf of Object.keys and switch when support is good enough
			for (var key in value)
			{
				if (value.hasOwnProperty(key))
				{
					var result = _Json_runHelp(decoder.b, value[key]);
					if (!$elm$core$Result$isOk(result))
					{
						return $elm$core$Result$Err(A2($elm$json$Json$Decode$Field, key, result.a));
					}
					keyValuePairs = _List_Cons(_Utils_Tuple2(key, result.a), keyValuePairs);
				}
			}
			return $elm$core$Result$Ok($elm$core$List$reverse(keyValuePairs));

		case 9:
			var answer = decoder.f;
			var decoders = decoder.g;
			for (var i = 0; i < decoders.length; i++)
			{
				var result = _Json_runHelp(decoders[i], value);
				if (!$elm$core$Result$isOk(result))
				{
					return result;
				}
				answer = answer(result.a);
			}
			return $elm$core$Result$Ok(answer);

		case 10:
			var result = _Json_runHelp(decoder.b, value);
			return (!$elm$core$Result$isOk(result))
				? result
				: _Json_runHelp(decoder.h(result.a), value);

		case 11:
			var errors = _List_Nil;
			for (var temp = decoder.g; temp.b; temp = temp.b) // WHILE_CONS
			{
				var result = _Json_runHelp(temp.a, value);
				if ($elm$core$Result$isOk(result))
				{
					return result;
				}
				errors = _List_Cons(result.a, errors);
			}
			return $elm$core$Result$Err($elm$json$Json$Decode$OneOf($elm$core$List$reverse(errors)));

		case 1:
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, decoder.a, _Json_wrap(value)));

		case 0:
			return $elm$core$Result$Ok(decoder.a);
	}
}

function _Json_runArrayDecoder(decoder, value, toElmValue)
{
	var len = value.length;
	var array = new Array(len);
	for (var i = 0; i < len; i++)
	{
		var result = _Json_runHelp(decoder, value[i]);
		if (!$elm$core$Result$isOk(result))
		{
			return $elm$core$Result$Err(A2($elm$json$Json$Decode$Index, i, result.a));
		}
		array[i] = result.a;
	}
	return $elm$core$Result$Ok(toElmValue(array));
}

function _Json_isArray(value)
{
	return Array.isArray(value) || (typeof FileList !== 'undefined' && value instanceof FileList);
}

function _Json_toElmArray(array)
{
	return A2($elm$core$Array$initialize, array.length, function(i) { return array[i]; });
}

function _Json_expecting(type, value)
{
	return $elm$core$Result$Err(A2($elm$json$Json$Decode$Failure, 'Expecting ' + type, _Json_wrap(value)));
}


// EQUALITY

function _Json_equality(x, y)
{
	if (x === y)
	{
		return true;
	}

	if (x.$ !== y.$)
	{
		return false;
	}

	switch (x.$)
	{
		case 0:
		case 1:
			return x.a === y.a;

		case 2:
			return x.b === y.b;

		case 5:
			return x.c === y.c;

		case 3:
		case 4:
		case 8:
			return _Json_equality(x.b, y.b);

		case 6:
			return x.d === y.d && _Json_equality(x.b, y.b);

		case 7:
			return x.e === y.e && _Json_equality(x.b, y.b);

		case 9:
			return x.f === y.f && _Json_listEquality(x.g, y.g);

		case 10:
			return x.h === y.h && _Json_equality(x.b, y.b);

		case 11:
			return _Json_listEquality(x.g, y.g);
	}
}

function _Json_listEquality(aDecoders, bDecoders)
{
	var len = aDecoders.length;
	if (len !== bDecoders.length)
	{
		return false;
	}
	for (var i = 0; i < len; i++)
	{
		if (!_Json_equality(aDecoders[i], bDecoders[i]))
		{
			return false;
		}
	}
	return true;
}


// ENCODE

var _Json_encode = F2(function(indentLevel, value)
{
	return JSON.stringify(_Json_unwrap(value), null, indentLevel) + '';
});

function _Json_wrap(value) { return { $: 0, a: value }; }
function _Json_unwrap(value) { return value.a; }

function _Json_wrap_UNUSED(value) { return value; }
function _Json_unwrap_UNUSED(value) { return value; }

function _Json_emptyArray() { return []; }
function _Json_emptyObject() { return {}; }

var _Json_addField = F3(function(key, value, object)
{
	object[key] = _Json_unwrap(value);
	return object;
});

function _Json_addEntry(func)
{
	return F2(function(entry, array)
	{
		array.push(_Json_unwrap(func(entry)));
		return array;
	});
}

var _Json_encodeNull = _Json_wrap(null);



// TASKS

function _Scheduler_succeed(value)
{
	return {
		$: 0,
		a: value
	};
}

function _Scheduler_fail(error)
{
	return {
		$: 1,
		a: error
	};
}

function _Scheduler_binding(callback)
{
	return {
		$: 2,
		b: callback,
		c: null
	};
}

var _Scheduler_andThen = F2(function(callback, task)
{
	return {
		$: 3,
		b: callback,
		d: task
	};
});

var _Scheduler_onError = F2(function(callback, task)
{
	return {
		$: 4,
		b: callback,
		d: task
	};
});

function _Scheduler_receive(callback)
{
	return {
		$: 5,
		b: callback
	};
}


// PROCESSES

var _Scheduler_guid = 0;

function _Scheduler_rawSpawn(task)
{
	var proc = {
		$: 0,
		e: _Scheduler_guid++,
		f: task,
		g: null,
		h: []
	};

	_Scheduler_enqueue(proc);

	return proc;
}

function _Scheduler_spawn(task)
{
	return _Scheduler_binding(function(callback) {
		callback(_Scheduler_succeed(_Scheduler_rawSpawn(task)));
	});
}

function _Scheduler_rawSend(proc, msg)
{
	proc.h.push(msg);
	_Scheduler_enqueue(proc);
}

var _Scheduler_send = F2(function(proc, msg)
{
	return _Scheduler_binding(function(callback) {
		_Scheduler_rawSend(proc, msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});

function _Scheduler_kill(proc)
{
	return _Scheduler_binding(function(callback) {
		var task = proc.f;
		if (task.$ === 2 && task.c)
		{
			task.c();
		}

		proc.f = null;

		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
}


/* STEP PROCESSES

type alias Process =
  { $ : tag
  , id : unique_id
  , root : Task
  , stack : null | { $: SUCCEED | FAIL, a: callback, b: stack }
  , mailbox : [msg]
  }

*/


var _Scheduler_working = false;
var _Scheduler_queue = [];


function _Scheduler_enqueue(proc)
{
	_Scheduler_queue.push(proc);
	if (_Scheduler_working)
	{
		return;
	}
	_Scheduler_working = true;
	while (proc = _Scheduler_queue.shift())
	{
		_Scheduler_step(proc);
	}
	_Scheduler_working = false;
}


function _Scheduler_step(proc)
{
	while (proc.f)
	{
		var rootTag = proc.f.$;
		if (rootTag === 0 || rootTag === 1)
		{
			while (proc.g && proc.g.$ !== rootTag)
			{
				proc.g = proc.g.i;
			}
			if (!proc.g)
			{
				return;
			}
			proc.f = proc.g.b(proc.f.a);
			proc.g = proc.g.i;
		}
		else if (rootTag === 2)
		{
			proc.f.c = proc.f.b(function(newRoot) {
				proc.f = newRoot;
				_Scheduler_enqueue(proc);
			});
			return;
		}
		else if (rootTag === 5)
		{
			if (proc.h.length === 0)
			{
				return;
			}
			proc.f = proc.f.b(proc.h.shift());
		}
		else // if (rootTag === 3 || rootTag === 4)
		{
			proc.g = {
				$: rootTag === 3 ? 0 : 1,
				b: proc.f.b,
				i: proc.g
			};
			proc.f = proc.f.d;
		}
	}
}



function _Process_sleep(time)
{
	return _Scheduler_binding(function(callback) {
		var id = setTimeout(function() {
			callback(_Scheduler_succeed(_Utils_Tuple0));
		}, time);

		return function() { clearTimeout(id); };
	});
}




// PROGRAMS


var _Platform_worker = F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function() { return function() {} }
	);
});



// INITIALIZE A PROGRAM


function _Platform_initialize(flagDecoder, args, init, update, subscriptions, stepperBuilder)
{
	var result = A2(_Json_run, flagDecoder, _Json_wrap(args ? args['flags'] : undefined));
	$elm$core$Result$isOk(result) || _Debug_crash(2 /**/, _Json_errorToString(result.a) /**/);
	var managers = {};
	var initPair = init(result.a);
	var model = initPair.a;
	var stepper = stepperBuilder(sendToApp, model);
	var ports = _Platform_setupEffects(managers, sendToApp);

	function sendToApp(msg, viewMetadata)
	{
		var pair = A2(update, msg, model);
		stepper(model = pair.a, viewMetadata);
		_Platform_enqueueEffects(managers, pair.b, subscriptions(model));
	}

	_Platform_enqueueEffects(managers, initPair.b, subscriptions(model));

	return ports ? { ports: ports } : {};
}



// TRACK PRELOADS
//
// This is used by code in elm/browser and elm/http
// to register any HTTP requests that are triggered by init.
//


var _Platform_preload;


function _Platform_registerPreload(url)
{
	_Platform_preload.add(url);
}



// EFFECT MANAGERS


var _Platform_effectManagers = {};


function _Platform_setupEffects(managers, sendToApp)
{
	var ports;

	// setup all necessary effect managers
	for (var key in _Platform_effectManagers)
	{
		var manager = _Platform_effectManagers[key];

		if (manager.a)
		{
			ports = ports || {};
			ports[key] = manager.a(key, sendToApp);
		}

		managers[key] = _Platform_instantiateManager(manager, sendToApp);
	}

	return ports;
}


function _Platform_createManager(init, onEffects, onSelfMsg, cmdMap, subMap)
{
	return {
		b: init,
		c: onEffects,
		d: onSelfMsg,
		e: cmdMap,
		f: subMap
	};
}


function _Platform_instantiateManager(info, sendToApp)
{
	var router = {
		g: sendToApp,
		h: undefined
	};

	var onEffects = info.c;
	var onSelfMsg = info.d;
	var cmdMap = info.e;
	var subMap = info.f;

	function loop(state)
	{
		return A2(_Scheduler_andThen, loop, _Scheduler_receive(function(msg)
		{
			var value = msg.a;

			if (msg.$ === 0)
			{
				return A3(onSelfMsg, router, value, state);
			}

			return cmdMap && subMap
				? A4(onEffects, router, value.i, value.j, state)
				: A3(onEffects, router, cmdMap ? value.i : value.j, state);
		}));
	}

	return router.h = _Scheduler_rawSpawn(A2(_Scheduler_andThen, loop, info.b));
}



// ROUTING


var _Platform_sendToApp = F2(function(router, msg)
{
	return _Scheduler_binding(function(callback)
	{
		router.g(msg);
		callback(_Scheduler_succeed(_Utils_Tuple0));
	});
});


var _Platform_sendToSelf = F2(function(router, msg)
{
	return A2(_Scheduler_send, router.h, {
		$: 0,
		a: msg
	});
});



// BAGS


function _Platform_leaf(home)
{
	return function(value)
	{
		return {
			$: 1,
			k: home,
			l: value
		};
	};
}


function _Platform_batch(list)
{
	return {
		$: 2,
		m: list
	};
}


var _Platform_map = F2(function(tagger, bag)
{
	return {
		$: 3,
		n: tagger,
		o: bag
	}
});



// PIPE BAGS INTO EFFECT MANAGERS
//
// Effects must be queued!
//
// Say your init contains a synchronous command, like Time.now or Time.here
//
//   - This will produce a batch of effects (FX_1)
//   - The synchronous task triggers the subsequent `update` call
//   - This will produce a batch of effects (FX_2)
//
// If we just start dispatching FX_2, subscriptions from FX_2 can be processed
// before subscriptions from FX_1. No good! Earlier versions of this code had
// this problem, leading to these reports:
//
//   https://github.com/elm/core/issues/980
//   https://github.com/elm/core/pull/981
//   https://github.com/elm/compiler/issues/1776
//
// The queue is necessary to avoid ordering issues for synchronous commands.


// Why use true/false here? Why not just check the length of the queue?
// The goal is to detect "are we currently dispatching effects?" If we
// are, we need to bail and let the ongoing while loop handle things.
//
// Now say the queue has 1 element. When we dequeue the final element,
// the queue will be empty, but we are still actively dispatching effects.
// So you could get queue jumping in a really tricky category of cases.
//
var _Platform_effectsQueue = [];
var _Platform_effectsActive = false;


function _Platform_enqueueEffects(managers, cmdBag, subBag)
{
	_Platform_effectsQueue.push({ p: managers, q: cmdBag, r: subBag });

	if (_Platform_effectsActive) return;

	_Platform_effectsActive = true;
	for (var fx; fx = _Platform_effectsQueue.shift(); )
	{
		_Platform_dispatchEffects(fx.p, fx.q, fx.r);
	}
	_Platform_effectsActive = false;
}


function _Platform_dispatchEffects(managers, cmdBag, subBag)
{
	var effectsDict = {};
	_Platform_gatherEffects(true, cmdBag, effectsDict, null);
	_Platform_gatherEffects(false, subBag, effectsDict, null);

	for (var home in managers)
	{
		_Scheduler_rawSend(managers[home], {
			$: 'fx',
			a: effectsDict[home] || { i: _List_Nil, j: _List_Nil }
		});
	}
}


function _Platform_gatherEffects(isCmd, bag, effectsDict, taggers)
{
	switch (bag.$)
	{
		case 1:
			var home = bag.k;
			var effect = _Platform_toEffect(isCmd, home, taggers, bag.l);
			effectsDict[home] = _Platform_insert(isCmd, effect, effectsDict[home]);
			return;

		case 2:
			for (var list = bag.m; list.b; list = list.b) // WHILE_CONS
			{
				_Platform_gatherEffects(isCmd, list.a, effectsDict, taggers);
			}
			return;

		case 3:
			_Platform_gatherEffects(isCmd, bag.o, effectsDict, {
				s: bag.n,
				t: taggers
			});
			return;
	}
}


function _Platform_toEffect(isCmd, home, taggers, value)
{
	function applyTaggers(x)
	{
		for (var temp = taggers; temp; temp = temp.t)
		{
			x = temp.s(x);
		}
		return x;
	}

	var map = isCmd
		? _Platform_effectManagers[home].e
		: _Platform_effectManagers[home].f;

	return A2(map, applyTaggers, value)
}


function _Platform_insert(isCmd, newEffect, effects)
{
	effects = effects || { i: _List_Nil, j: _List_Nil };

	isCmd
		? (effects.i = _List_Cons(newEffect, effects.i))
		: (effects.j = _List_Cons(newEffect, effects.j));

	return effects;
}



// PORTS


function _Platform_checkPortName(name)
{
	if (_Platform_effectManagers[name])
	{
		_Debug_crash(3, name)
	}
}



// OUTGOING PORTS


function _Platform_outgoingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		e: _Platform_outgoingPortMap,
		u: converter,
		a: _Platform_setupOutgoingPort
	};
	return _Platform_leaf(name);
}


var _Platform_outgoingPortMap = F2(function(tagger, value) { return value; });


function _Platform_setupOutgoingPort(name)
{
	var subs = [];
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Process_sleep(0);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, cmdList, state)
	{
		for ( ; cmdList.b; cmdList = cmdList.b) // WHILE_CONS
		{
			// grab a separate reference to subs in case unsubscribe is called
			var currentSubs = subs;
			var value = _Json_unwrap(converter(cmdList.a));
			for (var i = 0; i < currentSubs.length; i++)
			{
				currentSubs[i](value);
			}
		}
		return init;
	});

	// PUBLIC API

	function subscribe(callback)
	{
		subs.push(callback);
	}

	function unsubscribe(callback)
	{
		// copy subs into a new array in case unsubscribe is called within a
		// subscribed callback
		subs = subs.slice();
		var index = subs.indexOf(callback);
		if (index >= 0)
		{
			subs.splice(index, 1);
		}
	}

	return {
		subscribe: subscribe,
		unsubscribe: unsubscribe
	};
}



// INCOMING PORTS


function _Platform_incomingPort(name, converter)
{
	_Platform_checkPortName(name);
	_Platform_effectManagers[name] = {
		f: _Platform_incomingPortMap,
		u: converter,
		a: _Platform_setupIncomingPort
	};
	return _Platform_leaf(name);
}


var _Platform_incomingPortMap = F2(function(tagger, finalTagger)
{
	return function(value)
	{
		return tagger(finalTagger(value));
	};
});


function _Platform_setupIncomingPort(name, sendToApp)
{
	var subs = _List_Nil;
	var converter = _Platform_effectManagers[name].u;

	// CREATE MANAGER

	var init = _Scheduler_succeed(null);

	_Platform_effectManagers[name].b = init;
	_Platform_effectManagers[name].c = F3(function(router, subList, state)
	{
		subs = subList;
		return init;
	});

	// PUBLIC API

	function send(incomingValue)
	{
		var result = A2(_Json_run, converter, _Json_wrap(incomingValue));

		$elm$core$Result$isOk(result) || _Debug_crash(4, name, result.a);

		var value = result.a;
		for (var temp = subs; temp.b; temp = temp.b) // WHILE_CONS
		{
			sendToApp(temp.a(value));
		}
	}

	return { send: send };
}



// EXPORT ELM MODULES
//
// Have DEBUG and PROD versions so that we can (1) give nicer errors in
// debug mode and (2) not pay for the bits needed for that in prod mode.
//


function _Platform_export_UNUSED(exports)
{
	scope['Elm']
		? _Platform_mergeExportsProd(scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsProd(obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6)
				: _Platform_mergeExportsProd(obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}


function _Platform_export(exports)
{
	scope['Elm']
		? _Platform_mergeExportsDebug('Elm', scope['Elm'], exports)
		: scope['Elm'] = exports;
}


function _Platform_mergeExportsDebug(moduleName, obj, exports)
{
	for (var name in exports)
	{
		(name in obj)
			? (name == 'init')
				? _Debug_crash(6, moduleName)
				: _Platform_mergeExportsDebug(moduleName + '.' + name, obj[name], exports[name])
			: (obj[name] = exports[name]);
	}
}




// HELPERS


var _VirtualDom_divertHrefToApp;

var _VirtualDom_doc = typeof document !== 'undefined' ? document : {};


function _VirtualDom_appendChild(parent, child)
{
	parent.appendChild(child);
}

var _VirtualDom_init = F4(function(virtualNode, flagDecoder, debugMetadata, args)
{
	// NOTE: this function needs _Platform_export available to work

	/**_UNUSED/
	var node = args['node'];
	//*/
	/**/
	var node = args && args['node'] ? args['node'] : _Debug_crash(0);
	//*/

	node.parentNode.replaceChild(
		_VirtualDom_render(virtualNode, function() {}),
		node
	);

	return {};
});



// TEXT


function _VirtualDom_text(string)
{
	return {
		$: 0,
		a: string
	};
}



// NODE


var _VirtualDom_nodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 1,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_node = _VirtualDom_nodeNS(undefined);



// KEYED NODE


var _VirtualDom_keyedNodeNS = F2(function(namespace, tag)
{
	return F2(function(factList, kidList)
	{
		for (var kids = [], descendantsCount = 0; kidList.b; kidList = kidList.b) // WHILE_CONS
		{
			var kid = kidList.a;
			descendantsCount += (kid.b.b || 0);
			kids.push(kid);
		}
		descendantsCount += kids.length;

		return {
			$: 2,
			c: tag,
			d: _VirtualDom_organizeFacts(factList),
			e: kids,
			f: namespace,
			b: descendantsCount
		};
	});
});


var _VirtualDom_keyedNode = _VirtualDom_keyedNodeNS(undefined);



// CUSTOM


function _VirtualDom_custom(factList, model, render, diff)
{
	return {
		$: 3,
		d: _VirtualDom_organizeFacts(factList),
		g: model,
		h: render,
		i: diff
	};
}



// MAP


var _VirtualDom_map = F2(function(tagger, node)
{
	return {
		$: 4,
		j: tagger,
		k: node,
		b: 1 + (node.b || 0)
	};
});



// LAZY


function _VirtualDom_thunk(refs, thunk)
{
	return {
		$: 5,
		l: refs,
		m: thunk,
		k: undefined
	};
}

var _VirtualDom_lazy = F2(function(func, a)
{
	return _VirtualDom_thunk([func, a], function() {
		return func(a);
	});
});

var _VirtualDom_lazy2 = F3(function(func, a, b)
{
	return _VirtualDom_thunk([func, a, b], function() {
		return A2(func, a, b);
	});
});

var _VirtualDom_lazy3 = F4(function(func, a, b, c)
{
	return _VirtualDom_thunk([func, a, b, c], function() {
		return A3(func, a, b, c);
	});
});

var _VirtualDom_lazy4 = F5(function(func, a, b, c, d)
{
	return _VirtualDom_thunk([func, a, b, c, d], function() {
		return A4(func, a, b, c, d);
	});
});

var _VirtualDom_lazy5 = F6(function(func, a, b, c, d, e)
{
	return _VirtualDom_thunk([func, a, b, c, d, e], function() {
		return A5(func, a, b, c, d, e);
	});
});

var _VirtualDom_lazy6 = F7(function(func, a, b, c, d, e, f)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f], function() {
		return A6(func, a, b, c, d, e, f);
	});
});

var _VirtualDom_lazy7 = F8(function(func, a, b, c, d, e, f, g)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g], function() {
		return A7(func, a, b, c, d, e, f, g);
	});
});

var _VirtualDom_lazy8 = F9(function(func, a, b, c, d, e, f, g, h)
{
	return _VirtualDom_thunk([func, a, b, c, d, e, f, g, h], function() {
		return A8(func, a, b, c, d, e, f, g, h);
	});
});



// FACTS


var _VirtualDom_on = F2(function(key, handler)
{
	return {
		$: 'a0',
		n: key,
		o: handler
	};
});
var _VirtualDom_style = F2(function(key, value)
{
	return {
		$: 'a1',
		n: key,
		o: value
	};
});
var _VirtualDom_property = F2(function(key, value)
{
	return {
		$: 'a2',
		n: key,
		o: value
	};
});
var _VirtualDom_attribute = F2(function(key, value)
{
	return {
		$: 'a3',
		n: key,
		o: value
	};
});
var _VirtualDom_attributeNS = F3(function(namespace, key, value)
{
	return {
		$: 'a4',
		n: key,
		o: { f: namespace, o: value }
	};
});



// XSS ATTACK VECTOR CHECKS


function _VirtualDom_noScript(tag)
{
	return tag == 'script' ? 'p' : tag;
}

function _VirtualDom_noOnOrFormAction(key)
{
	return /^(on|formAction$)/i.test(key) ? 'data-' + key : key;
}

function _VirtualDom_noInnerHtmlOrFormAction(key)
{
	return key == 'innerHTML' || key == 'formAction' ? 'data-' + key : key;
}

function _VirtualDom_noJavaScriptUri_UNUSED(value)
{
	return /^javascript:/i.test(value.replace(/\s/g,'')) ? '' : value;
}

function _VirtualDom_noJavaScriptUri(value)
{
	return /^javascript:/i.test(value.replace(/\s/g,''))
		? 'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'
		: value;
}

function _VirtualDom_noJavaScriptOrHtmlUri_UNUSED(value)
{
	return /^\s*(javascript:|data:text\/html)/i.test(value) ? '' : value;
}

function _VirtualDom_noJavaScriptOrHtmlUri(value)
{
	return /^\s*(javascript:|data:text\/html)/i.test(value)
		? 'javascript:alert("This is an XSS vector. Please use ports or web components instead.")'
		: value;
}



// MAP FACTS


var _VirtualDom_mapAttribute = F2(function(func, attr)
{
	return (attr.$ === 'a0')
		? A2(_VirtualDom_on, attr.n, _VirtualDom_mapHandler(func, attr.o))
		: attr;
});

function _VirtualDom_mapHandler(func, handler)
{
	var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

	// 0 = Normal
	// 1 = MayStopPropagation
	// 2 = MayPreventDefault
	// 3 = Custom

	return {
		$: handler.$,
		a:
			!tag
				? A2($elm$json$Json$Decode$map, func, handler.a)
				:
			A3($elm$json$Json$Decode$map2,
				tag < 3
					? _VirtualDom_mapEventTuple
					: _VirtualDom_mapEventRecord,
				$elm$json$Json$Decode$succeed(func),
				handler.a
			)
	};
}

var _VirtualDom_mapEventTuple = F2(function(func, tuple)
{
	return _Utils_Tuple2(func(tuple.a), tuple.b);
});

var _VirtualDom_mapEventRecord = F2(function(func, record)
{
	return {
		message: func(record.message),
		stopPropagation: record.stopPropagation,
		preventDefault: record.preventDefault
	}
});



// ORGANIZE FACTS


function _VirtualDom_organizeFacts(factList)
{
	for (var facts = {}; factList.b; factList = factList.b) // WHILE_CONS
	{
		var entry = factList.a;

		var tag = entry.$;
		var key = entry.n;
		var value = entry.o;

		if (tag === 'a2')
		{
			(key === 'className')
				? _VirtualDom_addClass(facts, key, _Json_unwrap(value))
				: facts[key] = _Json_unwrap(value);

			continue;
		}

		var subFacts = facts[tag] || (facts[tag] = {});
		(tag === 'a3' && key === 'class')
			? _VirtualDom_addClass(subFacts, key, value)
			: subFacts[key] = value;
	}

	return facts;
}

function _VirtualDom_addClass(object, key, newClass)
{
	var classes = object[key];
	object[key] = classes ? classes + ' ' + newClass : newClass;
}



// RENDER


function _VirtualDom_render(vNode, eventNode)
{
	var tag = vNode.$;

	if (tag === 5)
	{
		return _VirtualDom_render(vNode.k || (vNode.k = vNode.m()), eventNode);
	}

	if (tag === 0)
	{
		return _VirtualDom_doc.createTextNode(vNode.a);
	}

	if (tag === 4)
	{
		var subNode = vNode.k;
		var tagger = vNode.j;

		while (subNode.$ === 4)
		{
			typeof tagger !== 'object'
				? tagger = [tagger, subNode.j]
				: tagger.push(subNode.j);

			subNode = subNode.k;
		}

		var subEventRoot = { j: tagger, p: eventNode };
		var domNode = _VirtualDom_render(subNode, subEventRoot);
		domNode.elm_event_node_ref = subEventRoot;
		return domNode;
	}

	if (tag === 3)
	{
		var domNode = vNode.h(vNode.g);
		_VirtualDom_applyFacts(domNode, eventNode, vNode.d);
		return domNode;
	}

	// at this point `tag` must be 1 or 2

	var domNode = vNode.f
		? _VirtualDom_doc.createElementNS(vNode.f, vNode.c)
		: _VirtualDom_doc.createElement(vNode.c);

	if (_VirtualDom_divertHrefToApp && vNode.c == 'a')
	{
		domNode.addEventListener('click', _VirtualDom_divertHrefToApp(domNode));
	}

	_VirtualDom_applyFacts(domNode, eventNode, vNode.d);

	for (var kids = vNode.e, i = 0; i < kids.length; i++)
	{
		_VirtualDom_appendChild(domNode, _VirtualDom_render(tag === 1 ? kids[i] : kids[i].b, eventNode));
	}

	return domNode;
}



// APPLY FACTS


function _VirtualDom_applyFacts(domNode, eventNode, facts)
{
	for (var key in facts)
	{
		var value = facts[key];

		key === 'a1'
			? _VirtualDom_applyStyles(domNode, value)
			:
		key === 'a0'
			? _VirtualDom_applyEvents(domNode, eventNode, value)
			:
		key === 'a3'
			? _VirtualDom_applyAttrs(domNode, value)
			:
		key === 'a4'
			? _VirtualDom_applyAttrsNS(domNode, value)
			:
		((key !== 'value' && key !== 'checked') || domNode[key] !== value) && (domNode[key] = value);
	}
}



// APPLY STYLES


function _VirtualDom_applyStyles(domNode, styles)
{
	var domNodeStyle = domNode.style;

	for (var key in styles)
	{
		domNodeStyle[key] = styles[key];
	}
}



// APPLY ATTRS


function _VirtualDom_applyAttrs(domNode, attrs)
{
	for (var key in attrs)
	{
		var value = attrs[key];
		typeof value !== 'undefined'
			? domNode.setAttribute(key, value)
			: domNode.removeAttribute(key);
	}
}



// APPLY NAMESPACED ATTRS


function _VirtualDom_applyAttrsNS(domNode, nsAttrs)
{
	for (var key in nsAttrs)
	{
		var pair = nsAttrs[key];
		var namespace = pair.f;
		var value = pair.o;

		typeof value !== 'undefined'
			? domNode.setAttributeNS(namespace, key, value)
			: domNode.removeAttributeNS(namespace, key);
	}
}



// APPLY EVENTS


function _VirtualDom_applyEvents(domNode, eventNode, events)
{
	var allCallbacks = domNode.elmFs || (domNode.elmFs = {});

	for (var key in events)
	{
		var newHandler = events[key];
		var oldCallback = allCallbacks[key];

		if (!newHandler)
		{
			domNode.removeEventListener(key, oldCallback);
			allCallbacks[key] = undefined;
			continue;
		}

		if (oldCallback)
		{
			var oldHandler = oldCallback.q;
			if (oldHandler.$ === newHandler.$)
			{
				oldCallback.q = newHandler;
				continue;
			}
			domNode.removeEventListener(key, oldCallback);
		}

		oldCallback = _VirtualDom_makeCallback(eventNode, newHandler);
		domNode.addEventListener(key, oldCallback,
			_VirtualDom_passiveSupported
			&& { passive: $elm$virtual_dom$VirtualDom$toHandlerInt(newHandler) < 2 }
		);
		allCallbacks[key] = oldCallback;
	}
}



// PASSIVE EVENTS


var _VirtualDom_passiveSupported;

try
{
	window.addEventListener('t', null, Object.defineProperty({}, 'passive', {
		get: function() { _VirtualDom_passiveSupported = true; }
	}));
}
catch(e) {}



// EVENT HANDLERS


function _VirtualDom_makeCallback(eventNode, initialHandler)
{
	function callback(event)
	{
		var handler = callback.q;
		var result = _Json_runHelp(handler.a, event);

		if (!$elm$core$Result$isOk(result))
		{
			return;
		}

		var tag = $elm$virtual_dom$VirtualDom$toHandlerInt(handler);

		// 0 = Normal
		// 1 = MayStopPropagation
		// 2 = MayPreventDefault
		// 3 = Custom

		var value = result.a;
		var message = !tag ? value : tag < 3 ? value.a : value.message;
		var stopPropagation = tag == 1 ? value.b : tag == 3 && value.stopPropagation;
		var currentEventNode = (
			stopPropagation && event.stopPropagation(),
			(tag == 2 ? value.b : tag == 3 && value.preventDefault) && event.preventDefault(),
			eventNode
		);
		var tagger;
		var i;
		while (tagger = currentEventNode.j)
		{
			if (typeof tagger == 'function')
			{
				message = tagger(message);
			}
			else
			{
				for (var i = tagger.length; i--; )
				{
					message = tagger[i](message);
				}
			}
			currentEventNode = currentEventNode.p;
		}
		currentEventNode(message, stopPropagation); // stopPropagation implies isSync
	}

	callback.q = initialHandler;

	return callback;
}

function _VirtualDom_equalEvents(x, y)
{
	return x.$ == y.$ && _Json_equality(x.a, y.a);
}



// DIFF


// TODO: Should we do patches like in iOS?
//
// type Patch
//   = At Int Patch
//   | Batch (List Patch)
//   | Change ...
//
// How could it not be better?
//
function _VirtualDom_diff(x, y)
{
	var patches = [];
	_VirtualDom_diffHelp(x, y, patches, 0);
	return patches;
}


function _VirtualDom_pushPatch(patches, type, index, data)
{
	var patch = {
		$: type,
		r: index,
		s: data,
		t: undefined,
		u: undefined
	};
	patches.push(patch);
	return patch;
}


function _VirtualDom_diffHelp(x, y, patches, index)
{
	if (x === y)
	{
		return;
	}

	var xType = x.$;
	var yType = y.$;

	// Bail if you run into different types of nodes. Implies that the
	// structure has changed significantly and it's not worth a diff.
	if (xType !== yType)
	{
		if (xType === 1 && yType === 2)
		{
			y = _VirtualDom_dekey(y);
			yType = 1;
		}
		else
		{
			_VirtualDom_pushPatch(patches, 0, index, y);
			return;
		}
	}

	// Now we know that both nodes are the same $.
	switch (yType)
	{
		case 5:
			var xRefs = x.l;
			var yRefs = y.l;
			var i = xRefs.length;
			var same = i === yRefs.length;
			while (same && i--)
			{
				same = xRefs[i] === yRefs[i];
			}
			if (same)
			{
				y.k = x.k;
				return;
			}
			y.k = y.m();
			var subPatches = [];
			_VirtualDom_diffHelp(x.k, y.k, subPatches, 0);
			subPatches.length > 0 && _VirtualDom_pushPatch(patches, 1, index, subPatches);
			return;

		case 4:
			// gather nested taggers
			var xTaggers = x.j;
			var yTaggers = y.j;
			var nesting = false;

			var xSubNode = x.k;
			while (xSubNode.$ === 4)
			{
				nesting = true;

				typeof xTaggers !== 'object'
					? xTaggers = [xTaggers, xSubNode.j]
					: xTaggers.push(xSubNode.j);

				xSubNode = xSubNode.k;
			}

			var ySubNode = y.k;
			while (ySubNode.$ === 4)
			{
				nesting = true;

				typeof yTaggers !== 'object'
					? yTaggers = [yTaggers, ySubNode.j]
					: yTaggers.push(ySubNode.j);

				ySubNode = ySubNode.k;
			}

			// Just bail if different numbers of taggers. This implies the
			// structure of the virtual DOM has changed.
			if (nesting && xTaggers.length !== yTaggers.length)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			// check if taggers are "the same"
			if (nesting ? !_VirtualDom_pairwiseRefEqual(xTaggers, yTaggers) : xTaggers !== yTaggers)
			{
				_VirtualDom_pushPatch(patches, 2, index, yTaggers);
			}

			// diff everything below the taggers
			_VirtualDom_diffHelp(xSubNode, ySubNode, patches, index + 1);
			return;

		case 0:
			if (x.a !== y.a)
			{
				_VirtualDom_pushPatch(patches, 3, index, y.a);
			}
			return;

		case 1:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKids);
			return;

		case 2:
			_VirtualDom_diffNodes(x, y, patches, index, _VirtualDom_diffKeyedKids);
			return;

		case 3:
			if (x.h !== y.h)
			{
				_VirtualDom_pushPatch(patches, 0, index, y);
				return;
			}

			var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
			factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

			var patch = y.i(x.g, y.g);
			patch && _VirtualDom_pushPatch(patches, 5, index, patch);

			return;
	}
}

// assumes the incoming arrays are the same length
function _VirtualDom_pairwiseRefEqual(as, bs)
{
	for (var i = 0; i < as.length; i++)
	{
		if (as[i] !== bs[i])
		{
			return false;
		}
	}

	return true;
}

function _VirtualDom_diffNodes(x, y, patches, index, diffKids)
{
	// Bail if obvious indicators have changed. Implies more serious
	// structural changes such that it's not worth it to diff.
	if (x.c !== y.c || x.f !== y.f)
	{
		_VirtualDom_pushPatch(patches, 0, index, y);
		return;
	}

	var factsDiff = _VirtualDom_diffFacts(x.d, y.d);
	factsDiff && _VirtualDom_pushPatch(patches, 4, index, factsDiff);

	diffKids(x, y, patches, index);
}



// DIFF FACTS


// TODO Instead of creating a new diff object, it's possible to just test if
// there *is* a diff. During the actual patch, do the diff again and make the
// modifications directly. This way, there's no new allocations. Worth it?
function _VirtualDom_diffFacts(x, y, category)
{
	var diff;

	// look for changes and removals
	for (var xKey in x)
	{
		if (xKey === 'a1' || xKey === 'a0' || xKey === 'a3' || xKey === 'a4')
		{
			var subDiff = _VirtualDom_diffFacts(x[xKey], y[xKey] || {}, xKey);
			if (subDiff)
			{
				diff = diff || {};
				diff[xKey] = subDiff;
			}
			continue;
		}

		// remove if not in the new facts
		if (!(xKey in y))
		{
			diff = diff || {};
			diff[xKey] =
				!category
					? (typeof x[xKey] === 'string' ? '' : null)
					:
				(category === 'a1')
					? ''
					:
				(category === 'a0' || category === 'a3')
					? undefined
					:
				{ f: x[xKey].f, o: undefined };

			continue;
		}

		var xValue = x[xKey];
		var yValue = y[xKey];

		// reference equal, so don't worry about it
		if (xValue === yValue && xKey !== 'value' && xKey !== 'checked'
			|| category === 'a0' && _VirtualDom_equalEvents(xValue, yValue))
		{
			continue;
		}

		diff = diff || {};
		diff[xKey] = yValue;
	}

	// add new stuff
	for (var yKey in y)
	{
		if (!(yKey in x))
		{
			diff = diff || {};
			diff[yKey] = y[yKey];
		}
	}

	return diff;
}



// DIFF KIDS


function _VirtualDom_diffKids(xParent, yParent, patches, index)
{
	var xKids = xParent.e;
	var yKids = yParent.e;

	var xLen = xKids.length;
	var yLen = yKids.length;

	// FIGURE OUT IF THERE ARE INSERTS OR REMOVALS

	if (xLen > yLen)
	{
		_VirtualDom_pushPatch(patches, 6, index, {
			v: yLen,
			i: xLen - yLen
		});
	}
	else if (xLen < yLen)
	{
		_VirtualDom_pushPatch(patches, 7, index, {
			v: xLen,
			e: yKids
		});
	}

	// PAIRWISE DIFF EVERYTHING ELSE

	for (var minLen = xLen < yLen ? xLen : yLen, i = 0; i < minLen; i++)
	{
		var xKid = xKids[i];
		_VirtualDom_diffHelp(xKid, yKids[i], patches, ++index);
		index += xKid.b || 0;
	}
}



// KEYED DIFF


function _VirtualDom_diffKeyedKids(xParent, yParent, patches, rootIndex)
{
	var localPatches = [];

	var changes = {}; // Dict String Entry
	var inserts = []; // Array { index : Int, entry : Entry }
	// type Entry = { tag : String, vnode : VNode, index : Int, data : _ }

	var xKids = xParent.e;
	var yKids = yParent.e;
	var xLen = xKids.length;
	var yLen = yKids.length;
	var xIndex = 0;
	var yIndex = 0;

	var index = rootIndex;

	while (xIndex < xLen && yIndex < yLen)
	{
		var x = xKids[xIndex];
		var y = yKids[yIndex];

		var xKey = x.a;
		var yKey = y.a;
		var xNode = x.b;
		var yNode = y.b;

		var newMatch = undefined;
		var oldMatch = undefined;

		// check if keys match

		if (xKey === yKey)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNode, localPatches, index);
			index += xNode.b || 0;

			xIndex++;
			yIndex++;
			continue;
		}

		// look ahead 1 to detect insertions and removals.

		var xNext = xKids[xIndex + 1];
		var yNext = yKids[yIndex + 1];

		if (xNext)
		{
			var xNextKey = xNext.a;
			var xNextNode = xNext.b;
			oldMatch = yKey === xNextKey;
		}

		if (yNext)
		{
			var yNextKey = yNext.a;
			var yNextNode = yNext.b;
			newMatch = xKey === yNextKey;
		}


		// swap x and y
		if (newMatch && oldMatch)
		{
			index++;
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			_VirtualDom_insertNode(changes, localPatches, xKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNextNode, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		// insert y
		if (newMatch)
		{
			index++;
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			_VirtualDom_diffHelp(xNode, yNextNode, localPatches, index);
			index += xNode.b || 0;

			xIndex += 1;
			yIndex += 2;
			continue;
		}

		// remove x
		if (oldMatch)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 1;
			continue;
		}

		// remove x, insert y
		if (xNext && xNextKey === yNextKey)
		{
			index++;
			_VirtualDom_removeNode(changes, localPatches, xKey, xNode, index);
			_VirtualDom_insertNode(changes, localPatches, yKey, yNode, yIndex, inserts);
			index += xNode.b || 0;

			index++;
			_VirtualDom_diffHelp(xNextNode, yNextNode, localPatches, index);
			index += xNextNode.b || 0;

			xIndex += 2;
			yIndex += 2;
			continue;
		}

		break;
	}

	// eat up any remaining nodes with removeNode and insertNode

	while (xIndex < xLen)
	{
		index++;
		var x = xKids[xIndex];
		var xNode = x.b;
		_VirtualDom_removeNode(changes, localPatches, x.a, xNode, index);
		index += xNode.b || 0;
		xIndex++;
	}

	while (yIndex < yLen)
	{
		var endInserts = endInserts || [];
		var y = yKids[yIndex];
		_VirtualDom_insertNode(changes, localPatches, y.a, y.b, undefined, endInserts);
		yIndex++;
	}

	if (localPatches.length > 0 || inserts.length > 0 || endInserts)
	{
		_VirtualDom_pushPatch(patches, 8, rootIndex, {
			w: localPatches,
			x: inserts,
			y: endInserts
		});
	}
}



// CHANGES FROM KEYED DIFF


var _VirtualDom_POSTFIX = '_elmW6BL';


function _VirtualDom_insertNode(changes, localPatches, key, vnode, yIndex, inserts)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		entry = {
			c: 0,
			z: vnode,
			r: yIndex,
			s: undefined
		};

		inserts.push({ r: yIndex, A: entry });
		changes[key] = entry;

		return;
	}

	// this key was removed earlier, a match!
	if (entry.c === 1)
	{
		inserts.push({ r: yIndex, A: entry });

		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(entry.z, vnode, subPatches, entry.r);
		entry.r = yIndex;
		entry.s.s = {
			w: subPatches,
			A: entry
		};

		return;
	}

	// this key has already been inserted or moved, a duplicate!
	_VirtualDom_insertNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, yIndex, inserts);
}


function _VirtualDom_removeNode(changes, localPatches, key, vnode, index)
{
	var entry = changes[key];

	// never seen this key before
	if (!entry)
	{
		var patch = _VirtualDom_pushPatch(localPatches, 9, index, undefined);

		changes[key] = {
			c: 1,
			z: vnode,
			r: index,
			s: patch
		};

		return;
	}

	// this key was inserted earlier, a match!
	if (entry.c === 0)
	{
		entry.c = 2;
		var subPatches = [];
		_VirtualDom_diffHelp(vnode, entry.z, subPatches, index);

		_VirtualDom_pushPatch(localPatches, 9, index, {
			w: subPatches,
			A: entry
		});

		return;
	}

	// this key has already been removed or moved, a duplicate!
	_VirtualDom_removeNode(changes, localPatches, key + _VirtualDom_POSTFIX, vnode, index);
}



// ADD DOM NODES
//
// Each DOM node has an "index" assigned in order of traversal. It is important
// to minimize our crawl over the actual DOM, so these indexes (along with the
// descendantsCount of virtual nodes) let us skip touching entire subtrees of
// the DOM if we know there are no patches there.


function _VirtualDom_addDomNodes(domNode, vNode, patches, eventNode)
{
	_VirtualDom_addDomNodesHelp(domNode, vNode, patches, 0, 0, vNode.b, eventNode);
}


// assumes `patches` is non-empty and indexes increase monotonically.
function _VirtualDom_addDomNodesHelp(domNode, vNode, patches, i, low, high, eventNode)
{
	var patch = patches[i];
	var index = patch.r;

	while (index === low)
	{
		var patchType = patch.$;

		if (patchType === 1)
		{
			_VirtualDom_addDomNodes(domNode, vNode.k, patch.s, eventNode);
		}
		else if (patchType === 8)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var subPatches = patch.s.w;
			if (subPatches.length > 0)
			{
				_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
			}
		}
		else if (patchType === 9)
		{
			patch.t = domNode;
			patch.u = eventNode;

			var data = patch.s;
			if (data)
			{
				data.A.s = domNode;
				var subPatches = data.w;
				if (subPatches.length > 0)
				{
					_VirtualDom_addDomNodesHelp(domNode, vNode, subPatches, 0, low, high, eventNode);
				}
			}
		}
		else
		{
			patch.t = domNode;
			patch.u = eventNode;
		}

		i++;

		if (!(patch = patches[i]) || (index = patch.r) > high)
		{
			return i;
		}
	}

	var tag = vNode.$;

	if (tag === 4)
	{
		var subNode = vNode.k;

		while (subNode.$ === 4)
		{
			subNode = subNode.k;
		}

		return _VirtualDom_addDomNodesHelp(domNode, subNode, patches, i, low + 1, high, domNode.elm_event_node_ref);
	}

	// tag must be 1 or 2 at this point

	var vKids = vNode.e;
	var childNodes = domNode.childNodes;
	for (var j = 0; j < vKids.length; j++)
	{
		low++;
		var vKid = tag === 1 ? vKids[j] : vKids[j].b;
		var nextLow = low + (vKid.b || 0);
		if (low <= index && index <= nextLow)
		{
			i = _VirtualDom_addDomNodesHelp(childNodes[j], vKid, patches, i, low, nextLow, eventNode);
			if (!(patch = patches[i]) || (index = patch.r) > high)
			{
				return i;
			}
		}
		low = nextLow;
	}
	return i;
}



// APPLY PATCHES


function _VirtualDom_applyPatches(rootDomNode, oldVirtualNode, patches, eventNode)
{
	if (patches.length === 0)
	{
		return rootDomNode;
	}

	_VirtualDom_addDomNodes(rootDomNode, oldVirtualNode, patches, eventNode);
	return _VirtualDom_applyPatchesHelp(rootDomNode, patches);
}

function _VirtualDom_applyPatchesHelp(rootDomNode, patches)
{
	for (var i = 0; i < patches.length; i++)
	{
		var patch = patches[i];
		var localDomNode = patch.t
		var newNode = _VirtualDom_applyPatch(localDomNode, patch);
		if (localDomNode === rootDomNode)
		{
			rootDomNode = newNode;
		}
	}
	return rootDomNode;
}

function _VirtualDom_applyPatch(domNode, patch)
{
	switch (patch.$)
	{
		case 0:
			return _VirtualDom_applyPatchRedraw(domNode, patch.s, patch.u);

		case 4:
			_VirtualDom_applyFacts(domNode, patch.u, patch.s);
			return domNode;

		case 3:
			domNode.replaceData(0, domNode.length, patch.s);
			return domNode;

		case 1:
			return _VirtualDom_applyPatchesHelp(domNode, patch.s);

		case 2:
			if (domNode.elm_event_node_ref)
			{
				domNode.elm_event_node_ref.j = patch.s;
			}
			else
			{
				domNode.elm_event_node_ref = { j: patch.s, p: patch.u };
			}
			return domNode;

		case 6:
			var data = patch.s;
			for (var i = 0; i < data.i; i++)
			{
				domNode.removeChild(domNode.childNodes[data.v]);
			}
			return domNode;

		case 7:
			var data = patch.s;
			var kids = data.e;
			var i = data.v;
			var theEnd = domNode.childNodes[i];
			for (; i < kids.length; i++)
			{
				domNode.insertBefore(_VirtualDom_render(kids[i], patch.u), theEnd);
			}
			return domNode;

		case 9:
			var data = patch.s;
			if (!data)
			{
				domNode.parentNode.removeChild(domNode);
				return domNode;
			}
			var entry = data.A;
			if (typeof entry.r !== 'undefined')
			{
				domNode.parentNode.removeChild(domNode);
			}
			entry.s = _VirtualDom_applyPatchesHelp(domNode, data.w);
			return domNode;

		case 8:
			return _VirtualDom_applyPatchReorder(domNode, patch);

		case 5:
			return patch.s(domNode);

		default:
			_Debug_crash(10); // 'Ran into an unknown patch!'
	}
}


function _VirtualDom_applyPatchRedraw(domNode, vNode, eventNode)
{
	var parentNode = domNode.parentNode;
	var newNode = _VirtualDom_render(vNode, eventNode);

	if (!newNode.elm_event_node_ref)
	{
		newNode.elm_event_node_ref = domNode.elm_event_node_ref;
	}

	if (parentNode && newNode !== domNode)
	{
		parentNode.replaceChild(newNode, domNode);
	}
	return newNode;
}


function _VirtualDom_applyPatchReorder(domNode, patch)
{
	var data = patch.s;

	// remove end inserts
	var frag = _VirtualDom_applyPatchReorderEndInsertsHelp(data.y, patch);

	// removals
	domNode = _VirtualDom_applyPatchesHelp(domNode, data.w);

	// inserts
	var inserts = data.x;
	for (var i = 0; i < inserts.length; i++)
	{
		var insert = inserts[i];
		var entry = insert.A;
		var node = entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u);
		domNode.insertBefore(node, domNode.childNodes[insert.r]);
	}

	// add end inserts
	if (frag)
	{
		_VirtualDom_appendChild(domNode, frag);
	}

	return domNode;
}


function _VirtualDom_applyPatchReorderEndInsertsHelp(endInserts, patch)
{
	if (!endInserts)
	{
		return;
	}

	var frag = _VirtualDom_doc.createDocumentFragment();
	for (var i = 0; i < endInserts.length; i++)
	{
		var insert = endInserts[i];
		var entry = insert.A;
		_VirtualDom_appendChild(frag, entry.c === 2
			? entry.s
			: _VirtualDom_render(entry.z, patch.u)
		);
	}
	return frag;
}


function _VirtualDom_virtualize(node)
{
	// TEXT NODES

	if (node.nodeType === 3)
	{
		return _VirtualDom_text(node.textContent);
	}


	// WEIRD NODES

	if (node.nodeType !== 1)
	{
		return _VirtualDom_text('');
	}


	// ELEMENT NODES

	var attrList = _List_Nil;
	var attrs = node.attributes;
	for (var i = attrs.length; i--; )
	{
		var attr = attrs[i];
		var name = attr.name;
		var value = attr.value;
		attrList = _List_Cons( A2(_VirtualDom_attribute, name, value), attrList );
	}

	var tag = node.tagName.toLowerCase();
	var kidList = _List_Nil;
	var kids = node.childNodes;

	for (var i = kids.length; i--; )
	{
		kidList = _List_Cons(_VirtualDom_virtualize(kids[i]), kidList);
	}
	return A3(_VirtualDom_node, tag, attrList, kidList);
}

function _VirtualDom_dekey(keyedNode)
{
	var keyedKids = keyedNode.e;
	var len = keyedKids.length;
	var kids = new Array(len);
	for (var i = 0; i < len; i++)
	{
		kids[i] = keyedKids[i].b;
	}

	return {
		$: 1,
		c: keyedNode.c,
		d: keyedNode.d,
		e: kids,
		f: keyedNode.f,
		b: keyedNode.b
	};
}




// ELEMENT


var _Debugger_element;

var _Browser_element = _Debugger_element || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function(sendToApp, initialModel) {
			var view = impl.view;
			/**_UNUSED/
			var domNode = args['node'];
			//*/
			/**/
			var domNode = args && args['node'] ? args['node'] : _Debug_crash(0);
			//*/
			var currNode = _VirtualDom_virtualize(domNode);

			return _Browser_makeAnimator(initialModel, function(model)
			{
				var nextNode = view(model);
				var patches = _VirtualDom_diff(currNode, nextNode);
				domNode = _VirtualDom_applyPatches(domNode, currNode, patches, sendToApp);
				currNode = nextNode;
			});
		}
	);
});



// DOCUMENT


var _Debugger_document;

var _Browser_document = _Debugger_document || F4(function(impl, flagDecoder, debugMetadata, args)
{
	return _Platform_initialize(
		flagDecoder,
		args,
		impl.init,
		impl.update,
		impl.subscriptions,
		function(sendToApp, initialModel) {
			var divertHrefToApp = impl.setup && impl.setup(sendToApp)
			var view = impl.view;
			var title = _VirtualDom_doc.title;
			var bodyNode = _VirtualDom_doc.body;
			var currNode = _VirtualDom_virtualize(bodyNode);
			return _Browser_makeAnimator(initialModel, function(model)
			{
				_VirtualDom_divertHrefToApp = divertHrefToApp;
				var doc = view(model);
				var nextNode = _VirtualDom_node('body')(_List_Nil)(doc.body);
				var patches = _VirtualDom_diff(currNode, nextNode);
				bodyNode = _VirtualDom_applyPatches(bodyNode, currNode, patches, sendToApp);
				currNode = nextNode;
				_VirtualDom_divertHrefToApp = 0;
				(title !== doc.title) && (_VirtualDom_doc.title = title = doc.title);
			});
		}
	);
});



// ANIMATION


var _Browser_cancelAnimationFrame =
	typeof cancelAnimationFrame !== 'undefined'
		? cancelAnimationFrame
		: function(id) { clearTimeout(id); };

var _Browser_requestAnimationFrame =
	typeof requestAnimationFrame !== 'undefined'
		? requestAnimationFrame
		: function(callback) { return setTimeout(callback, 1000 / 60); };


function _Browser_makeAnimator(model, draw)
{
	draw(model);

	var state = 0;

	function updateIfNeeded()
	{
		state = state === 1
			? 0
			: ( _Browser_requestAnimationFrame(updateIfNeeded), draw(model), 1 );
	}

	return function(nextModel, isSync)
	{
		model = nextModel;

		isSync
			? ( draw(model),
				state === 2 && (state = 1)
				)
			: ( state === 0 && _Browser_requestAnimationFrame(updateIfNeeded),
				state = 2
				);
	};
}



// APPLICATION


function _Browser_application(impl)
{
	var onUrlChange = impl.onUrlChange;
	var onUrlRequest = impl.onUrlRequest;
	var key = function() { key.a(onUrlChange(_Browser_getUrl())); };

	return _Browser_document({
		setup: function(sendToApp)
		{
			key.a = sendToApp;
			_Browser_window.addEventListener('popstate', key);
			_Browser_window.navigator.userAgent.indexOf('Trident') < 0 || _Browser_window.addEventListener('hashchange', key);

			return F2(function(domNode, event)
			{
				if (!event.ctrlKey && !event.metaKey && !event.shiftKey && event.button < 1 && !domNode.target && !domNode.hasAttribute('download'))
				{
					event.preventDefault();
					var href = domNode.href;
					var curr = _Browser_getUrl();
					var next = $elm$url$Url$fromString(href).a;
					sendToApp(onUrlRequest(
						(next
							&& curr.protocol === next.protocol
							&& curr.host === next.host
							&& curr.port_.a === next.port_.a
						)
							? $elm$browser$Browser$Internal(next)
							: $elm$browser$Browser$External(href)
					));
				}
			});
		},
		init: function(flags)
		{
			return A3(impl.init, flags, _Browser_getUrl(), key);
		},
		view: impl.view,
		update: impl.update,
		subscriptions: impl.subscriptions
	});
}

function _Browser_getUrl()
{
	return $elm$url$Url$fromString(_VirtualDom_doc.location.href).a || _Debug_crash(1);
}

var _Browser_go = F2(function(key, n)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		n && history.go(n);
		key();
	}));
});

var _Browser_pushUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.pushState({}, '', url);
		key();
	}));
});

var _Browser_replaceUrl = F2(function(key, url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function() {
		history.replaceState({}, '', url);
		key();
	}));
});



// GLOBAL EVENTS


var _Browser_fakeNode = { addEventListener: function() {}, removeEventListener: function() {} };
var _Browser_doc = typeof document !== 'undefined' ? document : _Browser_fakeNode;
var _Browser_window = typeof window !== 'undefined' ? window : _Browser_fakeNode;

var _Browser_on = F3(function(node, eventName, sendToSelf)
{
	return _Scheduler_spawn(_Scheduler_binding(function(callback)
	{
		function handler(event)	{ _Scheduler_rawSpawn(sendToSelf(event)); }
		node.addEventListener(eventName, handler, _VirtualDom_passiveSupported && { passive: true });
		return function() { node.removeEventListener(eventName, handler); };
	}));
});

var _Browser_decodeEvent = F2(function(decoder, event)
{
	var result = _Json_runHelp(decoder, event);
	return $elm$core$Result$isOk(result) ? $elm$core$Maybe$Just(result.a) : $elm$core$Maybe$Nothing;
});



// PAGE VISIBILITY


function _Browser_visibilityInfo()
{
	return (typeof _VirtualDom_doc.hidden !== 'undefined')
		? { hidden: 'hidden', change: 'visibilitychange' }
		:
	(typeof _VirtualDom_doc.mozHidden !== 'undefined')
		? { hidden: 'mozHidden', change: 'mozvisibilitychange' }
		:
	(typeof _VirtualDom_doc.msHidden !== 'undefined')
		? { hidden: 'msHidden', change: 'msvisibilitychange' }
		:
	(typeof _VirtualDom_doc.webkitHidden !== 'undefined')
		? { hidden: 'webkitHidden', change: 'webkitvisibilitychange' }
		: { hidden: 'hidden', change: 'visibilitychange' };
}



// ANIMATION FRAMES


function _Browser_rAF()
{
	return _Scheduler_binding(function(callback)
	{
		var id = _Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(Date.now()));
		});

		return function() {
			_Browser_cancelAnimationFrame(id);
		};
	});
}


function _Browser_now()
{
	return _Scheduler_binding(function(callback)
	{
		callback(_Scheduler_succeed(Date.now()));
	});
}



// DOM STUFF


function _Browser_withNode(id, doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			var node = document.getElementById(id);
			callback(node
				? _Scheduler_succeed(doStuff(node))
				: _Scheduler_fail($elm$browser$Browser$Dom$NotFound(id))
			);
		});
	});
}


function _Browser_withWindow(doStuff)
{
	return _Scheduler_binding(function(callback)
	{
		_Browser_requestAnimationFrame(function() {
			callback(_Scheduler_succeed(doStuff()));
		});
	});
}


// FOCUS and BLUR


var _Browser_call = F2(function(functionName, id)
{
	return _Browser_withNode(id, function(node) {
		node[functionName]();
		return _Utils_Tuple0;
	});
});



// WINDOW VIEWPORT


function _Browser_getViewport()
{
	return {
		scene: _Browser_getScene(),
		viewport: {
			x: _Browser_window.pageXOffset,
			y: _Browser_window.pageYOffset,
			width: _Browser_doc.documentElement.clientWidth,
			height: _Browser_doc.documentElement.clientHeight
		}
	};
}

function _Browser_getScene()
{
	var body = _Browser_doc.body;
	var elem = _Browser_doc.documentElement;
	return {
		width: Math.max(body.scrollWidth, body.offsetWidth, elem.scrollWidth, elem.offsetWidth, elem.clientWidth),
		height: Math.max(body.scrollHeight, body.offsetHeight, elem.scrollHeight, elem.offsetHeight, elem.clientHeight)
	};
}

var _Browser_setViewport = F2(function(x, y)
{
	return _Browser_withWindow(function()
	{
		_Browser_window.scroll(x, y);
		return _Utils_Tuple0;
	});
});



// ELEMENT VIEWPORT


function _Browser_getViewportOf(id)
{
	return _Browser_withNode(id, function(node)
	{
		return {
			scene: {
				width: node.scrollWidth,
				height: node.scrollHeight
			},
			viewport: {
				x: node.scrollLeft,
				y: node.scrollTop,
				width: node.clientWidth,
				height: node.clientHeight
			}
		};
	});
}


var _Browser_setViewportOf = F3(function(id, x, y)
{
	return _Browser_withNode(id, function(node)
	{
		node.scrollLeft = x;
		node.scrollTop = y;
		return _Utils_Tuple0;
	});
});



// ELEMENT


function _Browser_getElement(id)
{
	return _Browser_withNode(id, function(node)
	{
		var rect = node.getBoundingClientRect();
		var x = _Browser_window.pageXOffset;
		var y = _Browser_window.pageYOffset;
		return {
			scene: _Browser_getScene(),
			viewport: {
				x: x,
				y: y,
				width: _Browser_doc.documentElement.clientWidth,
				height: _Browser_doc.documentElement.clientHeight
			},
			element: {
				x: x + rect.left,
				y: y + rect.top,
				width: rect.width,
				height: rect.height
			}
		};
	});
}



// LOAD and RELOAD


function _Browser_reload(skipCache)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		_VirtualDom_doc.location.reload(skipCache);
	}));
}

function _Browser_load(url)
{
	return A2($elm$core$Task$perform, $elm$core$Basics$never, _Scheduler_binding(function(callback)
	{
		try
		{
			_Browser_window.location = url;
		}
		catch(err)
		{
			// Only Firefox can throw a NS_ERROR_MALFORMED_URI exception here.
			// Other browsers reload the page, so let's be consistent about that.
			_VirtualDom_doc.location.reload(false);
		}
	}));
}



// SEND REQUEST

var _Http_toTask = F3(function(router, toTask, request)
{
	return _Scheduler_binding(function(callback)
	{
		function done(response) {
			callback(toTask(request.expect.a(response)));
		}

		var xhr = new XMLHttpRequest();
		xhr.addEventListener('error', function() { done($elm$http$Http$NetworkError_); });
		xhr.addEventListener('timeout', function() { done($elm$http$Http$Timeout_); });
		xhr.addEventListener('load', function() { done(_Http_toResponse(request.expect.b, xhr)); });
		$elm$core$Maybe$isJust(request.tracker) && _Http_track(router, xhr, request.tracker.a);

		try {
			xhr.open(request.method, request.url, true);
		} catch (e) {
			return done($elm$http$Http$BadUrl_(request.url));
		}

		_Http_configureRequest(xhr, request);

		request.body.a && xhr.setRequestHeader('Content-Type', request.body.a);
		xhr.send(request.body.b);

		return function() { xhr.c = true; xhr.abort(); };
	});
});


// CONFIGURE

function _Http_configureRequest(xhr, request)
{
	for (var headers = request.headers; headers.b; headers = headers.b) // WHILE_CONS
	{
		xhr.setRequestHeader(headers.a.a, headers.a.b);
	}
	xhr.timeout = request.timeout.a || 0;
	xhr.responseType = request.expect.d;
	xhr.withCredentials = request.allowCookiesFromOtherDomains;
}


// RESPONSES

function _Http_toResponse(toBody, xhr)
{
	return A2(
		200 <= xhr.status && xhr.status < 300 ? $elm$http$Http$GoodStatus_ : $elm$http$Http$BadStatus_,
		_Http_toMetadata(xhr),
		toBody(xhr.response)
	);
}


// METADATA

function _Http_toMetadata(xhr)
{
	return {
		url: xhr.responseURL,
		statusCode: xhr.status,
		statusText: xhr.statusText,
		headers: _Http_parseHeaders(xhr.getAllResponseHeaders())
	};
}


// HEADERS

function _Http_parseHeaders(rawHeaders)
{
	if (!rawHeaders)
	{
		return $elm$core$Dict$empty;
	}

	var headers = $elm$core$Dict$empty;
	var headerPairs = rawHeaders.split('\r\n');
	for (var i = headerPairs.length; i--; )
	{
		var headerPair = headerPairs[i];
		var index = headerPair.indexOf(': ');
		if (index > 0)
		{
			var key = headerPair.substring(0, index);
			var value = headerPair.substring(index + 2);

			headers = A3($elm$core$Dict$update, key, function(oldValue) {
				return $elm$core$Maybe$Just($elm$core$Maybe$isJust(oldValue)
					? value + ', ' + oldValue.a
					: value
				);
			}, headers);
		}
	}
	return headers;
}


// EXPECT

var _Http_expect = F3(function(type, toBody, toValue)
{
	return {
		$: 0,
		d: type,
		b: toBody,
		a: toValue
	};
});

var _Http_mapExpect = F2(function(func, expect)
{
	return {
		$: 0,
		d: expect.d,
		b: expect.b,
		a: function(x) { return func(expect.a(x)); }
	};
});

function _Http_toDataView(arrayBuffer)
{
	return new DataView(arrayBuffer);
}


// BODY and PARTS

var _Http_emptyBody = { $: 0 };
var _Http_pair = F2(function(a, b) { return { $: 0, a: a, b: b }; });

function _Http_toFormData(parts)
{
	for (var formData = new FormData(); parts.b; parts = parts.b) // WHILE_CONS
	{
		var part = parts.a;
		formData.append(part.a, part.b);
	}
	return formData;
}

var _Http_bytesToBlob = F2(function(mime, bytes)
{
	return new Blob([bytes], { type: mime });
});


// PROGRESS

function _Http_track(router, xhr, tracker)
{
	// TODO check out lengthComputable on loadstart event

	xhr.upload.addEventListener('progress', function(event) {
		if (xhr.c) { return; }
		_Scheduler_rawSpawn(A2($elm$core$Platform$sendToSelf, router, _Utils_Tuple2(tracker, $elm$http$Http$Sending({
			sent: event.loaded,
			size: event.total
		}))));
	});
	xhr.addEventListener('progress', function(event) {
		if (xhr.c) { return; }
		_Scheduler_rawSpawn(A2($elm$core$Platform$sendToSelf, router, _Utils_Tuple2(tracker, $elm$http$Http$Receiving({
			received: event.loaded,
			size: event.lengthComputable ? $elm$core$Maybe$Just(event.total) : $elm$core$Maybe$Nothing
		}))));
	});
}

function _Url_percentEncode(string)
{
	return encodeURIComponent(string);
}

function _Url_percentDecode(string)
{
	try
	{
		return $elm$core$Maybe$Just(decodeURIComponent(string));
	}
	catch (e)
	{
		return $elm$core$Maybe$Nothing;
	}
}

// CREATE

var _Regex_never = /.^/;

var _Regex_fromStringWith = F2(function(options, string)
{
	var flags = 'g';
	if (options.multiline) { flags += 'm'; }
	if (options.caseInsensitive) { flags += 'i'; }

	try
	{
		return $elm$core$Maybe$Just(new RegExp(string, flags));
	}
	catch(error)
	{
		return $elm$core$Maybe$Nothing;
	}
});


// USE

var _Regex_contains = F2(function(re, string)
{
	return string.match(re) !== null;
});


var _Regex_findAtMost = F3(function(n, re, str)
{
	var out = [];
	var number = 0;
	var string = str;
	var lastIndex = re.lastIndex;
	var prevLastIndex = -1;
	var result;
	while (number++ < n && (result = re.exec(string)))
	{
		if (prevLastIndex == re.lastIndex) break;
		var i = result.length - 1;
		var subs = new Array(i);
		while (i > 0)
		{
			var submatch = result[i];
			subs[--i] = submatch
				? $elm$core$Maybe$Just(submatch)
				: $elm$core$Maybe$Nothing;
		}
		out.push(A4($elm$regex$Regex$Match, result[0], result.index, number, _List_fromArray(subs)));
		prevLastIndex = re.lastIndex;
	}
	re.lastIndex = lastIndex;
	return _List_fromArray(out);
});


var _Regex_replaceAtMost = F4(function(n, re, replacer, string)
{
	var count = 0;
	function jsReplacer(match)
	{
		if (count++ >= n)
		{
			return match;
		}
		var i = arguments.length - 3;
		var submatches = new Array(i);
		while (i > 0)
		{
			var submatch = arguments[i];
			submatches[--i] = submatch
				? $elm$core$Maybe$Just(submatch)
				: $elm$core$Maybe$Nothing;
		}
		return replacer(A4($elm$regex$Regex$Match, match, arguments[arguments.length - 2], count, _List_fromArray(submatches)));
	}
	return string.replace(re, jsReplacer);
});

var _Regex_splitAtMost = F3(function(n, re, str)
{
	var string = str;
	var out = [];
	var start = re.lastIndex;
	var restoreLastIndex = re.lastIndex;
	while (n--)
	{
		var result = re.exec(string);
		if (!result) break;
		out.push(string.slice(start, result.index));
		start = re.lastIndex;
	}
	out.push(string.slice(start));
	re.lastIndex = restoreLastIndex;
	return _List_fromArray(out);
});

var _Regex_infinity = Infinity;
var $elm$core$Basics$EQ = {$: 'EQ'};
var $elm$core$Basics$GT = {$: 'GT'};
var $elm$core$Basics$LT = {$: 'LT'};
var $elm$core$List$cons = _List_cons;
var $elm$core$Dict$foldr = F3(
	function (func, acc, t) {
		foldr:
		while (true) {
			if (t.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = t.b;
				var value = t.c;
				var left = t.d;
				var right = t.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldr, func, acc, right)),
					$temp$t = left;
				func = $temp$func;
				acc = $temp$acc;
				t = $temp$t;
				continue foldr;
			}
		}
	});
var $elm$core$Dict$toList = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, list) {
				return A2(
					$elm$core$List$cons,
					_Utils_Tuple2(key, value),
					list);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Dict$keys = function (dict) {
	return A3(
		$elm$core$Dict$foldr,
		F3(
			function (key, value, keyList) {
				return A2($elm$core$List$cons, key, keyList);
			}),
		_List_Nil,
		dict);
};
var $elm$core$Set$toList = function (_v0) {
	var dict = _v0.a;
	return $elm$core$Dict$keys(dict);
};
var $elm$core$Elm$JsArray$foldr = _JsArray_foldr;
var $elm$core$Array$foldr = F3(
	function (func, baseCase, _v0) {
		var tree = _v0.c;
		var tail = _v0.d;
		var helper = F2(
			function (node, acc) {
				if (node.$ === 'SubTree') {
					var subTree = node.a;
					return A3($elm$core$Elm$JsArray$foldr, helper, acc, subTree);
				} else {
					var values = node.a;
					return A3($elm$core$Elm$JsArray$foldr, func, acc, values);
				}
			});
		return A3(
			$elm$core$Elm$JsArray$foldr,
			helper,
			A3($elm$core$Elm$JsArray$foldr, func, baseCase, tail),
			tree);
	});
var $elm$core$Array$toList = function (array) {
	return A3($elm$core$Array$foldr, $elm$core$List$cons, _List_Nil, array);
};
var $elm$core$Result$Err = function (a) {
	return {$: 'Err', a: a};
};
var $elm$json$Json$Decode$Failure = F2(
	function (a, b) {
		return {$: 'Failure', a: a, b: b};
	});
var $elm$json$Json$Decode$Field = F2(
	function (a, b) {
		return {$: 'Field', a: a, b: b};
	});
var $elm$json$Json$Decode$Index = F2(
	function (a, b) {
		return {$: 'Index', a: a, b: b};
	});
var $elm$core$Result$Ok = function (a) {
	return {$: 'Ok', a: a};
};
var $elm$json$Json$Decode$OneOf = function (a) {
	return {$: 'OneOf', a: a};
};
var $elm$core$Basics$False = {$: 'False'};
var $elm$core$Basics$add = _Basics_add;
var $elm$core$Maybe$Just = function (a) {
	return {$: 'Just', a: a};
};
var $elm$core$Maybe$Nothing = {$: 'Nothing'};
var $elm$core$String$all = _String_all;
var $elm$core$Basics$and = _Basics_and;
var $elm$core$Basics$append = _Utils_append;
var $elm$json$Json$Encode$encode = _Json_encode;
var $elm$core$String$fromInt = _String_fromNumber;
var $elm$core$String$join = F2(
	function (sep, chunks) {
		return A2(
			_String_join,
			sep,
			_List_toArray(chunks));
	});
var $elm$core$String$split = F2(
	function (sep, string) {
		return _List_fromArray(
			A2(_String_split, sep, string));
	});
var $elm$json$Json$Decode$indent = function (str) {
	return A2(
		$elm$core$String$join,
		'\n    ',
		A2($elm$core$String$split, '\n', str));
};
var $elm$core$List$foldl = F3(
	function (func, acc, list) {
		foldl:
		while (true) {
			if (!list.b) {
				return acc;
			} else {
				var x = list.a;
				var xs = list.b;
				var $temp$func = func,
					$temp$acc = A2(func, x, acc),
					$temp$list = xs;
				func = $temp$func;
				acc = $temp$acc;
				list = $temp$list;
				continue foldl;
			}
		}
	});
var $elm$core$List$length = function (xs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, i) {
				return i + 1;
			}),
		0,
		xs);
};
var $elm$core$List$map2 = _List_map2;
var $elm$core$Basics$le = _Utils_le;
var $elm$core$Basics$sub = _Basics_sub;
var $elm$core$List$rangeHelp = F3(
	function (lo, hi, list) {
		rangeHelp:
		while (true) {
			if (_Utils_cmp(lo, hi) < 1) {
				var $temp$lo = lo,
					$temp$hi = hi - 1,
					$temp$list = A2($elm$core$List$cons, hi, list);
				lo = $temp$lo;
				hi = $temp$hi;
				list = $temp$list;
				continue rangeHelp;
			} else {
				return list;
			}
		}
	});
var $elm$core$List$range = F2(
	function (lo, hi) {
		return A3($elm$core$List$rangeHelp, lo, hi, _List_Nil);
	});
var $elm$core$List$indexedMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$map2,
			f,
			A2(
				$elm$core$List$range,
				0,
				$elm$core$List$length(xs) - 1),
			xs);
	});
var $elm$core$Char$toCode = _Char_toCode;
var $elm$core$Char$isLower = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (97 <= code) && (code <= 122);
};
var $elm$core$Char$isUpper = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 90) && (65 <= code);
};
var $elm$core$Basics$or = _Basics_or;
var $elm$core$Char$isAlpha = function (_char) {
	return $elm$core$Char$isLower(_char) || $elm$core$Char$isUpper(_char);
};
var $elm$core$Char$isDigit = function (_char) {
	var code = $elm$core$Char$toCode(_char);
	return (code <= 57) && (48 <= code);
};
var $elm$core$Char$isAlphaNum = function (_char) {
	return $elm$core$Char$isLower(_char) || ($elm$core$Char$isUpper(_char) || $elm$core$Char$isDigit(_char));
};
var $elm$core$List$reverse = function (list) {
	return A3($elm$core$List$foldl, $elm$core$List$cons, _List_Nil, list);
};
var $elm$core$String$uncons = _String_uncons;
var $elm$json$Json$Decode$errorOneOf = F2(
	function (i, error) {
		return '\n\n(' + ($elm$core$String$fromInt(i + 1) + (') ' + $elm$json$Json$Decode$indent(
			$elm$json$Json$Decode$errorToString(error))));
	});
var $elm$json$Json$Decode$errorToString = function (error) {
	return A2($elm$json$Json$Decode$errorToStringHelp, error, _List_Nil);
};
var $elm$json$Json$Decode$errorToStringHelp = F2(
	function (error, context) {
		errorToStringHelp:
		while (true) {
			switch (error.$) {
				case 'Field':
					var f = error.a;
					var err = error.b;
					var isSimple = function () {
						var _v1 = $elm$core$String$uncons(f);
						if (_v1.$ === 'Nothing') {
							return false;
						} else {
							var _v2 = _v1.a;
							var _char = _v2.a;
							var rest = _v2.b;
							return $elm$core$Char$isAlpha(_char) && A2($elm$core$String$all, $elm$core$Char$isAlphaNum, rest);
						}
					}();
					var fieldName = isSimple ? ('.' + f) : ('[\'' + (f + '\']'));
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, fieldName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'Index':
					var i = error.a;
					var err = error.b;
					var indexName = '[' + ($elm$core$String$fromInt(i) + ']');
					var $temp$error = err,
						$temp$context = A2($elm$core$List$cons, indexName, context);
					error = $temp$error;
					context = $temp$context;
					continue errorToStringHelp;
				case 'OneOf':
					var errors = error.a;
					if (!errors.b) {
						return 'Ran into a Json.Decode.oneOf with no possibilities' + function () {
							if (!context.b) {
								return '!';
							} else {
								return ' at json' + A2(
									$elm$core$String$join,
									'',
									$elm$core$List$reverse(context));
							}
						}();
					} else {
						if (!errors.b.b) {
							var err = errors.a;
							var $temp$error = err,
								$temp$context = context;
							error = $temp$error;
							context = $temp$context;
							continue errorToStringHelp;
						} else {
							var starter = function () {
								if (!context.b) {
									return 'Json.Decode.oneOf';
								} else {
									return 'The Json.Decode.oneOf at json' + A2(
										$elm$core$String$join,
										'',
										$elm$core$List$reverse(context));
								}
							}();
							var introduction = starter + (' failed in the following ' + ($elm$core$String$fromInt(
								$elm$core$List$length(errors)) + ' ways:'));
							return A2(
								$elm$core$String$join,
								'\n\n',
								A2(
									$elm$core$List$cons,
									introduction,
									A2($elm$core$List$indexedMap, $elm$json$Json$Decode$errorOneOf, errors)));
						}
					}
				default:
					var msg = error.a;
					var json = error.b;
					var introduction = function () {
						if (!context.b) {
							return 'Problem with the given value:\n\n';
						} else {
							return 'Problem with the value at json' + (A2(
								$elm$core$String$join,
								'',
								$elm$core$List$reverse(context)) + ':\n\n    ');
						}
					}();
					return introduction + ($elm$json$Json$Decode$indent(
						A2($elm$json$Json$Encode$encode, 4, json)) + ('\n\n' + msg));
			}
		}
	});
var $elm$core$Array$branchFactor = 32;
var $elm$core$Array$Array_elm_builtin = F4(
	function (a, b, c, d) {
		return {$: 'Array_elm_builtin', a: a, b: b, c: c, d: d};
	});
var $elm$core$Elm$JsArray$empty = _JsArray_empty;
var $elm$core$Basics$ceiling = _Basics_ceiling;
var $elm$core$Basics$fdiv = _Basics_fdiv;
var $elm$core$Basics$logBase = F2(
	function (base, number) {
		return _Basics_log(number) / _Basics_log(base);
	});
var $elm$core$Basics$toFloat = _Basics_toFloat;
var $elm$core$Array$shiftStep = $elm$core$Basics$ceiling(
	A2($elm$core$Basics$logBase, 2, $elm$core$Array$branchFactor));
var $elm$core$Array$empty = A4($elm$core$Array$Array_elm_builtin, 0, $elm$core$Array$shiftStep, $elm$core$Elm$JsArray$empty, $elm$core$Elm$JsArray$empty);
var $elm$core$Elm$JsArray$initialize = _JsArray_initialize;
var $elm$core$Array$Leaf = function (a) {
	return {$: 'Leaf', a: a};
};
var $elm$core$Basics$apL = F2(
	function (f, x) {
		return f(x);
	});
var $elm$core$Basics$apR = F2(
	function (x, f) {
		return f(x);
	});
var $elm$core$Basics$eq = _Utils_equal;
var $elm$core$Basics$floor = _Basics_floor;
var $elm$core$Elm$JsArray$length = _JsArray_length;
var $elm$core$Basics$gt = _Utils_gt;
var $elm$core$Basics$max = F2(
	function (x, y) {
		return (_Utils_cmp(x, y) > 0) ? x : y;
	});
var $elm$core$Basics$mul = _Basics_mul;
var $elm$core$Array$SubTree = function (a) {
	return {$: 'SubTree', a: a};
};
var $elm$core$Elm$JsArray$initializeFromList = _JsArray_initializeFromList;
var $elm$core$Array$compressNodes = F2(
	function (nodes, acc) {
		compressNodes:
		while (true) {
			var _v0 = A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodes);
			var node = _v0.a;
			var remainingNodes = _v0.b;
			var newAcc = A2(
				$elm$core$List$cons,
				$elm$core$Array$SubTree(node),
				acc);
			if (!remainingNodes.b) {
				return $elm$core$List$reverse(newAcc);
			} else {
				var $temp$nodes = remainingNodes,
					$temp$acc = newAcc;
				nodes = $temp$nodes;
				acc = $temp$acc;
				continue compressNodes;
			}
		}
	});
var $elm$core$Tuple$first = function (_v0) {
	var x = _v0.a;
	return x;
};
var $elm$core$Array$treeFromBuilder = F2(
	function (nodeList, nodeListSize) {
		treeFromBuilder:
		while (true) {
			var newNodeSize = $elm$core$Basics$ceiling(nodeListSize / $elm$core$Array$branchFactor);
			if (newNodeSize === 1) {
				return A2($elm$core$Elm$JsArray$initializeFromList, $elm$core$Array$branchFactor, nodeList).a;
			} else {
				var $temp$nodeList = A2($elm$core$Array$compressNodes, nodeList, _List_Nil),
					$temp$nodeListSize = newNodeSize;
				nodeList = $temp$nodeList;
				nodeListSize = $temp$nodeListSize;
				continue treeFromBuilder;
			}
		}
	});
var $elm$core$Array$builderToArray = F2(
	function (reverseNodeList, builder) {
		if (!builder.nodeListSize) {
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail),
				$elm$core$Array$shiftStep,
				$elm$core$Elm$JsArray$empty,
				builder.tail);
		} else {
			var treeLen = builder.nodeListSize * $elm$core$Array$branchFactor;
			var depth = $elm$core$Basics$floor(
				A2($elm$core$Basics$logBase, $elm$core$Array$branchFactor, treeLen - 1));
			var correctNodeList = reverseNodeList ? $elm$core$List$reverse(builder.nodeList) : builder.nodeList;
			var tree = A2($elm$core$Array$treeFromBuilder, correctNodeList, builder.nodeListSize);
			return A4(
				$elm$core$Array$Array_elm_builtin,
				$elm$core$Elm$JsArray$length(builder.tail) + treeLen,
				A2($elm$core$Basics$max, 5, depth * $elm$core$Array$shiftStep),
				tree,
				builder.tail);
		}
	});
var $elm$core$Basics$idiv = _Basics_idiv;
var $elm$core$Basics$lt = _Utils_lt;
var $elm$core$Array$initializeHelp = F5(
	function (fn, fromIndex, len, nodeList, tail) {
		initializeHelp:
		while (true) {
			if (fromIndex < 0) {
				return A2(
					$elm$core$Array$builderToArray,
					false,
					{nodeList: nodeList, nodeListSize: (len / $elm$core$Array$branchFactor) | 0, tail: tail});
			} else {
				var leaf = $elm$core$Array$Leaf(
					A3($elm$core$Elm$JsArray$initialize, $elm$core$Array$branchFactor, fromIndex, fn));
				var $temp$fn = fn,
					$temp$fromIndex = fromIndex - $elm$core$Array$branchFactor,
					$temp$len = len,
					$temp$nodeList = A2($elm$core$List$cons, leaf, nodeList),
					$temp$tail = tail;
				fn = $temp$fn;
				fromIndex = $temp$fromIndex;
				len = $temp$len;
				nodeList = $temp$nodeList;
				tail = $temp$tail;
				continue initializeHelp;
			}
		}
	});
var $elm$core$Basics$remainderBy = _Basics_remainderBy;
var $elm$core$Array$initialize = F2(
	function (len, fn) {
		if (len <= 0) {
			return $elm$core$Array$empty;
		} else {
			var tailLen = len % $elm$core$Array$branchFactor;
			var tail = A3($elm$core$Elm$JsArray$initialize, tailLen, len - tailLen, fn);
			var initialFromIndex = (len - tailLen) - $elm$core$Array$branchFactor;
			return A5($elm$core$Array$initializeHelp, fn, initialFromIndex, len, _List_Nil, tail);
		}
	});
var $elm$core$Basics$True = {$: 'True'};
var $elm$core$Result$isOk = function (result) {
	if (result.$ === 'Ok') {
		return true;
	} else {
		return false;
	}
};
var $elm$json$Json$Decode$map = _Json_map1;
var $elm$json$Json$Decode$map2 = _Json_map2;
var $elm$json$Json$Decode$succeed = _Json_succeed;
var $elm$virtual_dom$VirtualDom$toHandlerInt = function (handler) {
	switch (handler.$) {
		case 'Normal':
			return 0;
		case 'MayStopPropagation':
			return 1;
		case 'MayPreventDefault':
			return 2;
		default:
			return 3;
	}
};
var $elm$browser$Browser$External = function (a) {
	return {$: 'External', a: a};
};
var $elm$browser$Browser$Internal = function (a) {
	return {$: 'Internal', a: a};
};
var $elm$core$Basics$identity = function (x) {
	return x;
};
var $elm$browser$Browser$Dom$NotFound = function (a) {
	return {$: 'NotFound', a: a};
};
var $elm$url$Url$Http = {$: 'Http'};
var $elm$url$Url$Https = {$: 'Https'};
var $elm$url$Url$Url = F6(
	function (protocol, host, port_, path, query, fragment) {
		return {fragment: fragment, host: host, path: path, port_: port_, protocol: protocol, query: query};
	});
var $elm$core$String$contains = _String_contains;
var $elm$core$String$length = _String_length;
var $elm$core$String$slice = _String_slice;
var $elm$core$String$dropLeft = F2(
	function (n, string) {
		return (n < 1) ? string : A3(
			$elm$core$String$slice,
			n,
			$elm$core$String$length(string),
			string);
	});
var $elm$core$String$indexes = _String_indexes;
var $elm$core$String$isEmpty = function (string) {
	return string === '';
};
var $elm$core$String$left = F2(
	function (n, string) {
		return (n < 1) ? '' : A3($elm$core$String$slice, 0, n, string);
	});
var $elm$core$String$toInt = _String_toInt;
var $elm$url$Url$chompBeforePath = F5(
	function (protocol, path, params, frag, str) {
		if ($elm$core$String$isEmpty(str) || A2($elm$core$String$contains, '@', str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, ':', str);
			if (!_v0.b) {
				return $elm$core$Maybe$Just(
					A6($elm$url$Url$Url, protocol, str, $elm$core$Maybe$Nothing, path, params, frag));
			} else {
				if (!_v0.b.b) {
					var i = _v0.a;
					var _v1 = $elm$core$String$toInt(
						A2($elm$core$String$dropLeft, i + 1, str));
					if (_v1.$ === 'Nothing') {
						return $elm$core$Maybe$Nothing;
					} else {
						var port_ = _v1;
						return $elm$core$Maybe$Just(
							A6(
								$elm$url$Url$Url,
								protocol,
								A2($elm$core$String$left, i, str),
								port_,
								path,
								params,
								frag));
					}
				} else {
					return $elm$core$Maybe$Nothing;
				}
			}
		}
	});
var $elm$url$Url$chompBeforeQuery = F4(
	function (protocol, params, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '/', str);
			if (!_v0.b) {
				return A5($elm$url$Url$chompBeforePath, protocol, '/', params, frag, str);
			} else {
				var i = _v0.a;
				return A5(
					$elm$url$Url$chompBeforePath,
					protocol,
					A2($elm$core$String$dropLeft, i, str),
					params,
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompBeforeFragment = F3(
	function (protocol, frag, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '?', str);
			if (!_v0.b) {
				return A4($elm$url$Url$chompBeforeQuery, protocol, $elm$core$Maybe$Nothing, frag, str);
			} else {
				var i = _v0.a;
				return A4(
					$elm$url$Url$chompBeforeQuery,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					frag,
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$url$Url$chompAfterProtocol = F2(
	function (protocol, str) {
		if ($elm$core$String$isEmpty(str)) {
			return $elm$core$Maybe$Nothing;
		} else {
			var _v0 = A2($elm$core$String$indexes, '#', str);
			if (!_v0.b) {
				return A3($elm$url$Url$chompBeforeFragment, protocol, $elm$core$Maybe$Nothing, str);
			} else {
				var i = _v0.a;
				return A3(
					$elm$url$Url$chompBeforeFragment,
					protocol,
					$elm$core$Maybe$Just(
						A2($elm$core$String$dropLeft, i + 1, str)),
					A2($elm$core$String$left, i, str));
			}
		}
	});
var $elm$core$String$startsWith = _String_startsWith;
var $elm$url$Url$fromString = function (str) {
	return A2($elm$core$String$startsWith, 'http://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Http,
		A2($elm$core$String$dropLeft, 7, str)) : (A2($elm$core$String$startsWith, 'https://', str) ? A2(
		$elm$url$Url$chompAfterProtocol,
		$elm$url$Url$Https,
		A2($elm$core$String$dropLeft, 8, str)) : $elm$core$Maybe$Nothing);
};
var $elm$core$Basics$never = function (_v0) {
	never:
	while (true) {
		var nvr = _v0.a;
		var $temp$_v0 = nvr;
		_v0 = $temp$_v0;
		continue never;
	}
};
var $elm$core$Task$Perform = function (a) {
	return {$: 'Perform', a: a};
};
var $elm$core$Task$succeed = _Scheduler_succeed;
var $elm$core$Task$init = $elm$core$Task$succeed(_Utils_Tuple0);
var $elm$core$List$foldrHelper = F4(
	function (fn, acc, ctr, ls) {
		if (!ls.b) {
			return acc;
		} else {
			var a = ls.a;
			var r1 = ls.b;
			if (!r1.b) {
				return A2(fn, a, acc);
			} else {
				var b = r1.a;
				var r2 = r1.b;
				if (!r2.b) {
					return A2(
						fn,
						a,
						A2(fn, b, acc));
				} else {
					var c = r2.a;
					var r3 = r2.b;
					if (!r3.b) {
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(fn, c, acc)));
					} else {
						var d = r3.a;
						var r4 = r3.b;
						var res = (ctr > 500) ? A3(
							$elm$core$List$foldl,
							fn,
							acc,
							$elm$core$List$reverse(r4)) : A4($elm$core$List$foldrHelper, fn, acc, ctr + 1, r4);
						return A2(
							fn,
							a,
							A2(
								fn,
								b,
								A2(
									fn,
									c,
									A2(fn, d, res))));
					}
				}
			}
		}
	});
var $elm$core$List$foldr = F3(
	function (fn, acc, ls) {
		return A4($elm$core$List$foldrHelper, fn, acc, 0, ls);
	});
var $elm$core$List$map = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, acc) {
					return A2(
						$elm$core$List$cons,
						f(x),
						acc);
				}),
			_List_Nil,
			xs);
	});
var $elm$core$Task$andThen = _Scheduler_andThen;
var $elm$core$Task$map = F2(
	function (func, taskA) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return $elm$core$Task$succeed(
					func(a));
			},
			taskA);
	});
var $elm$core$Task$map2 = F3(
	function (func, taskA, taskB) {
		return A2(
			$elm$core$Task$andThen,
			function (a) {
				return A2(
					$elm$core$Task$andThen,
					function (b) {
						return $elm$core$Task$succeed(
							A2(func, a, b));
					},
					taskB);
			},
			taskA);
	});
var $elm$core$Task$sequence = function (tasks) {
	return A3(
		$elm$core$List$foldr,
		$elm$core$Task$map2($elm$core$List$cons),
		$elm$core$Task$succeed(_List_Nil),
		tasks);
};
var $elm$core$Platform$sendToApp = _Platform_sendToApp;
var $elm$core$Task$spawnCmd = F2(
	function (router, _v0) {
		var task = _v0.a;
		return _Scheduler_spawn(
			A2(
				$elm$core$Task$andThen,
				$elm$core$Platform$sendToApp(router),
				task));
	});
var $elm$core$Task$onEffects = F3(
	function (router, commands, state) {
		return A2(
			$elm$core$Task$map,
			function (_v0) {
				return _Utils_Tuple0;
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Task$spawnCmd(router),
					commands)));
	});
var $elm$core$Task$onSelfMsg = F3(
	function (_v0, _v1, _v2) {
		return $elm$core$Task$succeed(_Utils_Tuple0);
	});
var $elm$core$Task$cmdMap = F2(
	function (tagger, _v0) {
		var task = _v0.a;
		return $elm$core$Task$Perform(
			A2($elm$core$Task$map, tagger, task));
	});
_Platform_effectManagers['Task'] = _Platform_createManager($elm$core$Task$init, $elm$core$Task$onEffects, $elm$core$Task$onSelfMsg, $elm$core$Task$cmdMap);
var $elm$core$Task$command = _Platform_leaf('Task');
var $elm$core$Task$perform = F2(
	function (toMessage, task) {
		return $elm$core$Task$command(
			$elm$core$Task$Perform(
				A2($elm$core$Task$map, toMessage, task)));
	});
var $elm$browser$Browser$element = _Browser_element;
var $author$project$NethysSearch$Dark = {$: 'Dark'};
var $author$project$NethysSearch$List = {$: 'List'};
var $author$project$NethysSearch$Standard = {$: 'Standard'};
var $elm$core$Platform$Cmd$batch = _Platform_batch;
var $elm$json$Json$Decode$decodeValue = _Json_run;
var $author$project$NethysSearch$defaultFlags = {currentUrl: '/', elasticUrl: '', showHeader: true};
var $elm$core$Dict$RBEmpty_elm_builtin = {$: 'RBEmpty_elm_builtin'};
var $elm$core$Dict$empty = $elm$core$Dict$RBEmpty_elm_builtin;
var $elm$json$Json$Decode$andThen = _Json_andThen;
var $elm$json$Json$Decode$field = _Json_decodeField;
var $elm$json$Json$Decode$oneOf = _Json_oneOf;
var $elm$json$Json$Decode$maybe = function (decoder) {
	return $elm$json$Json$Decode$oneOf(
		_List_fromArray(
			[
				A2($elm$json$Json$Decode$map, $elm$core$Maybe$Just, decoder),
				$elm$json$Json$Decode$succeed($elm$core$Maybe$Nothing)
			]));
};
var $webbhuset$elm_json_decode$Json$Decode$Field$attempt = F3(
	function (fieldName, valueDecoder, continuation) {
		return A2(
			$elm$json$Json$Decode$andThen,
			continuation,
			$elm$json$Json$Decode$maybe(
				A2($elm$json$Json$Decode$field, fieldName, valueDecoder)));
	});
var $elm$json$Json$Decode$bool = _Json_decodeBool;
var $webbhuset$elm_json_decode$Json$Decode$Field$require = F3(
	function (fieldName, valueDecoder, continuation) {
		return A2(
			$elm$json$Json$Decode$andThen,
			continuation,
			A2($elm$json$Json$Decode$field, fieldName, valueDecoder));
	});
var $elm$json$Json$Decode$string = _Json_decodeString;
var $elm$core$Maybe$withDefault = F2(
	function (_default, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return value;
		} else {
			return _default;
		}
	});
var $author$project$NethysSearch$flagsDecoder = A3(
	$webbhuset$elm_json_decode$Json$Decode$Field$require,
	'currentUrl',
	$elm$json$Json$Decode$string,
	function (currentUrl) {
		return A3(
			$webbhuset$elm_json_decode$Json$Decode$Field$require,
			'elasticUrl',
			$elm$json$Json$Decode$string,
			function (elasticUrl) {
				return A3(
					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
					'showHeader',
					$elm$json$Json$Decode$bool,
					function (showHeader) {
						return $elm$json$Json$Decode$succeed(
							{
								currentUrl: currentUrl,
								elasticUrl: elasticUrl,
								showHeader: A2($elm$core$Maybe$withDefault, $author$project$NethysSearch$defaultFlags.showHeader, showHeader)
							});
					});
			});
	});
var $author$project$NethysSearch$GotAggregationsResult = function (a) {
	return {$: 'GotAggregationsResult', a: a};
};
var $elm$json$Json$Decode$list = _Json_decodeList;
var $author$project$NethysSearch$aggregationBucketDecoder = function (keyDecoder) {
	return A2(
		$elm$json$Json$Decode$field,
		'buckets',
		$elm$json$Json$Decode$list(
			A2($elm$json$Json$Decode$field, 'key', keyDecoder)));
};
var $elm$json$Json$Decode$at = F2(
	function (fields, decoder) {
		return A3($elm$core$List$foldr, $elm$json$Json$Decode$field, decoder, fields);
	});
var $webbhuset$elm_json_decode$Json$Decode$Field$requireAt = F3(
	function (path, valueDecoder, continuation) {
		return A2(
			$elm$json$Json$Decode$andThen,
			continuation,
			A2($elm$json$Json$Decode$at, path, valueDecoder));
	});
var $author$project$NethysSearch$aggregationsDecoder = A3(
	$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
	_List_fromArray(
		['aggregations', 'actions.keyword']),
	$author$project$NethysSearch$aggregationBucketDecoder($elm$json$Json$Decode$string),
	function (actions) {
		return A3(
			$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
			_List_fromArray(
				['aggregations', 'creature_family']),
			$author$project$NethysSearch$aggregationBucketDecoder($elm$json$Json$Decode$string),
			function (creatureFamilies) {
				return A3(
					$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
					_List_fromArray(
						['aggregations', 'item_category']),
					$author$project$NethysSearch$aggregationBucketDecoder($elm$json$Json$Decode$string),
					function (itemCategories) {
						return A3(
							$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
							_List_fromArray(
								['aggregations', 'item_subcategory']),
							$author$project$NethysSearch$aggregationBucketDecoder(
								A3(
									$webbhuset$elm_json_decode$Json$Decode$Field$require,
									'category',
									$elm$json$Json$Decode$string,
									function (category) {
										return A3(
											$webbhuset$elm_json_decode$Json$Decode$Field$require,
											'name',
											$elm$json$Json$Decode$string,
											function (name) {
												return $elm$json$Json$Decode$succeed(
													{category: category, name: name});
											});
									})),
							function (itemSubcategories) {
								return A3(
									$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
									_List_fromArray(
										['aggregations', 'source']),
									$author$project$NethysSearch$aggregationBucketDecoder(
										A3(
											$webbhuset$elm_json_decode$Json$Decode$Field$require,
											'category',
											$elm$json$Json$Decode$string,
											function (category) {
												return A3(
													$webbhuset$elm_json_decode$Json$Decode$Field$require,
													'name',
													$elm$json$Json$Decode$string,
													function (name) {
														return $elm$json$Json$Decode$succeed(
															{category: category, name: name});
													});
											})),
									function (sources) {
										return A3(
											$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
											_List_fromArray(
												['aggregations', 'trait']),
											$author$project$NethysSearch$aggregationBucketDecoder($elm$json$Json$Decode$string),
											function (traits) {
												return A3(
													$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
													_List_fromArray(
														['aggregations', 'type']),
													$author$project$NethysSearch$aggregationBucketDecoder($elm$json$Json$Decode$string),
													function (types) {
														return A3(
															$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
															_List_fromArray(
																['aggregations', 'weapon_group']),
															$author$project$NethysSearch$aggregationBucketDecoder($elm$json$Json$Decode$string),
															function (weaponGroups) {
																return $elm$json$Json$Decode$succeed(
																	{actions: actions, creatureFamilies: creatureFamilies, itemCategories: itemCategories, itemSubcategories: itemSubcategories, sources: sources, traits: traits, types: types, weaponGroups: weaponGroups});
															});
													});
											});
									});
							});
					});
			});
	});
var $elm$core$List$append = F2(
	function (xs, ys) {
		if (!ys.b) {
			return xs;
		} else {
			return A3($elm$core$List$foldr, $elm$core$List$cons, ys, xs);
		}
	});
var $elm$json$Json$Encode$object = function (pairs) {
	return _Json_wrap(
		A3(
			$elm$core$List$foldl,
			F2(
				function (_v0, obj) {
					var k = _v0.a;
					var v = _v0.b;
					return A3(_Json_addField, k, v, obj);
				}),
			_Json_emptyObject(_Utils_Tuple0),
			pairs));
};
var $elm$json$Json$Encode$string = _Json_wrap;
var $author$project$NethysSearch$buildCompositeTermsSource = function (_v0) {
	var name = _v0.a;
	var field = _v0.b;
	return _List_fromArray(
		[
			_Utils_Tuple2(
			name,
			$elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'terms',
						$elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'field',
									$elm$json$Json$Encode$string(field))
								])))
					])))
		]);
};
var $elm$json$Json$Encode$int = _Json_wrap;
var $elm$json$Json$Encode$list = F2(
	function (func, entries) {
		return _Json_wrap(
			A3(
				$elm$core$List$foldl,
				_Json_addEntry(func),
				_Json_emptyArray(_Utils_Tuple0),
				entries));
	});
var $author$project$NethysSearch$buildCompositeAggregation = F2(
	function (name, sources) {
		return _Utils_Tuple2(
			name,
			$elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'composite',
						$elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'sources',
									A2(
										$elm$json$Json$Encode$list,
										$elm$json$Json$Encode$object,
										A2($elm$core$List$map, $author$project$NethysSearch$buildCompositeTermsSource, sources))),
									_Utils_Tuple2(
									'size',
									$elm$json$Json$Encode$int(10000))
								])))
					])));
	});
var $author$project$NethysSearch$buildTermsAggregation = function (field) {
	return _Utils_Tuple2(
		field,
		$elm$json$Json$Encode$object(
			_List_fromArray(
				[
					_Utils_Tuple2(
					'terms',
					$elm$json$Json$Encode$object(
						_List_fromArray(
							[
								_Utils_Tuple2(
								'field',
								$elm$json$Json$Encode$string(field)),
								_Utils_Tuple2(
								'size',
								$elm$json$Json$Encode$int(10000))
							])))
				])));
};
var $author$project$NethysSearch$buildAggregationsBody = $elm$json$Json$Encode$object(
	_List_fromArray(
		[
			_Utils_Tuple2(
			'aggs',
			$elm$json$Json$Encode$object(
				A2(
					$elm$core$List$append,
					A2(
						$elm$core$List$map,
						$author$project$NethysSearch$buildTermsAggregation,
						_List_fromArray(
							['actions.keyword', 'creature_family', 'item_category', 'hands.keyword', 'reload_raw.keyword', 'trait', 'type', 'weapon_group'])),
					_List_fromArray(
						[
							A2(
							$author$project$NethysSearch$buildCompositeAggregation,
							'item_subcategory',
							_List_fromArray(
								[
									_Utils_Tuple2('category', 'item_category'),
									_Utils_Tuple2('name', 'item_subcategory')
								])),
							A2(
							$author$project$NethysSearch$buildCompositeAggregation,
							'source',
							_List_fromArray(
								[
									_Utils_Tuple2('category', 'source_category'),
									_Utils_Tuple2('name', 'name.keyword')
								]))
						])))),
			_Utils_Tuple2(
			'size',
			$elm$json$Json$Encode$int(0))
		]));
var $elm$json$Json$Decode$decodeString = _Json_runOnString;
var $elm$http$Http$BadStatus_ = F2(
	function (a, b) {
		return {$: 'BadStatus_', a: a, b: b};
	});
var $elm$http$Http$BadUrl_ = function (a) {
	return {$: 'BadUrl_', a: a};
};
var $elm$http$Http$GoodStatus_ = F2(
	function (a, b) {
		return {$: 'GoodStatus_', a: a, b: b};
	});
var $elm$http$Http$NetworkError_ = {$: 'NetworkError_'};
var $elm$http$Http$Receiving = function (a) {
	return {$: 'Receiving', a: a};
};
var $elm$http$Http$Sending = function (a) {
	return {$: 'Sending', a: a};
};
var $elm$http$Http$Timeout_ = {$: 'Timeout_'};
var $elm$core$Maybe$isJust = function (maybe) {
	if (maybe.$ === 'Just') {
		return true;
	} else {
		return false;
	}
};
var $elm$core$Platform$sendToSelf = _Platform_sendToSelf;
var $elm$core$Basics$compare = _Utils_compare;
var $elm$core$Dict$get = F2(
	function (targetKey, dict) {
		get:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return $elm$core$Maybe$Nothing;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var _v1 = A2($elm$core$Basics$compare, targetKey, key);
				switch (_v1.$) {
					case 'LT':
						var $temp$targetKey = targetKey,
							$temp$dict = left;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
					case 'EQ':
						return $elm$core$Maybe$Just(value);
					default:
						var $temp$targetKey = targetKey,
							$temp$dict = right;
						targetKey = $temp$targetKey;
						dict = $temp$dict;
						continue get;
				}
			}
		}
	});
var $elm$core$Dict$Black = {$: 'Black'};
var $elm$core$Dict$RBNode_elm_builtin = F5(
	function (a, b, c, d, e) {
		return {$: 'RBNode_elm_builtin', a: a, b: b, c: c, d: d, e: e};
	});
var $elm$core$Dict$Red = {$: 'Red'};
var $elm$core$Dict$balance = F5(
	function (color, key, value, left, right) {
		if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Red')) {
			var _v1 = right.a;
			var rK = right.b;
			var rV = right.c;
			var rLeft = right.d;
			var rRight = right.e;
			if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
				var _v3 = left.a;
				var lK = left.b;
				var lV = left.c;
				var lLeft = left.d;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					key,
					value,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					rK,
					rV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, left, rLeft),
					rRight);
			}
		} else {
			if ((((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) && (left.d.$ === 'RBNode_elm_builtin')) && (left.d.a.$ === 'Red')) {
				var _v5 = left.a;
				var lK = left.b;
				var lV = left.c;
				var _v6 = left.d;
				var _v7 = _v6.a;
				var llK = _v6.b;
				var llV = _v6.c;
				var llLeft = _v6.d;
				var llRight = _v6.e;
				var lRight = left.e;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Red,
					lK,
					lV,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, key, value, lRight, right));
			} else {
				return A5($elm$core$Dict$RBNode_elm_builtin, color, key, value, left, right);
			}
		}
	});
var $elm$core$Dict$insertHelp = F3(
	function (key, value, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, $elm$core$Dict$RBEmpty_elm_builtin, $elm$core$Dict$RBEmpty_elm_builtin);
		} else {
			var nColor = dict.a;
			var nKey = dict.b;
			var nValue = dict.c;
			var nLeft = dict.d;
			var nRight = dict.e;
			var _v1 = A2($elm$core$Basics$compare, key, nKey);
			switch (_v1.$) {
				case 'LT':
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						A3($elm$core$Dict$insertHelp, key, value, nLeft),
						nRight);
				case 'EQ':
					return A5($elm$core$Dict$RBNode_elm_builtin, nColor, nKey, value, nLeft, nRight);
				default:
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						nLeft,
						A3($elm$core$Dict$insertHelp, key, value, nRight));
			}
		}
	});
var $elm$core$Dict$insert = F3(
	function (key, value, dict) {
		var _v0 = A3($elm$core$Dict$insertHelp, key, value, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$getMin = function (dict) {
	getMin:
	while (true) {
		if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
			var left = dict.d;
			var $temp$dict = left;
			dict = $temp$dict;
			continue getMin;
		} else {
			return dict;
		}
	}
};
var $elm$core$Dict$moveRedLeft = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.e.d.$ === 'RBNode_elm_builtin') && (dict.e.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var lLeft = _v1.d;
			var lRight = _v1.e;
			var _v2 = dict.e;
			var rClr = _v2.a;
			var rK = _v2.b;
			var rV = _v2.c;
			var rLeft = _v2.d;
			var _v3 = rLeft.a;
			var rlK = rLeft.b;
			var rlV = rLeft.c;
			var rlL = rLeft.d;
			var rlR = rLeft.e;
			var rRight = _v2.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				rlK,
				rlV,
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					rlL),
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, rK, rV, rlR, rRight));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v4 = dict.d;
			var lClr = _v4.a;
			var lK = _v4.b;
			var lV = _v4.c;
			var lLeft = _v4.d;
			var lRight = _v4.e;
			var _v5 = dict.e;
			var rClr = _v5.a;
			var rK = _v5.b;
			var rV = _v5.c;
			var rLeft = _v5.d;
			var rRight = _v5.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$moveRedRight = function (dict) {
	if (((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) && (dict.e.$ === 'RBNode_elm_builtin')) {
		if ((dict.d.d.$ === 'RBNode_elm_builtin') && (dict.d.d.a.$ === 'Red')) {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v1 = dict.d;
			var lClr = _v1.a;
			var lK = _v1.b;
			var lV = _v1.c;
			var _v2 = _v1.d;
			var _v3 = _v2.a;
			var llK = _v2.b;
			var llV = _v2.c;
			var llLeft = _v2.d;
			var llRight = _v2.e;
			var lRight = _v1.e;
			var _v4 = dict.e;
			var rClr = _v4.a;
			var rK = _v4.b;
			var rV = _v4.c;
			var rLeft = _v4.d;
			var rRight = _v4.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				$elm$core$Dict$Red,
				lK,
				lV,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, llK, llV, llLeft, llRight),
				A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					lRight,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight)));
		} else {
			var clr = dict.a;
			var k = dict.b;
			var v = dict.c;
			var _v5 = dict.d;
			var lClr = _v5.a;
			var lK = _v5.b;
			var lV = _v5.c;
			var lLeft = _v5.d;
			var lRight = _v5.e;
			var _v6 = dict.e;
			var rClr = _v6.a;
			var rK = _v6.b;
			var rV = _v6.c;
			var rLeft = _v6.d;
			var rRight = _v6.e;
			if (clr.$ === 'Black') {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			} else {
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					$elm$core$Dict$Black,
					k,
					v,
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, lK, lV, lLeft, lRight),
					A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, rK, rV, rLeft, rRight));
			}
		}
	} else {
		return dict;
	}
};
var $elm$core$Dict$removeHelpPrepEQGT = F7(
	function (targetKey, dict, color, key, value, left, right) {
		if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Red')) {
			var _v1 = left.a;
			var lK = left.b;
			var lV = left.c;
			var lLeft = left.d;
			var lRight = left.e;
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				lK,
				lV,
				lLeft,
				A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Red, key, value, lRight, right));
		} else {
			_v2$2:
			while (true) {
				if ((right.$ === 'RBNode_elm_builtin') && (right.a.$ === 'Black')) {
					if (right.d.$ === 'RBNode_elm_builtin') {
						if (right.d.a.$ === 'Black') {
							var _v3 = right.a;
							var _v4 = right.d;
							var _v5 = _v4.a;
							return $elm$core$Dict$moveRedRight(dict);
						} else {
							break _v2$2;
						}
					} else {
						var _v6 = right.a;
						var _v7 = right.d;
						return $elm$core$Dict$moveRedRight(dict);
					}
				} else {
					break _v2$2;
				}
			}
			return dict;
		}
	});
var $elm$core$Dict$removeMin = function (dict) {
	if ((dict.$ === 'RBNode_elm_builtin') && (dict.d.$ === 'RBNode_elm_builtin')) {
		var color = dict.a;
		var key = dict.b;
		var value = dict.c;
		var left = dict.d;
		var lColor = left.a;
		var lLeft = left.d;
		var right = dict.e;
		if (lColor.$ === 'Black') {
			if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
				var _v3 = lLeft.a;
				return A5(
					$elm$core$Dict$RBNode_elm_builtin,
					color,
					key,
					value,
					$elm$core$Dict$removeMin(left),
					right);
			} else {
				var _v4 = $elm$core$Dict$moveRedLeft(dict);
				if (_v4.$ === 'RBNode_elm_builtin') {
					var nColor = _v4.a;
					var nKey = _v4.b;
					var nValue = _v4.c;
					var nLeft = _v4.d;
					var nRight = _v4.e;
					return A5(
						$elm$core$Dict$balance,
						nColor,
						nKey,
						nValue,
						$elm$core$Dict$removeMin(nLeft),
						nRight);
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			}
		} else {
			return A5(
				$elm$core$Dict$RBNode_elm_builtin,
				color,
				key,
				value,
				$elm$core$Dict$removeMin(left),
				right);
		}
	} else {
		return $elm$core$Dict$RBEmpty_elm_builtin;
	}
};
var $elm$core$Dict$removeHelp = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBEmpty_elm_builtin') {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		} else {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_cmp(targetKey, key) < 0) {
				if ((left.$ === 'RBNode_elm_builtin') && (left.a.$ === 'Black')) {
					var _v4 = left.a;
					var lLeft = left.d;
					if ((lLeft.$ === 'RBNode_elm_builtin') && (lLeft.a.$ === 'Red')) {
						var _v6 = lLeft.a;
						return A5(
							$elm$core$Dict$RBNode_elm_builtin,
							color,
							key,
							value,
							A2($elm$core$Dict$removeHelp, targetKey, left),
							right);
					} else {
						var _v7 = $elm$core$Dict$moveRedLeft(dict);
						if (_v7.$ === 'RBNode_elm_builtin') {
							var nColor = _v7.a;
							var nKey = _v7.b;
							var nValue = _v7.c;
							var nLeft = _v7.d;
							var nRight = _v7.e;
							return A5(
								$elm$core$Dict$balance,
								nColor,
								nKey,
								nValue,
								A2($elm$core$Dict$removeHelp, targetKey, nLeft),
								nRight);
						} else {
							return $elm$core$Dict$RBEmpty_elm_builtin;
						}
					}
				} else {
					return A5(
						$elm$core$Dict$RBNode_elm_builtin,
						color,
						key,
						value,
						A2($elm$core$Dict$removeHelp, targetKey, left),
						right);
				}
			} else {
				return A2(
					$elm$core$Dict$removeHelpEQGT,
					targetKey,
					A7($elm$core$Dict$removeHelpPrepEQGT, targetKey, dict, color, key, value, left, right));
			}
		}
	});
var $elm$core$Dict$removeHelpEQGT = F2(
	function (targetKey, dict) {
		if (dict.$ === 'RBNode_elm_builtin') {
			var color = dict.a;
			var key = dict.b;
			var value = dict.c;
			var left = dict.d;
			var right = dict.e;
			if (_Utils_eq(targetKey, key)) {
				var _v1 = $elm$core$Dict$getMin(right);
				if (_v1.$ === 'RBNode_elm_builtin') {
					var minKey = _v1.b;
					var minValue = _v1.c;
					return A5(
						$elm$core$Dict$balance,
						color,
						minKey,
						minValue,
						left,
						$elm$core$Dict$removeMin(right));
				} else {
					return $elm$core$Dict$RBEmpty_elm_builtin;
				}
			} else {
				return A5(
					$elm$core$Dict$balance,
					color,
					key,
					value,
					left,
					A2($elm$core$Dict$removeHelp, targetKey, right));
			}
		} else {
			return $elm$core$Dict$RBEmpty_elm_builtin;
		}
	});
var $elm$core$Dict$remove = F2(
	function (key, dict) {
		var _v0 = A2($elm$core$Dict$removeHelp, key, dict);
		if ((_v0.$ === 'RBNode_elm_builtin') && (_v0.a.$ === 'Red')) {
			var _v1 = _v0.a;
			var k = _v0.b;
			var v = _v0.c;
			var l = _v0.d;
			var r = _v0.e;
			return A5($elm$core$Dict$RBNode_elm_builtin, $elm$core$Dict$Black, k, v, l, r);
		} else {
			var x = _v0;
			return x;
		}
	});
var $elm$core$Dict$update = F3(
	function (targetKey, alter, dictionary) {
		var _v0 = alter(
			A2($elm$core$Dict$get, targetKey, dictionary));
		if (_v0.$ === 'Just') {
			var value = _v0.a;
			return A3($elm$core$Dict$insert, targetKey, value, dictionary);
		} else {
			return A2($elm$core$Dict$remove, targetKey, dictionary);
		}
	});
var $elm$core$Basics$composeR = F3(
	function (f, g, x) {
		return g(
			f(x));
	});
var $elm$http$Http$expectStringResponse = F2(
	function (toMsg, toResult) {
		return A3(
			_Http_expect,
			'',
			$elm$core$Basics$identity,
			A2($elm$core$Basics$composeR, toResult, toMsg));
	});
var $elm$core$Result$mapError = F2(
	function (f, result) {
		if (result.$ === 'Ok') {
			var v = result.a;
			return $elm$core$Result$Ok(v);
		} else {
			var e = result.a;
			return $elm$core$Result$Err(
				f(e));
		}
	});
var $elm$http$Http$BadBody = function (a) {
	return {$: 'BadBody', a: a};
};
var $elm$http$Http$BadStatus = function (a) {
	return {$: 'BadStatus', a: a};
};
var $elm$http$Http$BadUrl = function (a) {
	return {$: 'BadUrl', a: a};
};
var $elm$http$Http$NetworkError = {$: 'NetworkError'};
var $elm$http$Http$Timeout = {$: 'Timeout'};
var $elm$http$Http$resolve = F2(
	function (toResult, response) {
		switch (response.$) {
			case 'BadUrl_':
				var url = response.a;
				return $elm$core$Result$Err(
					$elm$http$Http$BadUrl(url));
			case 'Timeout_':
				return $elm$core$Result$Err($elm$http$Http$Timeout);
			case 'NetworkError_':
				return $elm$core$Result$Err($elm$http$Http$NetworkError);
			case 'BadStatus_':
				var metadata = response.a;
				return $elm$core$Result$Err(
					$elm$http$Http$BadStatus(metadata.statusCode));
			default:
				var body = response.b;
				return A2(
					$elm$core$Result$mapError,
					$elm$http$Http$BadBody,
					toResult(body));
		}
	});
var $elm$http$Http$expectJson = F2(
	function (toMsg, decoder) {
		return A2(
			$elm$http$Http$expectStringResponse,
			toMsg,
			$elm$http$Http$resolve(
				function (string) {
					return A2(
						$elm$core$Result$mapError,
						$elm$json$Json$Decode$errorToString,
						A2($elm$json$Json$Decode$decodeString, decoder, string));
				}));
	});
var $elm$http$Http$jsonBody = function (value) {
	return A2(
		_Http_pair,
		'application/json',
		A2($elm$json$Json$Encode$encode, 0, value));
};
var $elm$http$Http$Request = function (a) {
	return {$: 'Request', a: a};
};
var $elm$http$Http$State = F2(
	function (reqs, subs) {
		return {reqs: reqs, subs: subs};
	});
var $elm$http$Http$init = $elm$core$Task$succeed(
	A2($elm$http$Http$State, $elm$core$Dict$empty, _List_Nil));
var $elm$core$Process$kill = _Scheduler_kill;
var $elm$core$Process$spawn = _Scheduler_spawn;
var $elm$http$Http$updateReqs = F3(
	function (router, cmds, reqs) {
		updateReqs:
		while (true) {
			if (!cmds.b) {
				return $elm$core$Task$succeed(reqs);
			} else {
				var cmd = cmds.a;
				var otherCmds = cmds.b;
				if (cmd.$ === 'Cancel') {
					var tracker = cmd.a;
					var _v2 = A2($elm$core$Dict$get, tracker, reqs);
					if (_v2.$ === 'Nothing') {
						var $temp$router = router,
							$temp$cmds = otherCmds,
							$temp$reqs = reqs;
						router = $temp$router;
						cmds = $temp$cmds;
						reqs = $temp$reqs;
						continue updateReqs;
					} else {
						var pid = _v2.a;
						return A2(
							$elm$core$Task$andThen,
							function (_v3) {
								return A3(
									$elm$http$Http$updateReqs,
									router,
									otherCmds,
									A2($elm$core$Dict$remove, tracker, reqs));
							},
							$elm$core$Process$kill(pid));
					}
				} else {
					var req = cmd.a;
					return A2(
						$elm$core$Task$andThen,
						function (pid) {
							var _v4 = req.tracker;
							if (_v4.$ === 'Nothing') {
								return A3($elm$http$Http$updateReqs, router, otherCmds, reqs);
							} else {
								var tracker = _v4.a;
								return A3(
									$elm$http$Http$updateReqs,
									router,
									otherCmds,
									A3($elm$core$Dict$insert, tracker, pid, reqs));
							}
						},
						$elm$core$Process$spawn(
							A3(
								_Http_toTask,
								router,
								$elm$core$Platform$sendToApp(router),
								req)));
				}
			}
		}
	});
var $elm$http$Http$onEffects = F4(
	function (router, cmds, subs, state) {
		return A2(
			$elm$core$Task$andThen,
			function (reqs) {
				return $elm$core$Task$succeed(
					A2($elm$http$Http$State, reqs, subs));
			},
			A3($elm$http$Http$updateReqs, router, cmds, state.reqs));
	});
var $elm$core$List$maybeCons = F3(
	function (f, mx, xs) {
		var _v0 = f(mx);
		if (_v0.$ === 'Just') {
			var x = _v0.a;
			return A2($elm$core$List$cons, x, xs);
		} else {
			return xs;
		}
	});
var $elm$core$List$filterMap = F2(
	function (f, xs) {
		return A3(
			$elm$core$List$foldr,
			$elm$core$List$maybeCons(f),
			_List_Nil,
			xs);
	});
var $elm$http$Http$maybeSend = F4(
	function (router, desiredTracker, progress, _v0) {
		var actualTracker = _v0.a;
		var toMsg = _v0.b;
		return _Utils_eq(desiredTracker, actualTracker) ? $elm$core$Maybe$Just(
			A2(
				$elm$core$Platform$sendToApp,
				router,
				toMsg(progress))) : $elm$core$Maybe$Nothing;
	});
var $elm$http$Http$onSelfMsg = F3(
	function (router, _v0, state) {
		var tracker = _v0.a;
		var progress = _v0.b;
		return A2(
			$elm$core$Task$andThen,
			function (_v1) {
				return $elm$core$Task$succeed(state);
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$filterMap,
					A3($elm$http$Http$maybeSend, router, tracker, progress),
					state.subs)));
	});
var $elm$http$Http$Cancel = function (a) {
	return {$: 'Cancel', a: a};
};
var $elm$http$Http$cmdMap = F2(
	function (func, cmd) {
		if (cmd.$ === 'Cancel') {
			var tracker = cmd.a;
			return $elm$http$Http$Cancel(tracker);
		} else {
			var r = cmd.a;
			return $elm$http$Http$Request(
				{
					allowCookiesFromOtherDomains: r.allowCookiesFromOtherDomains,
					body: r.body,
					expect: A2(_Http_mapExpect, func, r.expect),
					headers: r.headers,
					method: r.method,
					timeout: r.timeout,
					tracker: r.tracker,
					url: r.url
				});
		}
	});
var $elm$http$Http$MySub = F2(
	function (a, b) {
		return {$: 'MySub', a: a, b: b};
	});
var $elm$http$Http$subMap = F2(
	function (func, _v0) {
		var tracker = _v0.a;
		var toMsg = _v0.b;
		return A2(
			$elm$http$Http$MySub,
			tracker,
			A2($elm$core$Basics$composeR, toMsg, func));
	});
_Platform_effectManagers['Http'] = _Platform_createManager($elm$http$Http$init, $elm$http$Http$onEffects, $elm$http$Http$onSelfMsg, $elm$http$Http$cmdMap, $elm$http$Http$subMap);
var $elm$http$Http$command = _Platform_leaf('Http');
var $elm$http$Http$subscription = _Platform_leaf('Http');
var $elm$http$Http$request = function (r) {
	return $elm$http$Http$command(
		$elm$http$Http$Request(
			{allowCookiesFromOtherDomains: false, body: r.body, expect: r.expect, headers: r.headers, method: r.method, timeout: r.timeout, tracker: r.tracker, url: r.url}));
};
var $author$project$NethysSearch$getAggregations = function (_v0) {
	var model = _v0.a;
	var cmd = _v0.b;
	return _Utils_Tuple2(
		model,
		$elm$core$Platform$Cmd$batch(
			_List_fromArray(
				[
					cmd,
					$elm$http$Http$request(
					{
						body: $elm$http$Http$jsonBody($author$project$NethysSearch$buildAggregationsBody),
						expect: A2($elm$http$Http$expectJson, $author$project$NethysSearch$GotAggregationsResult, $author$project$NethysSearch$aggregationsDecoder),
						headers: _List_Nil,
						method: 'POST',
						timeout: $elm$core$Maybe$Just(10000),
						tracker: $elm$core$Maybe$Nothing,
						url: model.elasticUrl + '/_search'
					})
				])));
};
var $author$project$NethysSearch$localStorage_get = _Platform_outgoingPort('localStorage_get', $elm$json$Json$Encode$string);
var $author$project$NethysSearch$parseUrl = function (url) {
	return A2(
		$elm$core$Maybe$withDefault,
		{fragment: $elm$core$Maybe$Nothing, host: '', path: '', port_: $elm$core$Maybe$Nothing, protocol: $elm$url$Url$Http, query: $elm$core$Maybe$Nothing},
		$elm$url$Url$fromString(url));
};
var $author$project$NethysSearch$GotSearchResult = function (a) {
	return {$: 'GotSearchResult', a: a};
};
var $elm$core$Maybe$andThen = F2(
	function (callback, maybeValue) {
		if (maybeValue.$ === 'Just') {
			var value = maybeValue.a;
			return callback(value);
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$NethysSearch$searchFields = _List_fromArray(
	['name', 'text^0.1', 'trait_raw', 'type']);
var $author$project$NethysSearch$buildElasticsearchQueryStringQueryBody = function (queryString) {
	return _List_fromArray(
		[
			_List_fromArray(
			[
				_Utils_Tuple2(
				'query_string',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'query',
							$elm$json$Json$Encode$string(queryString)),
							_Utils_Tuple2(
							'default_operator',
							$elm$json$Json$Encode$string('AND')),
							_Utils_Tuple2(
							'fields',
							A2($elm$json$Json$Encode$list, $elm$json$Json$Encode$string, $author$project$NethysSearch$searchFields))
						])))
			])
		]);
};
var $elm$core$List$filter = F2(
	function (isGood, list) {
		return A3(
			$elm$core$List$foldr,
			F2(
				function (x, xs) {
					return isGood(x) ? A2($elm$core$List$cons, x, xs) : xs;
				}),
			_List_Nil,
			list);
	});
var $elm$core$Tuple$second = function (_v0) {
	var y = _v0.b;
	return y;
};
var $author$project$NethysSearch$boolDictIncluded = function (dict) {
	return A2(
		$elm$core$List$map,
		$elm$core$Tuple$first,
		A2(
			$elm$core$List$filter,
			$elm$core$Tuple$second,
			$elm$core$Dict$toList(dict)));
};
var $elm$core$List$concat = function (lists) {
	return A3($elm$core$List$foldr, $elm$core$List$append, _List_Nil, lists);
};
var $elm$json$Json$Encode$float = _Json_wrap;
var $elm$core$Maybe$map = F2(
	function (f, maybe) {
		if (maybe.$ === 'Just') {
			var value = maybe.a;
			return $elm$core$Maybe$Just(
				f(value));
		} else {
			return $elm$core$Maybe$Nothing;
		}
	});
var $elm$core$Result$toMaybe = function (result) {
	if (result.$ === 'Ok') {
		var v = result.a;
		return $elm$core$Maybe$Just(v);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$NethysSearch$getAggregation = F2(
	function (fun, model) {
		return A2(
			$elm$core$Maybe$withDefault,
			_List_Nil,
			A2(
				$elm$core$Maybe$map,
				fun,
				A2($elm$core$Maybe$andThen, $elm$core$Result$toMaybe, model.aggregations)));
	});
var $elm$core$List$isEmpty = function (xs) {
	if (!xs.b) {
		return true;
	} else {
		return false;
	}
};
var $elm$core$List$any = F2(
	function (isOkay, list) {
		any:
		while (true) {
			if (!list.b) {
				return false;
			} else {
				var x = list.a;
				var xs = list.b;
				if (isOkay(x)) {
					return true;
				} else {
					var $temp$isOkay = isOkay,
						$temp$list = xs;
					isOkay = $temp$isOkay;
					list = $temp$list;
					continue any;
				}
			}
		}
	});
var $elm$core$List$member = F2(
	function (x, xs) {
		return A2(
			$elm$core$List$any,
			function (a) {
				return _Utils_eq(a, x);
			},
			xs);
	});
var $elm$core$Basics$neq = _Utils_notEqual;
var $elm$core$List$singleton = function (value) {
	return _List_fromArray(
		[value]);
};
var $elm$core$String$toFloat = _String_toFloat;
var $elm$core$String$toLower = _String_toLower;
var $elm_community$maybe_extra$Maybe$Extra$cons = F2(
	function (item, list) {
		if (item.$ === 'Just') {
			var v = item.a;
			return A2($elm$core$List$cons, v, list);
		} else {
			return list;
		}
	});
var $elm_community$maybe_extra$Maybe$Extra$values = A2($elm$core$List$foldr, $elm_community$maybe_extra$Maybe$Extra$cons, _List_Nil);
var $author$project$NethysSearch$buildSearchFilterTerms = function (model) {
	return $elm$core$List$concat(
		_List_fromArray(
			[
				$elm$core$List$concat(
				A2(
					$elm$core$List$map,
					function (_v0) {
						var field = _v0.a;
						var list = _v0.b;
						var isAnd = _v0.c;
						return $elm$core$List$isEmpty(list) ? _List_Nil : (isAnd ? A2(
							$elm$core$List$map,
							function (value) {
								return _List_fromArray(
									[
										_Utils_Tuple2(
										'term',
										$elm$json$Json$Encode$object(
											_List_fromArray(
												[
													_Utils_Tuple2(
													field,
													$elm$json$Json$Encode$object(
														_List_fromArray(
															[
																_Utils_Tuple2(
																'value',
																$elm$json$Json$Encode$string(value))
															])))
												])))
									]);
							},
							list) : _List_fromArray(
							[
								_List_fromArray(
								[
									_Utils_Tuple2(
									'bool',
									$elm$json$Json$Encode$object(
										_List_fromArray(
											[
												_Utils_Tuple2(
												'should',
												A2(
													$elm$json$Json$Encode$list,
													$elm$json$Json$Encode$object,
													$elm_community$maybe_extra$Maybe$Extra$values(
														_List_fromArray(
															[
																$elm$core$List$isEmpty(
																A2(
																	$elm$core$List$filter,
																	$elm$core$Basics$neq('none'),
																	list)) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
																_List_fromArray(
																	[
																		_Utils_Tuple2(
																		'terms',
																		$elm$json$Json$Encode$object(
																			_List_fromArray(
																				[
																					_Utils_Tuple2(
																					field,
																					A2(
																						$elm$json$Json$Encode$list,
																						$elm$json$Json$Encode$string,
																						A2(
																							$elm$core$List$filter,
																							$elm$core$Basics$neq('none'),
																							list)))
																				])))
																	])),
																A2($elm$core$List$member, 'none', list) ? $elm$core$Maybe$Just(
																_List_fromArray(
																	[
																		_Utils_Tuple2(
																		'bool',
																		$elm$json$Json$Encode$object(
																			_List_fromArray(
																				[
																					_Utils_Tuple2(
																					'must_not',
																					$elm$json$Json$Encode$object(
																						_List_fromArray(
																							[
																								_Utils_Tuple2(
																								'exists',
																								$elm$json$Json$Encode$object(
																									_List_fromArray(
																										[
																											_Utils_Tuple2(
																											'field',
																											$elm$json$Json$Encode$string(field))
																										])))
																							])))
																				])))
																	])) : $elm$core$Maybe$Nothing
															]))))
											])))
								])
							]));
					},
					_List_fromArray(
						[
							_Utils_Tuple3(
							'actions.keyword',
							$author$project$NethysSearch$boolDictIncluded(model.filteredActions),
							false),
							_Utils_Tuple3(
							'alignment',
							$author$project$NethysSearch$boolDictIncluded(model.filteredAlignments),
							false),
							_Utils_Tuple3(
							'component',
							$author$project$NethysSearch$boolDictIncluded(model.filteredComponents),
							model.filterComponentsOperator),
							_Utils_Tuple3(
							'creature_family',
							$author$project$NethysSearch$boolDictIncluded(model.filteredCreatureFamilies),
							false),
							_Utils_Tuple3(
							'item_category',
							$author$project$NethysSearch$boolDictIncluded(model.filteredItemCategories),
							false),
							_Utils_Tuple3(
							'item_subcategory',
							$author$project$NethysSearch$boolDictIncluded(model.filteredItemSubcategories),
							false),
							_Utils_Tuple3(
							'pfs',
							$author$project$NethysSearch$boolDictIncluded(model.filteredPfs),
							false),
							_Utils_Tuple3(
							'saving_throw',
							$author$project$NethysSearch$boolDictIncluded(model.filteredSavingThrows),
							false),
							_Utils_Tuple3(
							'school',
							$author$project$NethysSearch$boolDictIncluded(model.filteredSchools),
							false),
							_Utils_Tuple3(
							'size',
							$author$project$NethysSearch$boolDictIncluded(model.filteredSizes),
							false),
							_Utils_Tuple3(
							'source',
							$author$project$NethysSearch$boolDictIncluded(model.filteredSources),
							false),
							_Utils_Tuple3(
							'strongest_save',
							$author$project$NethysSearch$boolDictIncluded(model.filteredStrongestSaves),
							false),
							_Utils_Tuple3(
							'tradition',
							$author$project$NethysSearch$boolDictIncluded(model.filteredTraditions),
							model.filterTraditionsOperator),
							_Utils_Tuple3(
							'trait',
							$author$project$NethysSearch$boolDictIncluded(model.filteredTraits),
							model.filterTraitsOperator),
							_Utils_Tuple3(
							'type',
							$author$project$NethysSearch$boolDictIncluded(model.filteredTypes),
							false),
							_Utils_Tuple3(
							'weakest_save',
							$author$project$NethysSearch$boolDictIncluded(model.filteredWeakestSaves),
							false),
							_Utils_Tuple3(
							'weapon_category',
							$author$project$NethysSearch$boolDictIncluded(model.filteredWeaponCategories),
							false),
							_Utils_Tuple3(
							'weapon_group',
							$author$project$NethysSearch$boolDictIncluded(model.filteredWeaponGroups),
							false),
							_Utils_Tuple3(
							'weapon_type',
							$author$project$NethysSearch$boolDictIncluded(model.filteredWeaponTypes),
							false)
						]))),
				A2(
				$elm$core$List$map,
				function (_v1) {
					var field = _v1.a;
					var value = _v1.b;
					return _List_fromArray(
						[
							_Utils_Tuple2(
							'range',
							$elm$json$Json$Encode$object(
								_List_fromArray(
									[
										_Utils_Tuple2(
										field,
										$elm$json$Json$Encode$object(
											_List_fromArray(
												[
													_Utils_Tuple2(
													'gte',
													$elm$json$Json$Encode$float(
														A2(
															$elm$core$Maybe$withDefault,
															0,
															$elm$core$String$toFloat(value))))
												])))
									])))
						]);
				},
				$elm$core$Dict$toList(model.filteredFromValues)),
				A2(
				$elm$core$List$map,
				function (_v2) {
					var field = _v2.a;
					var value = _v2.b;
					return _List_fromArray(
						[
							_Utils_Tuple2(
							'range',
							$elm$json$Json$Encode$object(
								_List_fromArray(
									[
										_Utils_Tuple2(
										field,
										$elm$json$Json$Encode$object(
											_List_fromArray(
												[
													_Utils_Tuple2(
													'lte',
													$elm$json$Json$Encode$float(
														A2(
															$elm$core$Maybe$withDefault,
															0,
															$elm$core$String$toFloat(value))))
												])))
									])))
						]);
				},
				$elm$core$Dict$toList(model.filteredToValues)),
				$elm$core$List$isEmpty(
				$author$project$NethysSearch$boolDictIncluded(model.filteredSourceCategories)) ? _List_Nil : $elm$core$List$singleton(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'bool',
						$elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'should',
									A2(
										$elm$json$Json$Encode$list,
										$elm$json$Json$Encode$object,
										A2(
											$elm$core$List$map,
											function (category) {
												return _List_fromArray(
													[
														_Utils_Tuple2(
														'terms',
														$elm$json$Json$Encode$object(
															_List_fromArray(
																[
																	_Utils_Tuple2(
																	'source',
																	A2(
																		$elm$json$Json$Encode$list,
																		$elm$json$Json$Encode$string,
																		A2(
																			$elm$core$List$filterMap,
																			function (source) {
																				return _Utils_eq(
																					$elm$core$String$toLower(source.category),
																					category) ? $elm$core$Maybe$Just(source.name) : $elm$core$Maybe$Nothing;
																			},
																			A2(
																				$author$project$NethysSearch$getAggregation,
																				function ($) {
																					return $.sources;
																				},
																				model))))
																])))
													]);
											},
											$author$project$NethysSearch$boolDictIncluded(model.filteredSourceCategories))))
								])))
					]))
			]));
};
var $elm$core$Basics$not = _Basics_not;
var $author$project$NethysSearch$boolDictExcluded = function (dict) {
	return A2(
		$elm$core$List$map,
		$elm$core$Tuple$first,
		A2(
			$elm$core$List$filter,
			A2($elm$core$Basics$composeR, $elm$core$Tuple$second, $elm$core$Basics$not),
			$elm$core$Dict$toList(dict)));
};
var $author$project$NethysSearch$buildSearchMustNotTerms = function (model) {
	return $elm$core$List$concat(
		_List_fromArray(
			[
				$elm$core$List$concat(
				A2(
					$elm$core$List$map,
					function (_v0) {
						var field = _v0.a;
						var list = _v0.b;
						return $elm$core$List$isEmpty(list) ? _List_Nil : $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									$elm$core$List$isEmpty(
									A2(
										$elm$core$List$filter,
										$elm$core$Basics$neq('none'),
										list)) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
									_List_fromArray(
										[
											_Utils_Tuple2(
											'terms',
											$elm$json$Json$Encode$object(
												_List_fromArray(
													[
														_Utils_Tuple2(
														field,
														A2(
															$elm$json$Json$Encode$list,
															$elm$json$Json$Encode$string,
															A2(
																$elm$core$List$filter,
																$elm$core$Basics$neq('none'),
																list)))
													])))
										])),
									A2($elm$core$List$member, 'none', list) ? $elm$core$Maybe$Just(
									_List_fromArray(
										[
											_Utils_Tuple2(
											'bool',
											$elm$json$Json$Encode$object(
												_List_fromArray(
													[
														_Utils_Tuple2(
														'must_not',
														A2(
															$elm$json$Json$Encode$list,
															$elm$json$Json$Encode$object,
															_List_fromArray(
																[
																	_List_fromArray(
																	[
																		_Utils_Tuple2(
																		'exists',
																		$elm$json$Json$Encode$object(
																			_List_fromArray(
																				[
																					_Utils_Tuple2(
																					'field',
																					$elm$json$Json$Encode$string(field))
																				])))
																	])
																])))
													])))
										])) : $elm$core$Maybe$Nothing
								]));
					},
					_List_fromArray(
						[
							_Utils_Tuple2(
							'actions.keyword',
							$author$project$NethysSearch$boolDictExcluded(model.filteredActions)),
							_Utils_Tuple2(
							'alignment',
							$author$project$NethysSearch$boolDictExcluded(model.filteredAlignments)),
							_Utils_Tuple2(
							'component',
							$author$project$NethysSearch$boolDictExcluded(model.filteredComponents)),
							_Utils_Tuple2(
							'creature_family',
							$author$project$NethysSearch$boolDictExcluded(model.filteredCreatureFamilies)),
							_Utils_Tuple2(
							'item_category',
							$author$project$NethysSearch$boolDictExcluded(model.filteredItemCategories)),
							_Utils_Tuple2(
							'item_subcategory',
							$author$project$NethysSearch$boolDictExcluded(model.filteredItemSubcategories)),
							_Utils_Tuple2(
							'pfs',
							$author$project$NethysSearch$boolDictExcluded(model.filteredPfs)),
							_Utils_Tuple2(
							'saving_throw',
							$author$project$NethysSearch$boolDictExcluded(model.filteredSavingThrows)),
							_Utils_Tuple2(
							'school',
							$author$project$NethysSearch$boolDictExcluded(model.filteredSchools)),
							_Utils_Tuple2(
							'size',
							$author$project$NethysSearch$boolDictExcluded(model.filteredSizes)),
							_Utils_Tuple2(
							'source',
							$author$project$NethysSearch$boolDictExcluded(model.filteredSources)),
							_Utils_Tuple2(
							'strongest_save',
							$author$project$NethysSearch$boolDictExcluded(model.filteredStrongestSaves)),
							_Utils_Tuple2(
							'tradition',
							$author$project$NethysSearch$boolDictExcluded(model.filteredTraditions)),
							_Utils_Tuple2(
							'trait',
							$author$project$NethysSearch$boolDictExcluded(model.filteredTraits)),
							_Utils_Tuple2(
							'type',
							$author$project$NethysSearch$boolDictExcluded(model.filteredTypes)),
							_Utils_Tuple2(
							'weakest_save',
							$author$project$NethysSearch$boolDictExcluded(model.filteredWeakestSaves)),
							_Utils_Tuple2(
							'weapon_category',
							$author$project$NethysSearch$boolDictExcluded(model.filteredWeaponCategories)),
							_Utils_Tuple2(
							'weapon_group',
							$author$project$NethysSearch$boolDictExcluded(model.filteredWeaponGroups)),
							_Utils_Tuple2(
							'weapon_type',
							$author$project$NethysSearch$boolDictExcluded(model.filteredWeaponTypes))
						]))),
				A2(
				$elm$core$List$map,
				function (category) {
					return _List_fromArray(
						[
							_Utils_Tuple2(
							'terms',
							$elm$json$Json$Encode$object(
								_List_fromArray(
									[
										_Utils_Tuple2(
										'source',
										A2(
											$elm$json$Json$Encode$list,
											$elm$json$Json$Encode$string,
											A2(
												$elm$core$List$filterMap,
												function (source) {
													return _Utils_eq(
														$elm$core$String$toLower(source.category),
														category) ? $elm$core$Maybe$Just(source.name) : $elm$core$Maybe$Nothing;
												},
												A2(
													$author$project$NethysSearch$getAggregation,
													function ($) {
														return $.sources;
													},
													model))))
									])))
						]);
				},
				$author$project$NethysSearch$boolDictExcluded(model.filteredSourceCategories)),
				model.filterSpoilers ? $elm$core$List$singleton(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'exists',
						$elm$json$Json$Encode$object(
							_List_fromArray(
								[
									_Utils_Tuple2(
									'field',
									$elm$json$Json$Encode$string('spoilers'))
								])))
					])) : _List_Nil
			]));
};
var $elm$core$String$words = _String_words;
var $author$project$NethysSearch$buildStandardQueryBody = function (queryString) {
	return _List_fromArray(
		[
			_List_fromArray(
			[
				_Utils_Tuple2(
				'match_phrase_prefix',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'name',
							$elm$json$Json$Encode$object(
								_List_fromArray(
									[
										_Utils_Tuple2(
										'query',
										$elm$json$Json$Encode$string(queryString))
									])))
						])))
			]),
			_List_fromArray(
			[
				_Utils_Tuple2(
				'bool',
				$elm$json$Json$Encode$object(
					_List_fromArray(
						[
							_Utils_Tuple2(
							'must',
							A2(
								$elm$json$Json$Encode$list,
								$elm$json$Json$Encode$object,
								A2(
									$elm$core$List$map,
									function (word) {
										return _List_fromArray(
											[
												_Utils_Tuple2(
												'multi_match',
												$elm$json$Json$Encode$object(
													_List_fromArray(
														[
															_Utils_Tuple2(
															'query',
															$elm$json$Json$Encode$string(word)),
															_Utils_Tuple2(
															'type',
															$elm$json$Json$Encode$string('best_fields')),
															_Utils_Tuple2(
															'fields',
															A2($elm$json$Json$Encode$list, $elm$json$Json$Encode$string, $author$project$NethysSearch$searchFields)),
															_Utils_Tuple2(
															'fuzziness',
															$elm$json$Json$Encode$string('auto'))
														])))
											]);
									},
									$elm$core$String$words(queryString))))
						])))
			])
		]);
};
var $author$project$NethysSearch$encodeObjectMaybe = function (list) {
	return $elm$json$Json$Encode$object(
		$elm_community$maybe_extra$Maybe$Extra$values(list));
};
var $elm_community$list_extra$List$Extra$find = F2(
	function (predicate, list) {
		find:
		while (true) {
			if (!list.b) {
				return $elm$core$Maybe$Nothing;
			} else {
				var first = list.a;
				var rest = list.b;
				if (predicate(first)) {
					return $elm$core$Maybe$Just(first);
				} else {
					var $temp$predicate = predicate,
						$temp$list = rest;
					predicate = $temp$predicate;
					list = $temp$list;
					continue find;
				}
			}
		}
	});
var $TSFoster$elm_tuple_extra$Tuple3$first = function (_v0) {
	var a = _v0.a;
	return a;
};
var $author$project$Data$damageTypes = _List_fromArray(
	['acid', 'all', 'area', 'bleed', 'bludgeoning', 'chaotic', 'cold', 'cold_iron', 'electricity', 'evil', 'fire', 'force', 'good', 'lawful', 'mental', 'negative', 'orichalcum', 'physical', 'piercing', 'poison', 'positive', 'precision', 'silver', 'slashing', 'sonic', 'splash']);
var $author$project$Data$speedTypes = _List_fromArray(
	['burrow', 'climb', 'fly', 'land', 'swim']);
var $author$project$Data$sortFields = A2(
	$elm$core$List$append,
	A2(
		$elm$core$List$map,
		function (type_) {
			return _Utils_Tuple3('speed.' + type_, 'speed.' + type_, true);
		},
		$author$project$Data$speedTypes),
	A2(
		$elm$core$List$append,
		A2(
			$elm$core$List$map,
			function (type_) {
				return _Utils_Tuple3('weakness.' + type_, 'weakness.' + type_, true);
			},
			$author$project$Data$damageTypes),
		A2(
			$elm$core$List$append,
			A2(
				$elm$core$List$map,
				function (type_) {
					return _Utils_Tuple3('resistance.' + type_, 'resistance.' + type_, true);
				},
				$author$project$Data$damageTypes),
			_List_fromArray(
				[
					_Utils_Tuple3('ability', 'ability', false),
					_Utils_Tuple3('ability_type', 'ability_type', false),
					_Utils_Tuple3('ac', 'ac', true),
					_Utils_Tuple3('actions', 'actions.keyword', false),
					_Utils_Tuple3('alignment', 'alignment', false),
					_Utils_Tuple3('archetype', 'archetype', false),
					_Utils_Tuple3('area', 'area.keyword', false),
					_Utils_Tuple3('armor_category', 'armor_category', false),
					_Utils_Tuple3('armor_group', 'armor_group', false),
					_Utils_Tuple3('aspect', 'aspect', false),
					_Utils_Tuple3('bloodline', 'bloodline', false),
					_Utils_Tuple3('bulk', 'bulk', true),
					_Utils_Tuple3('charisma', 'charisma', true),
					_Utils_Tuple3('check_penalty', 'check_penalty', true),
					_Utils_Tuple3('component', 'component', false),
					_Utils_Tuple3('constitution', 'constitution', true),
					_Utils_Tuple3('cost', 'cost.keyword', false),
					_Utils_Tuple3('creature_family', 'creature_family', false),
					_Utils_Tuple3('deity', 'deity', false),
					_Utils_Tuple3('deity_category', 'deity_category', false),
					_Utils_Tuple3('dex_cap', 'dex_cap', true),
					_Utils_Tuple3('dexterity', 'dexterity', true),
					_Utils_Tuple3('divine_font', 'divine_font', false),
					_Utils_Tuple3('domain', 'domain.keyword', false),
					_Utils_Tuple3('duration', 'duration', true),
					_Utils_Tuple3('favored_weapon', 'favored_weapon', false),
					_Utils_Tuple3('fortitude', 'fortitude', false),
					_Utils_Tuple3('frequency', 'frequency.keyword', false),
					_Utils_Tuple3('hands', 'hands.keyword', false),
					_Utils_Tuple3('hardness', 'hardness', false),
					_Utils_Tuple3('heighten', 'heighten', false),
					_Utils_Tuple3('hp', 'hp', true),
					_Utils_Tuple3('intelligence', 'intelligence', false),
					_Utils_Tuple3('item_category', 'item_category', false),
					_Utils_Tuple3('item_subcategory', 'item_subcategory', false),
					_Utils_Tuple3('level', 'level', true),
					_Utils_Tuple3('mystery', 'mystery', false),
					_Utils_Tuple3('name', 'name.keyword', false),
					_Utils_Tuple3('onset', 'onset', true),
					_Utils_Tuple3('patron_theme', 'patron_theme', false),
					_Utils_Tuple3('perception', 'perception', true),
					_Utils_Tuple3('pfs', 'pfs', false),
					_Utils_Tuple3('plane_category', 'plane_category', false),
					_Utils_Tuple3('prerequisite', 'prerequisite.keyword', false),
					_Utils_Tuple3('price', 'price', true),
					_Utils_Tuple3('primary_check', 'primary_check.keyword', false),
					_Utils_Tuple3('range', 'range', true),
					_Utils_Tuple3('rarity', 'rarity', false),
					_Utils_Tuple3('reflex', 'reflex', true),
					_Utils_Tuple3('region', 'region', false),
					_Utils_Tuple3('requirement', 'requirement.keyword', false),
					_Utils_Tuple3('saving_throw', 'saving_throw.keyword', false),
					_Utils_Tuple3('school', 'school', false),
					_Utils_Tuple3('secondary_casters', 'secondary_casters', false),
					_Utils_Tuple3('secondary_check', 'secondary_check.keyword', false),
					_Utils_Tuple3('size', 'size', false),
					_Utils_Tuple3('source', 'source', false),
					_Utils_Tuple3('speed_penalty', 'speed_penalty.keyword', false),
					_Utils_Tuple3('spoilers', 'spoilers', false),
					_Utils_Tuple3('strength', 'strength', true),
					_Utils_Tuple3('strongest_save', 'strongest_save', false),
					_Utils_Tuple3('target', 'target.keyword', false),
					_Utils_Tuple3('tradition', 'tradition', false),
					_Utils_Tuple3('trigger', 'trigger.keyword', false),
					_Utils_Tuple3('type', 'type', false),
					_Utils_Tuple3('vision', 'vision', false),
					_Utils_Tuple3('weakest_save', 'weakest_save', false),
					_Utils_Tuple3('weapon_category', 'weapon_category', false),
					_Utils_Tuple3('weapon_group', 'weapon_group', false),
					_Utils_Tuple3('weapon_type', 'weapon_type', false),
					_Utils_Tuple3('will', 'will', true),
					_Utils_Tuple3('wisdom', 'wisdom', true)
				]))));
var $author$project$NethysSearch$getValidSortFields = function (values) {
	return A2(
		$elm$core$List$filterMap,
		function (_v0) {
			var field = _v0.a;
			var dir = _v0.b;
			var _v1 = A2(
				$elm_community$list_extra$List$Extra$find,
				A2(
					$elm$core$Basics$composeR,
					$TSFoster$elm_tuple_extra$Tuple3$first,
					$elm$core$Basics$eq(field)),
				$author$project$Data$sortFields);
			if (_v1.$ === 'Just') {
				var _v2 = _v1.a;
				var esField = _v2.b;
				return $elm$core$Maybe$Just(
					_Utils_Tuple2(esField, dir));
			} else {
				return $elm$core$Maybe$Nothing;
			}
		},
		values);
};
var $elm_community$list_extra$List$Extra$last = function (items) {
	last:
	while (true) {
		if (!items.b) {
			return $elm$core$Maybe$Nothing;
		} else {
			if (!items.b.b) {
				var x = items.a;
				return $elm$core$Maybe$Just(x);
			} else {
				var rest = items.b;
				var $temp$items = rest;
				items = $temp$items;
				continue last;
			}
		}
	}
};
var $elm$core$Tuple$pair = F2(
	function (a, b) {
		return _Utils_Tuple2(a, b);
	});
var $author$project$NethysSearch$sortDirToString = function (dir) {
	if (dir.$ === 'Asc') {
		return 'asc';
	} else {
		return 'desc';
	}
};
var $author$project$NethysSearch$buildSearchBody = function (model) {
	return $author$project$NethysSearch$encodeObjectMaybe(
		_List_fromArray(
			[
				$elm$core$Maybe$Just(
				_Utils_Tuple2(
					'query',
					$elm$json$Json$Encode$object(
						_List_fromArray(
							[
								_Utils_Tuple2(
								'bool',
								$author$project$NethysSearch$encodeObjectMaybe(
									_List_fromArray(
										[
											$elm$core$String$isEmpty(model.query) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
											_Utils_Tuple2(
												'should',
												A2(
													$elm$json$Json$Encode$list,
													$elm$json$Json$Encode$object,
													function () {
														var _v0 = model.queryType;
														if (_v0.$ === 'Standard') {
															return $author$project$NethysSearch$buildStandardQueryBody(model.query);
														} else {
															return $author$project$NethysSearch$buildElasticsearchQueryStringQueryBody(model.query);
														}
													}()))),
											$elm$core$List$isEmpty(
											$author$project$NethysSearch$buildSearchFilterTerms(model)) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
											_Utils_Tuple2(
												'filter',
												A2(
													$elm$json$Json$Encode$list,
													$elm$json$Json$Encode$object,
													$author$project$NethysSearch$buildSearchFilterTerms(model)))),
											$elm$core$List$isEmpty(
											$author$project$NethysSearch$buildSearchMustNotTerms(model)) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
											_Utils_Tuple2(
												'must_not',
												A2(
													$elm$json$Json$Encode$list,
													$elm$json$Json$Encode$object,
													$author$project$NethysSearch$buildSearchMustNotTerms(model)))),
											$elm$core$String$isEmpty(model.query) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(
											_Utils_Tuple2(
												'minimum_should_match',
												$elm$json$Json$Encode$int(1)))
										])))
							])))),
				$elm$core$Maybe$Just(
				_Utils_Tuple2(
					'size',
					$elm$json$Json$Encode$int(50))),
				$elm$core$Maybe$Just(
				_Utils_Tuple2(
					'sort',
					A2(
						$elm$json$Json$Encode$list,
						$elm$core$Basics$identity,
						$elm$core$List$isEmpty(
							$author$project$NethysSearch$getValidSortFields(model.sort)) ? _List_fromArray(
							[
								$elm$json$Json$Encode$string('_score'),
								$elm$json$Json$Encode$string('_doc')
							]) : A2(
							$elm$core$List$append,
							A2(
								$elm$core$List$map,
								function (_v1) {
									var field = _v1.a;
									var dir = _v1.b;
									return $elm$json$Json$Encode$object(
										_List_fromArray(
											[
												_Utils_Tuple2(
												field,
												$elm$json$Json$Encode$object(
													_List_fromArray(
														[
															_Utils_Tuple2(
															'order',
															$elm$json$Json$Encode$string(
																$author$project$NethysSearch$sortDirToString(dir)))
														])))
											]));
								},
								$author$project$NethysSearch$getValidSortFields(model.sort)),
							_List_fromArray(
								[
									$elm$json$Json$Encode$string('id')
								]))))),
				$elm$core$Maybe$Just(
				_Utils_Tuple2(
					'_source',
					$elm$json$Json$Encode$object(
						_List_fromArray(
							[
								_Utils_Tuple2(
								'excludes',
								A2(
									$elm$json$Json$Encode$list,
									$elm$json$Json$Encode$string,
									_List_fromArray(
										['text'])))
							])))),
				A2(
				$elm$core$Maybe$map,
				$elm$core$Tuple$pair('search_after'),
				A2(
					$elm$core$Maybe$map,
					function ($) {
						return $.sort;
					},
					A2(
						$elm$core$Maybe$andThen,
						$elm_community$list_extra$List$Extra$last,
						A2(
							$elm$core$Maybe$map,
							function ($) {
								return $.hits;
							},
							A2(
								$elm$core$Maybe$andThen,
								$elm$core$Result$toMaybe,
								$elm_community$list_extra$List$Extra$last(model.searchResults))))))
			]));
};
var $elm$http$Http$cancel = function (tracker) {
	return $elm$http$Http$command(
		$elm$http$Http$Cancel(tracker));
};
var $elm$json$Json$Decode$int = _Json_decodeInt;
var $author$project$NethysSearch$damageTypeValuesDecoder = A3(
	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
	'level',
	$elm$json$Json$Decode$int,
	function (level) {
		return A3(
			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
			'acid',
			$elm$json$Json$Decode$int,
			function (acid) {
				return A3(
					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
					'all',
					$elm$json$Json$Decode$int,
					function (all) {
						return A3(
							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
							'area',
							$elm$json$Json$Decode$int,
							function (area) {
								return A3(
									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
									'bleed',
									$elm$json$Json$Decode$int,
									function (bleed) {
										return A3(
											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
											'bludgeoning',
											$elm$json$Json$Decode$int,
											function (bludgeoning) {
												return A3(
													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
													'chaotic',
													$elm$json$Json$Decode$int,
													function (chaotic) {
														return A3(
															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
															'cold',
															$elm$json$Json$Decode$int,
															function (cold) {
																return A3(
																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																	'cold_iron',
																	$elm$json$Json$Decode$int,
																	function (coldIron) {
																		return A3(
																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																			'electricity',
																			$elm$json$Json$Decode$int,
																			function (electricity) {
																				return A3(
																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																					'evil',
																					$elm$json$Json$Decode$int,
																					function (evil) {
																						return A3(
																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																							'fire',
																							$elm$json$Json$Decode$int,
																							function (fire) {
																								return A3(
																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																									'force',
																									$elm$json$Json$Decode$int,
																									function (force) {
																										return A3(
																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																											'good',
																											$elm$json$Json$Decode$int,
																											function (good) {
																												return A3(
																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																													'lawful',
																													$elm$json$Json$Decode$int,
																													function (lawful) {
																														return A3(
																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																															'mental',
																															$elm$json$Json$Decode$int,
																															function (mental) {
																																return A3(
																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																	'negative',
																																	$elm$json$Json$Decode$int,
																																	function (negative) {
																																		return A3(
																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																			'orichalcum',
																																			$elm$json$Json$Decode$int,
																																			function (orichalcum) {
																																				return A3(
																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																					'physical',
																																					$elm$json$Json$Decode$int,
																																					function (physical) {
																																						return A3(
																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																							'piercing',
																																							$elm$json$Json$Decode$int,
																																							function (piercing) {
																																								return A3(
																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																									'poison',
																																									$elm$json$Json$Decode$int,
																																									function (poison) {
																																										return A3(
																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																											'positive',
																																											$elm$json$Json$Decode$int,
																																											function (positive) {
																																												return A3(
																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																													'precision',
																																													$elm$json$Json$Decode$int,
																																													function (precision) {
																																														return A3(
																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																															'silver',
																																															$elm$json$Json$Decode$int,
																																															function (silver) {
																																																return A3(
																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																	'slashing',
																																																	$elm$json$Json$Decode$int,
																																																	function (slashing) {
																																																		return A3(
																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																			'sonic',
																																																			$elm$json$Json$Decode$int,
																																																			function (sonic) {
																																																				return A3(
																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																					'splash',
																																																					$elm$json$Json$Decode$int,
																																																					function (splash) {
																																																						return $elm$json$Json$Decode$succeed(
																																																							{acid: acid, all: all, area: area, bleed: bleed, bludgeoning: bludgeoning, chaotic: chaotic, cold: cold, coldIron: coldIron, electricity: electricity, evil: evil, fire: fire, force: force, good: good, lawful: lawful, mental: mental, negative: negative, orichalcum: orichalcum, physical: physical, piercing: piercing, poison: poison, positive: positive, precision: precision, silver: silver, slashing: slashing, sonic: sonic, splash: splash});
																																																					});
																																																			});
																																																	});
																																															});
																																													});
																																											});
																																									});
																																							});
																																					});
																																			});
																																	});
																															});
																													});
																											});
																									});
																							});
																					});
																			});
																	});
															});
													});
											});
									});
							});
					});
			});
	});
var $author$project$NethysSearch$speedTypeValuesDecoder = A3(
	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
	'burrow',
	$elm$json$Json$Decode$int,
	function (burrow) {
		return A3(
			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
			'climb',
			$elm$json$Json$Decode$int,
			function (climb) {
				return A3(
					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
					'fly',
					$elm$json$Json$Decode$int,
					function (fly) {
						return A3(
							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
							'land',
							$elm$json$Json$Decode$int,
							function (land) {
								return A3(
									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
									'swim',
									$elm$json$Json$Decode$int,
									function (swim) {
										return $elm$json$Json$Decode$succeed(
											{burrow: burrow, climb: climb, fly: fly, land: land, swim: swim});
									});
							});
					});
			});
	});
var $author$project$NethysSearch$stringListDecoder = $elm$json$Json$Decode$oneOf(
	_List_fromArray(
		[
			$elm$json$Json$Decode$list($elm$json$Json$Decode$string),
			A2($elm$json$Json$Decode$map, $elm$core$List$singleton, $elm$json$Json$Decode$string)
		]));
var $author$project$NethysSearch$documentDecoder = A3(
	$webbhuset$elm_json_decode$Json$Decode$Field$require,
	'category',
	$elm$json$Json$Decode$string,
	function (category) {
		return A3(
			$webbhuset$elm_json_decode$Json$Decode$Field$require,
			'name',
			$elm$json$Json$Decode$string,
			function (name) {
				return A3(
					$webbhuset$elm_json_decode$Json$Decode$Field$require,
					'type',
					$elm$json$Json$Decode$string,
					function (type_) {
						return A3(
							$webbhuset$elm_json_decode$Json$Decode$Field$require,
							'url',
							$elm$json$Json$Decode$string,
							function (url) {
								return A3(
									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
									'ability',
									$author$project$NethysSearch$stringListDecoder,
									function (abilities) {
										return A3(
											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
											'ability_boost',
											$author$project$NethysSearch$stringListDecoder,
											function (abilityBoosts) {
												return A3(
													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
													'ability_flaw',
													$author$project$NethysSearch$stringListDecoder,
													function (abilityFlaws) {
														return A3(
															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
															'ability_type',
															$elm$json$Json$Decode$string,
															function (abilityType) {
																return A3(
																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																	'ac',
																	$elm$json$Json$Decode$int,
																	function (ac) {
																		return A3(
																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																			'actions',
																			$elm$json$Json$Decode$string,
																			function (actions) {
																				return A3(
																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																					'activate',
																					$elm$json$Json$Decode$string,
																					function (activate) {
																						return A3(
																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																							'advanced_domain_spell',
																							$elm$json$Json$Decode$string,
																							function (advancedDomainSpell) {
																								return A3(
																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																									'alignment',
																									$elm$json$Json$Decode$string,
																									function (alignment) {
																										return A3(
																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																											'ammunition',
																											$elm$json$Json$Decode$string,
																											function (ammunition) {
																												return A3(
																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																													'anathema',
																													$elm$json$Json$Decode$string,
																													function (anathema) {
																														return A3(
																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																															'archetype',
																															$elm$json$Json$Decode$string,
																															function (archetype) {
																																return A3(
																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																	'area',
																																	$elm$json$Json$Decode$string,
																																	function (area) {
																																		return A3(
																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																			'area_of_concern',
																																			$elm$json$Json$Decode$string,
																																			function (areaOfConcern) {
																																				return A3(
																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																					'armor_category',
																																					$elm$json$Json$Decode$string,
																																					function (armorCategory) {
																																						return A3(
																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																							'armor_group',
																																							$elm$json$Json$Decode$string,
																																							function (armorGroup) {
																																								return A3(
																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																									'aspect',
																																									$elm$json$Json$Decode$string,
																																									function (aspect) {
																																										return A3(
																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																											'attack_proficiency',
																																											$author$project$NethysSearch$stringListDecoder,
																																											function (attackProficiencies) {
																																												return A3(
																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																													'breadcrumbs',
																																													$elm$json$Json$Decode$string,
																																													function (breadcrumbs) {
																																														return A3(
																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																															'bloodline',
																																															$author$project$NethysSearch$stringListDecoder,
																																															function (bloodlines) {
																																																return A3(
																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																	'bulk_raw',
																																																	$elm$json$Json$Decode$string,
																																																	function (bulk) {
																																																		return A3(
																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																			'charisma',
																																																			$elm$json$Json$Decode$int,
																																																			function (charisma) {
																																																				return A3(
																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																					'check_penalty',
																																																					$elm$json$Json$Decode$int,
																																																					function (checkPenalty) {
																																																						return A3(
																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																							'cleric_spell',
																																																							$elm$json$Json$Decode$string,
																																																							function (clericSpell) {
																																																								return A3(
																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																									'component',
																																																									$elm$json$Json$Decode$list($elm$json$Json$Decode$string),
																																																									function (components) {
																																																										return A3(
																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																											'constitution',
																																																											$elm$json$Json$Decode$int,
																																																											function (constitution) {
																																																												return A3(
																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																													'cost',
																																																													$elm$json$Json$Decode$string,
																																																													function (cost) {
																																																														return A3(
																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																															'creature_family',
																																																															$elm$json$Json$Decode$string,
																																																															function (creatureFamily) {
																																																																return A3(
																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																	'damage',
																																																																	$elm$json$Json$Decode$string,
																																																																	function (damage) {
																																																																		return A3(
																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																			'defense_proficiency',
																																																																			$author$project$NethysSearch$stringListDecoder,
																																																																			function (defenseProficiencies) {
																																																																				return A3(
																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																					'deity',
																																																																					$author$project$NethysSearch$stringListDecoder,
																																																																					function (deities) {
																																																																						return A3(
																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																							'deity_category',
																																																																							$elm$json$Json$Decode$string,
																																																																							function (deityCategory) {
																																																																								return A3(
																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																									'dex_cap',
																																																																									$elm$json$Json$Decode$int,
																																																																									function (dexCap) {
																																																																										return A3(
																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																											'dexterity',
																																																																											$elm$json$Json$Decode$int,
																																																																											function (dexterity) {
																																																																												return A3(
																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																													'divine_font',
																																																																													$author$project$NethysSearch$stringListDecoder,
																																																																													function (divineFonts) {
																																																																														return A3(
																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																															'domain',
																																																																															$author$project$NethysSearch$stringListDecoder,
																																																																															function (domains) {
																																																																																return A3(
																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																	'domain_spell',
																																																																																	$elm$json$Json$Decode$string,
																																																																																	function (domainSpell) {
																																																																																		return A3(
																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																			'duration_raw',
																																																																																			$elm$json$Json$Decode$string,
																																																																																			function (duration) {
																																																																																				return A3(
																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																					'edict',
																																																																																					$elm$json$Json$Decode$string,
																																																																																					function (edict) {
																																																																																						return A3(
																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																							'familiar_ability',
																																																																																							$author$project$NethysSearch$stringListDecoder,
																																																																																							function (familiarAbilities) {
																																																																																								return A3(
																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																									'favored_weapon',
																																																																																									$author$project$NethysSearch$stringListDecoder,
																																																																																									function (favoredWeapons) {
																																																																																										return A3(
																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																											'feat',
																																																																																											$author$project$NethysSearch$stringListDecoder,
																																																																																											function (feats) {
																																																																																												return A3(
																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																													'fortitude_save',
																																																																																													$elm$json$Json$Decode$int,
																																																																																													function (fort) {
																																																																																														return A3(
																																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																															'follower_alignment',
																																																																																															$author$project$NethysSearch$stringListDecoder,
																																																																																															function (followerAlignments) {
																																																																																																return A3(
																																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																	'frequency',
																																																																																																	$elm$json$Json$Decode$string,
																																																																																																	function (frequency) {
																																																																																																		return A3(
																																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																			'hands',
																																																																																																			$elm$json$Json$Decode$string,
																																																																																																			function (hands) {
																																																																																																				return A3(
																																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																					'hardness_raw',
																																																																																																					$elm$json$Json$Decode$string,
																																																																																																					function (hardness) {
																																																																																																						return A3(
																																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																							'heighten',
																																																																																																							$elm$json$Json$Decode$list($elm$json$Json$Decode$string),
																																																																																																							function (heighten) {
																																																																																																								return A3(
																																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																									'hp_raw',
																																																																																																									$elm$json$Json$Decode$string,
																																																																																																									function (hp) {
																																																																																																										return A3(
																																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																											'immunity',
																																																																																																											$elm$json$Json$Decode$list($elm$json$Json$Decode$string),
																																																																																																											function (immunities) {
																																																																																																												return A3(
																																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																													'intelligence',
																																																																																																													$elm$json$Json$Decode$int,
																																																																																																													function (intelligence) {
																																																																																																														return A3(
																																																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																															'item_category',
																																																																																																															$elm$json$Json$Decode$string,
																																																																																																															function (itemCategory) {
																																																																																																																return A3(
																																																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																	'item_subcategory',
																																																																																																																	$elm$json$Json$Decode$string,
																																																																																																																	function (itemSubcategory) {
																																																																																																																		return A3(
																																																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																			'language',
																																																																																																																			$author$project$NethysSearch$stringListDecoder,
																																																																																																																			function (languages) {
																																																																																																																				return A3(
																																																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																					'lesson_type',
																																																																																																																					$elm$json$Json$Decode$string,
																																																																																																																					function (lessonType) {
																																																																																																																						return A3(
																																																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																							'level',
																																																																																																																							$elm$json$Json$Decode$int,
																																																																																																																							function (level) {
																																																																																																																								return A3(
																																																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																									'mystery',
																																																																																																																									$author$project$NethysSearch$stringListDecoder,
																																																																																																																									function (mysteries) {
																																																																																																																										return A3(
																																																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																											'onset_raw',
																																																																																																																											$elm$json$Json$Decode$string,
																																																																																																																											function (onset) {
																																																																																																																												return A3(
																																																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																													'patron_theme',
																																																																																																																													$author$project$NethysSearch$stringListDecoder,
																																																																																																																													function (patronThemes) {
																																																																																																																														return A3(
																																																																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																															'perception',
																																																																																																																															$elm$json$Json$Decode$int,
																																																																																																																															function (perception) {
																																																																																																																																return A3(
																																																																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																	'perception_proficiency',
																																																																																																																																	$elm$json$Json$Decode$string,
																																																																																																																																	function (perceptionProficiency) {
																																																																																																																																		return A3(
																																																																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																			'pfs',
																																																																																																																																			$elm$json$Json$Decode$string,
																																																																																																																																			function (pfs) {
																																																																																																																																				return A3(
																																																																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																					'plane_category',
																																																																																																																																					$elm$json$Json$Decode$string,
																																																																																																																																					function (planeCategory) {
																																																																																																																																						return A3(
																																																																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																							'prerequisite',
																																																																																																																																							$elm$json$Json$Decode$string,
																																																																																																																																							function (prerequisites) {
																																																																																																																																								return A3(
																																																																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																									'price_raw',
																																																																																																																																									$elm$json$Json$Decode$string,
																																																																																																																																									function (price) {
																																																																																																																																										return A3(
																																																																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																											'primary_check',
																																																																																																																																											$elm$json$Json$Decode$string,
																																																																																																																																											function (primaryCheck) {
																																																																																																																																												return A3(
																																																																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																													'range_raw',
																																																																																																																																													$elm$json$Json$Decode$string,
																																																																																																																																													function (range) {
																																																																																																																																														return A3(
																																																																																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																															'rarity',
																																																																																																																																															$elm$json$Json$Decode$string,
																																																																																																																																															function (rarity) {
																																																																																																																																																return A3(
																																																																																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																	'reflex_save',
																																																																																																																																																	$elm$json$Json$Decode$int,
																																																																																																																																																	function (ref) {
																																																																																																																																																		return A3(
																																																																																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																			'region',
																																																																																																																																																			$elm$json$Json$Decode$string,
																																																																																																																																																			function (region) {
																																																																																																																																																				return A3(
																																																																																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																					'reload_raw',
																																																																																																																																																					$elm$json$Json$Decode$string,
																																																																																																																																																					function (reload) {
																																																																																																																																																						return A3(
																																																																																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																							'required_abilities',
																																																																																																																																																							$elm$json$Json$Decode$string,
																																																																																																																																																							function (requiredAbilities) {
																																																																																																																																																								return A3(
																																																																																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																									'requirement',
																																																																																																																																																									$elm$json$Json$Decode$string,
																																																																																																																																																									function (requirements) {
																																																																																																																																																										return A3(
																																																																																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																											'resistance',
																																																																																																																																																											$author$project$NethysSearch$damageTypeValuesDecoder,
																																																																																																																																																											function (resistanceValues) {
																																																																																																																																																												return A3(
																																																																																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																													'resistance_raw',
																																																																																																																																																													$elm$json$Json$Decode$list($elm$json$Json$Decode$string),
																																																																																																																																																													function (resistances) {
																																																																																																																																																														return A3(
																																																																																																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																															'saving_throw',
																																																																																																																																																															$elm$json$Json$Decode$string,
																																																																																																																																																															function (savingThrow) {
																																																																																																																																																																return A3(
																																																																																																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																	'saving_throw_proficiency',
																																																																																																																																																																	$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																	function (savingThrowProficiencies) {
																																																																																																																																																																		return A3(
																																																																																																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																			'school',
																																																																																																																																																																			$elm$json$Json$Decode$string,
																																																																																																																																																																			function (school) {
																																																																																																																																																																				return A3(
																																																																																																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																					'secondary_casters_raw',
																																																																																																																																																																					$elm$json$Json$Decode$string,
																																																																																																																																																																					function (secondaryCasters) {
																																																																																																																																																																						return A3(
																																																																																																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																							'secondary_check',
																																																																																																																																																																							$elm$json$Json$Decode$string,
																																																																																																																																																																							function (secondaryChecks) {
																																																																																																																																																																								return A3(
																																																																																																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																									'sense',
																																																																																																																																																																									$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																									function (senses) {
																																																																																																																																																																										return A3(
																																																																																																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																											'size',
																																																																																																																																																																											$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																											function (sizes) {
																																																																																																																																																																												return A3(
																																																																																																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																													'skill',
																																																																																																																																																																													$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																													function (skills) {
																																																																																																																																																																														return A3(
																																																																																																																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																															'skill_proficiency',
																																																																																																																																																																															$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																															function (skillProficiencies) {
																																																																																																																																																																																return A3(
																																																																																																																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																	'source',
																																																																																																																																																																																	$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																																	function (sources) {
																																																																																																																																																																																		return A3(
																																																																																																																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																			'speed',
																																																																																																																																																																																			$author$project$NethysSearch$speedTypeValuesDecoder,
																																																																																																																																																																																			function (speedValues) {
																																																																																																																																																																																				return A3(
																																																																																																																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																					'speed_raw',
																																																																																																																																																																																					$elm$json$Json$Decode$string,
																																																																																																																																																																																					function (speed) {
																																																																																																																																																																																						return A3(
																																																																																																																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																							'speed_penalty',
																																																																																																																																																																																							$elm$json$Json$Decode$string,
																																																																																																																																																																																							function (speedPenalty) {
																																																																																																																																																																																								return A3(
																																																																																																																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																									'spell_list',
																																																																																																																																																																																									$elm$json$Json$Decode$string,
																																																																																																																																																																																									function (spellList) {
																																																																																																																																																																																										return A3(
																																																																																																																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																											'spoilers',
																																																																																																																																																																																											$elm$json$Json$Decode$string,
																																																																																																																																																																																											function (spoilers) {
																																																																																																																																																																																												return A3(
																																																																																																																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																													'stage',
																																																																																																																																																																																													$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																																													function (stages) {
																																																																																																																																																																																														return A3(
																																																																																																																																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																															'strength',
																																																																																																																																																																																															$elm$json$Json$Decode$int,
																																																																																																																																																																																															function (strength) {
																																																																																																																																																																																																return A3(
																																																																																																																																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																	'strongest_save',
																																																																																																																																																																																																	$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																																																	function (strongestSaves) {
																																																																																																																																																																																																		return A3(
																																																																																																																																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																			'target',
																																																																																																																																																																																																			$elm$json$Json$Decode$string,
																																																																																																																																																																																																			function (targets) {
																																																																																																																																																																																																				return A3(
																																																																																																																																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																					'tradition',
																																																																																																																																																																																																					$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																																																					function (traditions) {
																																																																																																																																																																																																						return A3(
																																																																																																																																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																							'trait_raw',
																																																																																																																																																																																																							$elm$json$Json$Decode$list($elm$json$Json$Decode$string),
																																																																																																																																																																																																							function (maybeTraits) {
																																																																																																																																																																																																								return A3(
																																																																																																																																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																									'trigger',
																																																																																																																																																																																																									$elm$json$Json$Decode$string,
																																																																																																																																																																																																									function (trigger) {
																																																																																																																																																																																																										return A3(
																																																																																																																																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																											'usage',
																																																																																																																																																																																																											$elm$json$Json$Decode$string,
																																																																																																																																																																																																											function (usage) {
																																																																																																																																																																																																												return A3(
																																																																																																																																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																													'vision',
																																																																																																																																																																																																													$elm$json$Json$Decode$string,
																																																																																																																																																																																																													function (vision) {
																																																																																																																																																																																																														return A3(
																																																																																																																																																																																																															$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																															'weakest_save',
																																																																																																																																																																																																															$author$project$NethysSearch$stringListDecoder,
																																																																																																																																																																																																															function (weakestSaves) {
																																																																																																																																																																																																																return A3(
																																																																																																																																																																																																																	$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																																	'weakness',
																																																																																																																																																																																																																	$author$project$NethysSearch$damageTypeValuesDecoder,
																																																																																																																																																																																																																	function (weaknessValues) {
																																																																																																																																																																																																																		return A3(
																																																																																																																																																																																																																			$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																																			'weakness_raw',
																																																																																																																																																																																																																			$elm$json$Json$Decode$list($elm$json$Json$Decode$string),
																																																																																																																																																																																																																			function (weaknesses) {
																																																																																																																																																																																																																				return A3(
																																																																																																																																																																																																																					$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																																					'weapon_category',
																																																																																																																																																																																																																					$elm$json$Json$Decode$string,
																																																																																																																																																																																																																					function (weaponCategory) {
																																																																																																																																																																																																																						return A3(
																																																																																																																																																																																																																							$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																																							'weapon_group',
																																																																																																																																																																																																																							$elm$json$Json$Decode$string,
																																																																																																																																																																																																																							function (weaponGroup) {
																																																																																																																																																																																																																								return A3(
																																																																																																																																																																																																																									$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																																									'weapon_type',
																																																																																																																																																																																																																									$elm$json$Json$Decode$string,
																																																																																																																																																																																																																									function (weaponType) {
																																																																																																																																																																																																																										return A3(
																																																																																																																																																																																																																											$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																																											'will_save',
																																																																																																																																																																																																																											$elm$json$Json$Decode$int,
																																																																																																																																																																																																																											function (will) {
																																																																																																																																																																																																																												return A3(
																																																																																																																																																																																																																													$webbhuset$elm_json_decode$Json$Decode$Field$attempt,
																																																																																																																																																																																																																													'wisdom',
																																																																																																																																																																																																																													$elm$json$Json$Decode$int,
																																																																																																																																																																																																																													function (wisdom) {
																																																																																																																																																																																																																														return $elm$json$Json$Decode$succeed(
																																																																																																																																																																																																																															{
																																																																																																																																																																																																																																abilities: A2($elm$core$Maybe$withDefault, _List_Nil, abilities),
																																																																																																																																																																																																																																abilityBoosts: A2($elm$core$Maybe$withDefault, _List_Nil, abilityBoosts),
																																																																																																																																																																																																																																abilityFlaws: A2($elm$core$Maybe$withDefault, _List_Nil, abilityFlaws),
																																																																																																																																																																																																																																abilityType: abilityType,
																																																																																																																																																																																																																																ac: ac,
																																																																																																																																																																																																																																actions: actions,
																																																																																																																																																																																																																																activate: activate,
																																																																																																																																																																																																																																advancedDomainSpell: advancedDomainSpell,
																																																																																																																																																																																																																																alignment: alignment,
																																																																																																																																																																																																																																ammunition: ammunition,
																																																																																																																																																																																																																																anathema: anathema,
																																																																																																																																																																																																																																archetype: archetype,
																																																																																																																																																																																																																																area: area,
																																																																																																																																																																																																																																areasOfConcern: areaOfConcern,
																																																																																																																																																																																																																																armorCategory: armorCategory,
																																																																																																																																																																																																																																armorGroup: armorGroup,
																																																																																																																																																																																																																																aspect: aspect,
																																																																																																																																																																																																																																attackProficiencies: A2($elm$core$Maybe$withDefault, _List_Nil, attackProficiencies),
																																																																																																																																																																																																																																bloodlines: A2($elm$core$Maybe$withDefault, _List_Nil, bloodlines),
																																																																																																																																																																																																																																breadcrumbs: breadcrumbs,
																																																																																																																																																																																																																																bulk: bulk,
																																																																																																																																																																																																																																category: category,
																																																																																																																																																																																																																																charisma: charisma,
																																																																																																																																																																																																																																checkPenalty: checkPenalty,
																																																																																																																																																																																																																																clericSpells: clericSpell,
																																																																																																																																																																																																																																components: A2($elm$core$Maybe$withDefault, _List_Nil, components),
																																																																																																																																																																																																																																constitution: constitution,
																																																																																																																																																																																																																																cost: cost,
																																																																																																																																																																																																																																creatureFamily: creatureFamily,
																																																																																																																																																																																																																																damage: damage,
																																																																																																																																																																																																																																defenseProficiencies: A2($elm$core$Maybe$withDefault, _List_Nil, defenseProficiencies),
																																																																																																																																																																																																																																deities: A2($elm$core$Maybe$withDefault, _List_Nil, deities),
																																																																																																																																																																																																																																deityCategory: deityCategory,
																																																																																																																																																																																																																																dexCap: dexCap,
																																																																																																																																																																																																																																dexterity: dexterity,
																																																																																																																																																																																																																																divineFonts: A2($elm$core$Maybe$withDefault, _List_Nil, divineFonts),
																																																																																																																																																																																																																																domainSpell: domainSpell,
																																																																																																																																																																																																																																domains: A2($elm$core$Maybe$withDefault, _List_Nil, domains),
																																																																																																																																																																																																																																duration: duration,
																																																																																																																																																																																																																																edict: edict,
																																																																																																																																																																																																																																familiarAbilities: A2($elm$core$Maybe$withDefault, _List_Nil, familiarAbilities),
																																																																																																																																																																																																																																favoredWeapons: A2($elm$core$Maybe$withDefault, _List_Nil, favoredWeapons),
																																																																																																																																																																																																																																feats: A2($elm$core$Maybe$withDefault, _List_Nil, feats),
																																																																																																																																																																																																																																followerAlignments: A2($elm$core$Maybe$withDefault, _List_Nil, followerAlignments),
																																																																																																																																																																																																																																fort: fort,
																																																																																																																																																																																																																																frequency: frequency,
																																																																																																																																																																																																																																hands: hands,
																																																																																																																																																																																																																																hardness: hardness,
																																																																																																																																																																																																																																heighten: A2($elm$core$Maybe$withDefault, _List_Nil, heighten),
																																																																																																																																																																																																																																hp: hp,
																																																																																																																																																																																																																																immunities: A2($elm$core$Maybe$withDefault, _List_Nil, immunities),
																																																																																																																																																																																																																																intelligence: intelligence,
																																																																																																																																																																																																																																itemCategory: itemCategory,
																																																																																																																																																																																																																																itemSubcategory: itemSubcategory,
																																																																																																																																																																																																																																languages: A2($elm$core$Maybe$withDefault, _List_Nil, languages),
																																																																																																																																																																																																																																lessonType: lessonType,
																																																																																																																																																																																																																																level: level,
																																																																																																																																																																																																																																mysteries: A2($elm$core$Maybe$withDefault, _List_Nil, mysteries),
																																																																																																																																																																																																																																name: name,
																																																																																																																																																																																																																																onset: onset,
																																																																																																																																																																																																																																patronThemes: A2($elm$core$Maybe$withDefault, _List_Nil, patronThemes),
																																																																																																																																																																																																																																perception: perception,
																																																																																																																																																																																																																																perceptionProficiency: perceptionProficiency,
																																																																																																																																																																																																																																pfs: pfs,
																																																																																																																																																																																																																																planeCategory: planeCategory,
																																																																																																																																																																																																																																prerequisites: prerequisites,
																																																																																																																																																																																																																																price: price,
																																																																																																																																																																																																																																primaryCheck: primaryCheck,
																																																																																																																																																																																																																																range: range,
																																																																																																																																																																																																																																rarity: rarity,
																																																																																																																																																																																																																																ref: ref,
																																																																																																																																																																																																																																region: region,
																																																																																																																																																																																																																																reload: reload,
																																																																																																																																																																																																																																requiredAbilities: requiredAbilities,
																																																																																																																																																																																																																																requirements: requirements,
																																																																																																																																																																																																																																resistanceValues: resistanceValues,
																																																																																																																																																																																																																																resistances: A2($elm$core$Maybe$withDefault, _List_Nil, resistances),
																																																																																																																																																																																																																																savingThrow: savingThrow,
																																																																																																																																																																																																																																savingThrowProficiencies: A2($elm$core$Maybe$withDefault, _List_Nil, savingThrowProficiencies),
																																																																																																																																																																																																																																school: school,
																																																																																																																																																																																																																																secondaryCasters: secondaryCasters,
																																																																																																																																																																																																																																secondaryChecks: secondaryChecks,
																																																																																																																																																																																																																																senses: A2($elm$core$Maybe$withDefault, _List_Nil, senses),
																																																																																																																																																																																																																																sizes: A2($elm$core$Maybe$withDefault, _List_Nil, sizes),
																																																																																																																																																																																																																																skillProficiencies: A2($elm$core$Maybe$withDefault, _List_Nil, skillProficiencies),
																																																																																																																																																																																																																																skills: A2($elm$core$Maybe$withDefault, _List_Nil, skills),
																																																																																																																																																																																																																																sources: A2($elm$core$Maybe$withDefault, _List_Nil, sources),
																																																																																																																																																																																																																																speed: speed,
																																																																																																																																																																																																																																speedPenalty: speedPenalty,
																																																																																																																																																																																																																																speedValues: speedValues,
																																																																																																																																																																																																																																spellList: spellList,
																																																																																																																																																																																																																																spoilers: spoilers,
																																																																																																																																																																																																																																stages: A2($elm$core$Maybe$withDefault, _List_Nil, stages),
																																																																																																																																																																																																																																strength: strength,
																																																																																																																																																																																																																																strongestSaves: A2($elm$core$Maybe$withDefault, _List_Nil, strongestSaves),
																																																																																																																																																																																																																																targets: targets,
																																																																																																																																																																																																																																traditions: A2($elm$core$Maybe$withDefault, _List_Nil, traditions),
																																																																																																																																																																																																																																traits: A2($elm$core$Maybe$withDefault, _List_Nil, maybeTraits),
																																																																																																																																																																																																																																trigger: trigger,
																																																																																																																																																																																																																																type_: type_,
																																																																																																																																																																																																																																url: url,
																																																																																																																																																																																																																																usage: usage,
																																																																																																																																																																																																																																vision: vision,
																																																																																																																																																																																																																																weakestSaves: A2($elm$core$Maybe$withDefault, _List_Nil, weakestSaves),
																																																																																																																																																																																																																																weaknessValues: weaknessValues,
																																																																																																																																																																																																																																weaknesses: A2($elm$core$Maybe$withDefault, _List_Nil, weaknesses),
																																																																																																																																																																																																																																weaponCategory: weaponCategory,
																																																																																																																																																																																																																																weaponGroup: weaponGroup,
																																																																																																																																																																																																																																weaponType: weaponType,
																																																																																																																																																																																																																																will: will,
																																																																																																																																																																																																																																wisdom: wisdom
																																																																																																																																																																																																																															});
																																																																																																																																																																																																																													});
																																																																																																																																																																																																																											});
																																																																																																																																																																																																																									});
																																																																																																																																																																																																																							});
																																																																																																																																																																																																																					});
																																																																																																																																																																																																																			});
																																																																																																																																																																																																																	});
																																																																																																																																																																																																															});
																																																																																																																																																																																																													});
																																																																																																																																																																																																											});
																																																																																																																																																																																																									});
																																																																																																																																																																																																							});
																																																																																																																																																																																																					});
																																																																																																																																																																																																			});
																																																																																																																																																																																																	});
																																																																																																																																																																																															});
																																																																																																																																																																																													});
																																																																																																																																																																																											});
																																																																																																																																																																																									});
																																																																																																																																																																																							});
																																																																																																																																																																																					});
																																																																																																																																																																																			});
																																																																																																																																																																																	});
																																																																																																																																																																															});
																																																																																																																																																																													});
																																																																																																																																																																											});
																																																																																																																																																																									});
																																																																																																																																																																							});
																																																																																																																																																																					});
																																																																																																																																																																			});
																																																																																																																																																																	});
																																																																																																																																																															});
																																																																																																																																																													});
																																																																																																																																																											});
																																																																																																																																																									});
																																																																																																																																																							});
																																																																																																																																																					});
																																																																																																																																																			});
																																																																																																																																																	});
																																																																																																																																															});
																																																																																																																																													});
																																																																																																																																											});
																																																																																																																																									});
																																																																																																																																							});
																																																																																																																																					});
																																																																																																																																			});
																																																																																																																																	});
																																																																																																																															});
																																																																																																																													});
																																																																																																																											});
																																																																																																																									});
																																																																																																																							});
																																																																																																																					});
																																																																																																																			});
																																																																																																																	});
																																																																																																															});
																																																																																																													});
																																																																																																											});
																																																																																																									});
																																																																																																							});
																																																																																																					});
																																																																																																			});
																																																																																																	});
																																																																																															});
																																																																																													});
																																																																																											});
																																																																																									});
																																																																																							});
																																																																																					});
																																																																																			});
																																																																																	});
																																																																															});
																																																																													});
																																																																											});
																																																																									});
																																																																							});
																																																																					});
																																																																			});
																																																																	});
																																																															});
																																																													});
																																																											});
																																																									});
																																																							});
																																																					});
																																																			});
																																																	});
																																															});
																																													});
																																											});
																																									});
																																							});
																																					});
																																			});
																																	});
																															});
																													});
																											});
																									});
																							});
																					});
																			});
																	});
															});
													});
											});
									});
							});
					});
			});
	});
var $elm$json$Json$Decode$float = _Json_decodeFloat;
var $elm$json$Json$Decode$value = _Json_decodeValue;
var $author$project$NethysSearch$hitDecoder = function (decoder) {
	return A3(
		$webbhuset$elm_json_decode$Json$Decode$Field$require,
		'_id',
		$elm$json$Json$Decode$string,
		function (id) {
			return A3(
				$webbhuset$elm_json_decode$Json$Decode$Field$require,
				'_score',
				$elm$json$Json$Decode$maybe($elm$json$Json$Decode$float),
				function (score) {
					return A3(
						$webbhuset$elm_json_decode$Json$Decode$Field$require,
						'_source',
						decoder,
						function (source) {
							return A3(
								$webbhuset$elm_json_decode$Json$Decode$Field$require,
								'sort',
								$elm$json$Json$Decode$value,
								function (sort) {
									return $elm$json$Json$Decode$succeed(
										{
											id: id,
											score: A2($elm$core$Maybe$withDefault, 0, score),
											sort: sort,
											source: source
										});
								});
						});
				});
		});
};
var $author$project$NethysSearch$esResultDecoder = A3(
	$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
	_List_fromArray(
		['hits', 'hits']),
	$elm$json$Json$Decode$list(
		$author$project$NethysSearch$hitDecoder($author$project$NethysSearch$documentDecoder)),
	function (hits) {
		return A3(
			$webbhuset$elm_json_decode$Json$Decode$Field$requireAt,
			_List_fromArray(
				['hits', 'total', 'value']),
			$elm$json$Json$Decode$int,
			function (total) {
				return $elm$json$Json$Decode$succeed(
					{hits: hits, total: total});
			});
	});
var $elm$url$Url$percentDecode = _Url_percentDecode;
var $elm$core$String$trim = _String_trim;
var $author$project$NethysSearch$getSearchKey = F2(
	function (includeSort, url) {
		return A2(
			$elm$core$String$join,
			'&',
			A2(
				$elm$core$List$filter,
				function (s) {
					var _v0 = A2($elm$core$String$split, '=', s);
					_v0$5:
					while (true) {
						if ((_v0.b && _v0.b.b) && (!_v0.b.b.b)) {
							switch (_v0.a) {
								case 'columns':
									var _v1 = _v0.b;
									return false;
								case 'display':
									var _v2 = _v0.b;
									return false;
								case 'sort':
									var _v3 = _v0.b;
									return includeSort;
								case 'q':
									var _v4 = _v0.b;
									var q = _v4.a;
									return !$elm$core$String$isEmpty(
										$elm$core$String$trim(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												$elm$url$Url$percentDecode(q))));
								case 'type':
									var _v5 = _v0.b;
									return includeSort;
								default:
									break _v0$5;
							}
						} else {
							break _v0$5;
						}
					}
					return true;
				},
				A2(
					$elm$core$String$split,
					'&',
					A2($elm$core$Maybe$withDefault, '', url.query))));
	});
var $elm$core$Dict$isEmpty = function (dict) {
	if (dict.$ === 'RBEmpty_elm_builtin') {
		return true;
	} else {
		return false;
	}
};
var $elm_community$maybe_extra$Maybe$Extra$isNothing = function (m) {
	if (m.$ === 'Nothing') {
		return true;
	} else {
		return false;
	}
};
var $elm$core$Platform$Cmd$none = $elm$core$Platform$Cmd$batch(_List_Nil);
var $author$project$NethysSearch$searchWithCurrentQuery = F2(
	function (loadMore, _v0) {
		var model = _v0.a;
		var cmd = _v0.b;
		if ($elm$core$String$isEmpty(
			A2($author$project$NethysSearch$getSearchKey, false, model.url)) || ((!$elm$core$Dict$isEmpty(model.filteredSourceCategories)) && $elm_community$maybe_extra$Maybe$Extra$isNothing(model.aggregations))) {
			return _Utils_Tuple2(
				_Utils_update(
					model,
					{lastSearchKey: '', searchResults: _List_Nil}),
				$elm$core$Platform$Cmd$batch(
					_List_fromArray(
						[
							cmd,
							function () {
							var _v1 = model.tracker;
							if (_v1.$ === 'Just') {
								var tracker = _v1.a;
								return $elm$http$Http$cancel(
									'search-' + $elm$core$String$fromInt(tracker));
							} else {
								return $elm$core$Platform$Cmd$none;
							}
						}()
						])));
		} else {
			if ((!_Utils_eq(
				A2($author$project$NethysSearch$getSearchKey, true, model.url),
				model.lastSearchKey)) || loadMore) {
				var newTracker = function () {
					var _v3 = model.tracker;
					if (_v3.$ === 'Just') {
						var tracker = _v3.a;
						return tracker + 1;
					} else {
						return 1;
					}
				}();
				var newModel = _Utils_update(
					model,
					{
						lastSearchKey: A2($author$project$NethysSearch$getSearchKey, true, model.url),
						searchResults: loadMore ? model.searchResults : _List_Nil,
						tracker: $elm$core$Maybe$Just(newTracker)
					});
				return _Utils_Tuple2(
					newModel,
					$elm$core$Platform$Cmd$batch(
						_List_fromArray(
							[
								cmd,
								function () {
								var _v2 = model.tracker;
								if (_v2.$ === 'Just') {
									var tracker = _v2.a;
									return $elm$http$Http$cancel(
										'search-' + $elm$core$String$fromInt(tracker));
								} else {
									return $elm$core$Platform$Cmd$none;
								}
							}(),
								$elm$http$Http$request(
								{
									body: $elm$http$Http$jsonBody(
										$author$project$NethysSearch$buildSearchBody(newModel)),
									expect: A2($elm$http$Http$expectJson, $author$project$NethysSearch$GotSearchResult, $author$project$NethysSearch$esResultDecoder),
									headers: _List_Nil,
									method: 'POST',
									timeout: $elm$core$Maybe$Just(10000),
									tracker: $elm$core$Maybe$Just(
										'search-' + $elm$core$String$fromInt(newTracker)),
									url: model.elasticUrl + '/_search'
								})
							])));
			} else {
				return _Utils_Tuple2(model, cmd);
			}
		}
	});
var $author$project$NethysSearch$ElasticsearchQueryString = {$: 'ElasticsearchQueryString'};
var $author$project$NethysSearch$Table = {$: 'Table'};
var $elm$core$Dict$fromList = function (assocs) {
	return A3(
		$elm$core$List$foldl,
		F2(
			function (_v0, dict) {
				var key = _v0.a;
				var value = _v0.b;
				return A3($elm$core$Dict$insert, key, value, dict);
			}),
		$elm$core$Dict$empty,
		assocs);
};
var $elm_community$maybe_extra$Maybe$Extra$join = function (mx) {
	if (mx.$ === 'Just') {
		var x = mx.a;
		return x;
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $elm$url$Url$Parser$State = F5(
	function (visited, unvisited, params, frag, value) {
		return {frag: frag, params: params, unvisited: unvisited, value: value, visited: visited};
	});
var $elm$url$Url$Parser$getFirstMatch = function (states) {
	getFirstMatch:
	while (true) {
		if (!states.b) {
			return $elm$core$Maybe$Nothing;
		} else {
			var state = states.a;
			var rest = states.b;
			var _v1 = state.unvisited;
			if (!_v1.b) {
				return $elm$core$Maybe$Just(state.value);
			} else {
				if ((_v1.a === '') && (!_v1.b.b)) {
					return $elm$core$Maybe$Just(state.value);
				} else {
					var $temp$states = rest;
					states = $temp$states;
					continue getFirstMatch;
				}
			}
		}
	}
};
var $elm$url$Url$Parser$removeFinalEmpty = function (segments) {
	if (!segments.b) {
		return _List_Nil;
	} else {
		if ((segments.a === '') && (!segments.b.b)) {
			return _List_Nil;
		} else {
			var segment = segments.a;
			var rest = segments.b;
			return A2(
				$elm$core$List$cons,
				segment,
				$elm$url$Url$Parser$removeFinalEmpty(rest));
		}
	}
};
var $elm$url$Url$Parser$preparePath = function (path) {
	var _v0 = A2($elm$core$String$split, '/', path);
	if (_v0.b && (_v0.a === '')) {
		var segments = _v0.b;
		return $elm$url$Url$Parser$removeFinalEmpty(segments);
	} else {
		var segments = _v0;
		return $elm$url$Url$Parser$removeFinalEmpty(segments);
	}
};
var $elm$url$Url$Parser$addToParametersHelp = F2(
	function (value, maybeList) {
		if (maybeList.$ === 'Nothing') {
			return $elm$core$Maybe$Just(
				_List_fromArray(
					[value]));
		} else {
			var list = maybeList.a;
			return $elm$core$Maybe$Just(
				A2($elm$core$List$cons, value, list));
		}
	});
var $elm$url$Url$Parser$addParam = F2(
	function (segment, dict) {
		var _v0 = A2($elm$core$String$split, '=', segment);
		if ((_v0.b && _v0.b.b) && (!_v0.b.b.b)) {
			var rawKey = _v0.a;
			var _v1 = _v0.b;
			var rawValue = _v1.a;
			var _v2 = $elm$url$Url$percentDecode(rawKey);
			if (_v2.$ === 'Nothing') {
				return dict;
			} else {
				var key = _v2.a;
				var _v3 = $elm$url$Url$percentDecode(rawValue);
				if (_v3.$ === 'Nothing') {
					return dict;
				} else {
					var value = _v3.a;
					return A3(
						$elm$core$Dict$update,
						key,
						$elm$url$Url$Parser$addToParametersHelp(value),
						dict);
				}
			}
		} else {
			return dict;
		}
	});
var $elm$url$Url$Parser$prepareQuery = function (maybeQuery) {
	if (maybeQuery.$ === 'Nothing') {
		return $elm$core$Dict$empty;
	} else {
		var qry = maybeQuery.a;
		return A3(
			$elm$core$List$foldr,
			$elm$url$Url$Parser$addParam,
			$elm$core$Dict$empty,
			A2($elm$core$String$split, '&', qry));
	}
};
var $elm$url$Url$Parser$parse = F2(
	function (_v0, url) {
		var parser = _v0.a;
		return $elm$url$Url$Parser$getFirstMatch(
			parser(
				A5(
					$elm$url$Url$Parser$State,
					_List_Nil,
					$elm$url$Url$Parser$preparePath(url.path),
					$elm$url$Url$Parser$prepareQuery(url.query),
					url.fragment,
					$elm$core$Basics$identity)));
	});
var $elm$url$Url$Parser$Parser = function (a) {
	return {$: 'Parser', a: a};
};
var $elm$url$Url$Parser$query = function (_v0) {
	var queryParser = _v0.a;
	return $elm$url$Url$Parser$Parser(
		function (_v1) {
			var visited = _v1.visited;
			var unvisited = _v1.unvisited;
			var params = _v1.params;
			var frag = _v1.frag;
			var value = _v1.value;
			return _List_fromArray(
				[
					A5(
					$elm$url$Url$Parser$State,
					visited,
					unvisited,
					params,
					frag,
					value(
						queryParser(params)))
				]);
		});
};
var $elm$url$Url$Parser$Internal$Parser = function (a) {
	return {$: 'Parser', a: a};
};
var $elm$url$Url$Parser$Query$custom = F2(
	function (key, func) {
		return $elm$url$Url$Parser$Internal$Parser(
			function (dict) {
				return func(
					A2(
						$elm$core$Maybe$withDefault,
						_List_Nil,
						A2($elm$core$Dict$get, key, dict)));
			});
	});
var $elm$url$Url$Parser$Query$string = function (key) {
	return A2(
		$elm$url$Url$Parser$Query$custom,
		key,
		function (stringList) {
			if (stringList.b && (!stringList.b.b)) {
				var str = stringList.a;
				return $elm$core$Maybe$Just(str);
			} else {
				return $elm$core$Maybe$Nothing;
			}
		});
};
var $author$project$NethysSearch$getQueryParam = F2(
	function (url, param) {
		return A2(
			$elm$core$Maybe$withDefault,
			'',
			$elm_community$maybe_extra$Maybe$Extra$join(
				A2(
					$elm$url$Url$Parser$parse,
					$elm$url$Url$Parser$query(
						$elm$url$Url$Parser$Query$string(param)),
					_Utils_update(
						url,
						{path: ''}))));
	});
var $elm_community$string_extra$String$Extra$nonEmpty = function (string) {
	return $elm$core$String$isEmpty(string) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(string);
};
var $author$project$NethysSearch$getBoolDictFromParams = F3(
	function (url, splitOn, param) {
		return $elm$core$Dict$fromList(
			A2(
				$elm$core$List$append,
				A2(
					$elm$core$List$map,
					function (value) {
						return _Utils_Tuple2(value, true);
					},
					A2(
						$elm$core$Maybe$withDefault,
						_List_Nil,
						A2(
							$elm$core$Maybe$map,
							$elm$core$String$split(splitOn),
							$elm_community$string_extra$String$Extra$nonEmpty(
								A2($author$project$NethysSearch$getQueryParam, url, 'include-' + param))))),
				A2(
					$elm$core$List$map,
					function (value) {
						return _Utils_Tuple2(value, false);
					},
					A2(
						$elm$core$Maybe$withDefault,
						_List_Nil,
						A2(
							$elm$core$Maybe$map,
							$elm$core$String$split(splitOn),
							$elm_community$string_extra$String$Extra$nonEmpty(
								A2($author$project$NethysSearch$getQueryParam, url, 'exclude-' + param)))))));
	});
var $author$project$NethysSearch$Asc = {$: 'Asc'};
var $author$project$NethysSearch$Desc = {$: 'Desc'};
var $author$project$NethysSearch$sortDirFromString = function (str) {
	switch (str) {
		case 'asc':
			return $elm$core$Maybe$Just($author$project$NethysSearch$Asc);
		case 'desc':
			return $elm$core$Maybe$Just($author$project$NethysSearch$Desc);
		default:
			return $elm$core$Maybe$Nothing;
	}
};
var $elm$core$Basics$always = F2(
	function (a, _v0) {
		return a;
	});
var $elm$core$String$append = _String_append;
var $elm$regex$Regex$Match = F4(
	function (match, index, number, submatches) {
		return {index: index, match: match, number: number, submatches: submatches};
	});
var $elm$regex$Regex$fromStringWith = _Regex_fromStringWith;
var $elm$regex$Regex$fromString = function (string) {
	return A2(
		$elm$regex$Regex$fromStringWith,
		{caseInsensitive: false, multiline: false},
		string);
};
var $elm$regex$Regex$never = _Regex_never;
var $elm_community$string_extra$String$Extra$regexFromString = A2(
	$elm$core$Basics$composeR,
	$elm$regex$Regex$fromString,
	$elm$core$Maybe$withDefault($elm$regex$Regex$never));
var $elm$regex$Regex$replace = _Regex_replaceAtMost(_Regex_infinity);
var $elm$core$String$cons = _String_cons;
var $elm_community$string_extra$String$Extra$changeCase = F2(
	function (mutator, word) {
		return A2(
			$elm$core$Maybe$withDefault,
			'',
			A2(
				$elm$core$Maybe$map,
				function (_v0) {
					var head = _v0.a;
					var tail = _v0.b;
					return A2(
						$elm$core$String$cons,
						mutator(head),
						tail);
				},
				$elm$core$String$uncons(word)));
	});
var $elm$core$Char$toUpper = _Char_toUpper;
var $elm_community$string_extra$String$Extra$toSentenceCase = function (word) {
	return A2($elm_community$string_extra$String$Extra$changeCase, $elm$core$Char$toUpper, word);
};
var $elm_community$string_extra$String$Extra$humanize = function (string) {
	return $elm_community$string_extra$String$Extra$toSentenceCase(
		$elm$core$String$toLower(
			$elm$core$String$trim(
				A3(
					$elm$regex$Regex$replace,
					$elm_community$string_extra$String$Extra$regexFromString('_id$|[-_\\s]+'),
					$elm$core$Basics$always(' '),
					A3(
						$elm$regex$Regex$replace,
						$elm_community$string_extra$String$Extra$regexFromString('[A-Z]+'),
						A2(
							$elm$core$Basics$composeR,
							function ($) {
								return $.match;
							},
							$elm$core$String$append('-')),
						string)))));
};
var $author$project$Data$sortFieldOld = A2(
	$elm$core$List$append,
	A2(
		$elm$core$List$map,
		function (speed) {
			return _Utils_Tuple2(
				'speed.' + speed,
				$elm_community$string_extra$String$Extra$humanize(speed) + ' speed');
		},
		$author$project$Data$speedTypes),
	A2(
		$elm$core$List$append,
		A2(
			$elm$core$List$map,
			function (type_) {
				return _Utils_Tuple2(
					'weakness.' + type_,
					$elm_community$string_extra$String$Extra$humanize(type_) + ' weakness');
			},
			$author$project$Data$damageTypes),
		A2(
			$elm$core$List$append,
			A2(
				$elm$core$List$map,
				function (type_) {
					return _Utils_Tuple2(
						'resistance.' + type_,
						$elm_community$string_extra$String$Extra$humanize(type_) + ' resistance');
				},
				$author$project$Data$damageTypes),
			_List_fromArray(
				[
					_Utils_Tuple2('ac', 'AC'),
					_Utils_Tuple2('bulk', 'Bulk'),
					_Utils_Tuple2('charisma', 'Charisma'),
					_Utils_Tuple2('constitution', 'Constitution'),
					_Utils_Tuple2('dexterity', 'Dexterity'),
					_Utils_Tuple2('fortitude', 'Fortitude'),
					_Utils_Tuple2('hp', 'HP'),
					_Utils_Tuple2('intelligence', 'Intelligence'),
					_Utils_Tuple2('level', 'Level'),
					_Utils_Tuple2('name', 'Name'),
					_Utils_Tuple2('perception', 'Perception'),
					_Utils_Tuple2('price', 'Price'),
					_Utils_Tuple2('range', 'Range'),
					_Utils_Tuple2('reflex', 'Reflex'),
					_Utils_Tuple2('strength', 'Strength'),
					_Utils_Tuple2('type', 'Type'),
					_Utils_Tuple2('will', 'Will'),
					_Utils_Tuple2('wisdom', 'Wisdom')
				]))));
var $author$project$NethysSearch$updateModelFromUrl = F2(
	function (url, model) {
		return _Utils_update(
			model,
			{
				filterComponentsOperator: A2($author$project$NethysSearch$getQueryParam, url, 'components-operator') !== 'or',
				filterSpoilers: A2($author$project$NethysSearch$getQueryParam, url, 'spoilers') === 'hide',
				filterTraditionsOperator: A2($author$project$NethysSearch$getQueryParam, url, 'traditions-operator') !== 'or',
				filterTraitsOperator: A2($author$project$NethysSearch$getQueryParam, url, 'traits-operator') !== 'or',
				filteredActions: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'actions'),
				filteredAlignments: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'alignments'),
				filteredComponents: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'components'),
				filteredCreatureFamilies: A3($author$project$NethysSearch$getBoolDictFromParams, url, ';', 'creature-families'),
				filteredFromValues: $elm$core$Dict$fromList(
					A2(
						$elm$core$List$filterMap,
						function (string) {
							var _v0 = A2($elm$core$String$split, ':', string);
							if ((_v0.b && _v0.b.b) && (!_v0.b.b.b)) {
								var field = _v0.a;
								var _v1 = _v0.b;
								var value = _v1.a;
								return $elm$core$Maybe$Just(
									_Utils_Tuple2(field, value));
							} else {
								return $elm$core$Maybe$Nothing;
							}
						},
						A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							A2(
								$elm$core$Maybe$map,
								$elm$core$String$split(','),
								$elm_community$string_extra$String$Extra$nonEmpty(
									A2($author$project$NethysSearch$getQueryParam, url, 'values-from')))))),
				filteredItemCategories: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'item-categories'),
				filteredItemSubcategories: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'item-subcategories'),
				filteredPfs: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'pfs'),
				filteredSavingThrows: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'saving-throws'),
				filteredSchools: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'schools'),
				filteredSizes: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'sizes'),
				filteredSourceCategories: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'source-categories'),
				filteredSources: A3($author$project$NethysSearch$getBoolDictFromParams, url, ';', 'sources'),
				filteredStrongestSaves: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'strongest-saves'),
				filteredToValues: $elm$core$Dict$fromList(
					A2(
						$elm$core$List$filterMap,
						function (string) {
							var _v2 = A2($elm$core$String$split, ':', string);
							if ((_v2.b && _v2.b.b) && (!_v2.b.b.b)) {
								var field = _v2.a;
								var _v3 = _v2.b;
								var value = _v3.a;
								return $elm$core$Maybe$Just(
									_Utils_Tuple2(field, value));
							} else {
								return $elm$core$Maybe$Nothing;
							}
						},
						A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							A2(
								$elm$core$Maybe$map,
								$elm$core$String$split(','),
								$elm_community$string_extra$String$Extra$nonEmpty(
									A2($author$project$NethysSearch$getQueryParam, url, 'values-to')))))),
				filteredTraditions: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'traditions'),
				filteredTraits: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'traits'),
				filteredTypes: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'types'),
				filteredWeakestSaves: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'weakest-saves'),
				filteredWeaponCategories: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'weapon-categories'),
				filteredWeaponGroups: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'weapon-groups'),
				filteredWeaponTypes: A3($author$project$NethysSearch$getBoolDictFromParams, url, ',', 'weapon-types'),
				query: A2($author$project$NethysSearch$getQueryParam, url, 'q'),
				queryType: function () {
					var _v4 = A2($author$project$NethysSearch$getQueryParam, url, 'type');
					if (_v4 === 'eqs') {
						return $author$project$NethysSearch$ElasticsearchQueryString;
					} else {
						return $author$project$NethysSearch$Standard;
					}
				}(),
				resultDisplay: (A2($author$project$NethysSearch$getQueryParam, url, 'display') === 'table') ? $author$project$NethysSearch$Table : $author$project$NethysSearch$List,
				sort: A2(
					$elm$core$Maybe$withDefault,
					_List_Nil,
					A2(
						$elm$core$Maybe$map,
						$elm$core$List$filterMap(
							function (str) {
								var _v5 = A2($elm$core$String$split, '-', str);
								if ((_v5.b && _v5.b.b) && (!_v5.b.b.b)) {
									var field = _v5.a;
									var _v6 = _v5.b;
									var dir = _v6.a;
									return A2(
										$elm$core$Maybe$map,
										function (dir_) {
											return _Utils_Tuple2(
												A2(
													$elm$core$Maybe$withDefault,
													field,
													A2(
														$elm$core$Maybe$map,
														$elm$core$Tuple$first,
														A2(
															$elm_community$list_extra$List$Extra$find,
															A2(
																$elm$core$Basics$composeR,
																$elm$core$Tuple$second,
																$elm$core$Basics$eq(field)),
															$author$project$Data$sortFieldOld))),
												dir_);
										},
										$author$project$NethysSearch$sortDirFromString(dir));
								} else {
									return $elm$core$Maybe$Nothing;
								}
							}),
						A2(
							$elm$core$Maybe$map,
							$elm$core$String$split(','),
							$elm_community$string_extra$String$Extra$nonEmpty(
								A2($author$project$NethysSearch$getQueryParam, url, 'sort'))))),
				tableColumns: (A2($author$project$NethysSearch$getQueryParam, url, 'display') === 'table') ? A2(
					$elm$core$Maybe$withDefault,
					_List_Nil,
					A2(
						$elm$core$Maybe$map,
						$elm$core$String$split(','),
						$elm_community$string_extra$String$Extra$nonEmpty(
							A2($author$project$NethysSearch$getQueryParam, url, 'columns')))) : model.tableColumns,
				url: url
			});
	});
var $author$project$NethysSearch$document_setTitle = _Platform_outgoingPort('document_setTitle', $elm$json$Json$Encode$string);
var $author$project$NethysSearch$updateTitle = function (_v0) {
	var model = _v0.a;
	var cmd = _v0.b;
	return _Utils_Tuple2(
		model,
		$elm$core$Platform$Cmd$batch(
			_List_fromArray(
				[
					cmd,
					$author$project$NethysSearch$document_setTitle(model.query)
				])));
};
var $elm$core$Result$withDefault = F2(
	function (def, result) {
		if (result.$ === 'Ok') {
			var a = result.a;
			return a;
		} else {
			return def;
		}
	});
var $author$project$NethysSearch$init = function (flagsValue) {
	var flags = A2(
		$elm$core$Result$withDefault,
		$author$project$NethysSearch$defaultFlags,
		A2($elm$json$Json$Decode$decodeValue, $author$project$NethysSearch$flagsDecoder, flagsValue));
	var url = $author$project$NethysSearch$parseUrl(flags.currentUrl);
	return $author$project$NethysSearch$getAggregations(
		$author$project$NethysSearch$updateTitle(
			A2(
				$author$project$NethysSearch$searchWithCurrentQuery,
				false,
				_Utils_Tuple2(
					A2(
						$author$project$NethysSearch$updateModelFromUrl,
						url,
						{aggregations: $elm$core$Maybe$Nothing, debounce: 0, elasticUrl: flags.elasticUrl, elementHeights: $elm$core$Dict$empty, filterComponentsOperator: true, filterSpoilers: false, filterTraditionsOperator: true, filterTraitsOperator: true, filteredActions: $elm$core$Dict$empty, filteredAlignments: $elm$core$Dict$empty, filteredComponents: $elm$core$Dict$empty, filteredCreatureFamilies: $elm$core$Dict$empty, filteredFromValues: $elm$core$Dict$empty, filteredItemCategories: $elm$core$Dict$empty, filteredItemSubcategories: $elm$core$Dict$empty, filteredPfs: $elm$core$Dict$empty, filteredSavingThrows: $elm$core$Dict$empty, filteredSchools: $elm$core$Dict$empty, filteredSizes: $elm$core$Dict$empty, filteredSourceCategories: $elm$core$Dict$empty, filteredSources: $elm$core$Dict$empty, filteredStrongestSaves: $elm$core$Dict$empty, filteredToValues: $elm$core$Dict$empty, filteredTraditions: $elm$core$Dict$empty, filteredTraits: $elm$core$Dict$empty, filteredTypes: $elm$core$Dict$empty, filteredWeakestSaves: $elm$core$Dict$empty, filteredWeaponCategories: $elm$core$Dict$empty, filteredWeaponGroups: $elm$core$Dict$empty, filteredWeaponTypes: $elm$core$Dict$empty, lastSearchKey: '', limitTableWidth: false, menuOpen: false, overlayActive: false, query: '', queryOptionsOpen: false, queryType: $author$project$NethysSearch$Standard, resultDisplay: $author$project$NethysSearch$List, searchCreatureFamilies: '', searchItemCategories: '', searchItemSubcategories: '', searchResults: _List_Nil, searchSources: '', searchTraits: '', searchTypes: '', selectedColumnResistance: 'acid', selectedColumnSpeed: 'land', selectedColumnWeakness: 'acid', selectedFilterAbility: 'strength', selectedFilterResistance: 'acid', selectedFilterSpeed: 'land', selectedFilterWeakness: 'acid', selectedSortAbility: 'strength', selectedSortResistance: 'acid', selectedSortSpeed: 'land', selectedSortWeakness: 'acid', showHeader: flags.showHeader, showResultAdditionalInfo: true, showResultSpoilers: true, showResultTraits: true, sort: _List_Nil, tableColumns: _List_Nil, theme: $author$project$NethysSearch$Dark, tracker: $elm$core$Maybe$Nothing, url: url}),
					$elm$core$Platform$Cmd$batch(
						_List_fromArray(
							[
								$author$project$NethysSearch$localStorage_get('limit-table-width'),
								$author$project$NethysSearch$localStorage_get('show-additional-info'),
								$author$project$NethysSearch$localStorage_get('show-spoilers'),
								$author$project$NethysSearch$localStorage_get('show-traits'),
								$author$project$NethysSearch$localStorage_get('theme')
							]))))));
};
var $author$project$NethysSearch$GotElementHeight = F2(
	function (a, b) {
		return {$: 'GotElementHeight', a: a, b: b};
	});
var $author$project$NethysSearch$LocalStorageValueReceived = function (a) {
	return {$: 'LocalStorageValueReceived', a: a};
};
var $author$project$NethysSearch$UrlChanged = function (a) {
	return {$: 'UrlChanged', a: a};
};
var $author$project$NethysSearch$WindowResized = F2(
	function (a, b) {
		return {$: 'WindowResized', a: a, b: b};
	});
var $elm$core$Platform$Sub$batch = _Platform_batch;
var $author$project$NethysSearch$document_receiveElementHeight = _Platform_incomingPort(
	'document_receiveElementHeight',
	A2(
		$elm$json$Json$Decode$andThen,
		function (id) {
			return A2(
				$elm$json$Json$Decode$andThen,
				function (height) {
					return $elm$json$Json$Decode$succeed(
						{height: height, id: id});
				},
				A2($elm$json$Json$Decode$field, 'height', $elm$json$Json$Decode$float));
		},
		A2($elm$json$Json$Decode$field, 'id', $elm$json$Json$Decode$string)));
var $author$project$NethysSearch$localStorage_receive = _Platform_incomingPort('localStorage_receive', $elm$json$Json$Decode$value);
var $author$project$NethysSearch$navigation_urlChanged = _Platform_incomingPort('navigation_urlChanged', $elm$json$Json$Decode$string);
var $elm$browser$Browser$Events$Window = {$: 'Window'};
var $elm$browser$Browser$Events$MySub = F3(
	function (a, b, c) {
		return {$: 'MySub', a: a, b: b, c: c};
	});
var $elm$browser$Browser$Events$State = F2(
	function (subs, pids) {
		return {pids: pids, subs: subs};
	});
var $elm$browser$Browser$Events$init = $elm$core$Task$succeed(
	A2($elm$browser$Browser$Events$State, _List_Nil, $elm$core$Dict$empty));
var $elm$browser$Browser$Events$nodeToKey = function (node) {
	if (node.$ === 'Document') {
		return 'd_';
	} else {
		return 'w_';
	}
};
var $elm$browser$Browser$Events$addKey = function (sub) {
	var node = sub.a;
	var name = sub.b;
	return _Utils_Tuple2(
		_Utils_ap(
			$elm$browser$Browser$Events$nodeToKey(node),
			name),
		sub);
};
var $elm$core$Dict$foldl = F3(
	function (func, acc, dict) {
		foldl:
		while (true) {
			if (dict.$ === 'RBEmpty_elm_builtin') {
				return acc;
			} else {
				var key = dict.b;
				var value = dict.c;
				var left = dict.d;
				var right = dict.e;
				var $temp$func = func,
					$temp$acc = A3(
					func,
					key,
					value,
					A3($elm$core$Dict$foldl, func, acc, left)),
					$temp$dict = right;
				func = $temp$func;
				acc = $temp$acc;
				dict = $temp$dict;
				continue foldl;
			}
		}
	});
var $elm$core$Dict$merge = F6(
	function (leftStep, bothStep, rightStep, leftDict, rightDict, initialResult) {
		var stepState = F3(
			function (rKey, rValue, _v0) {
				stepState:
				while (true) {
					var list = _v0.a;
					var result = _v0.b;
					if (!list.b) {
						return _Utils_Tuple2(
							list,
							A3(rightStep, rKey, rValue, result));
					} else {
						var _v2 = list.a;
						var lKey = _v2.a;
						var lValue = _v2.b;
						var rest = list.b;
						if (_Utils_cmp(lKey, rKey) < 0) {
							var $temp$rKey = rKey,
								$temp$rValue = rValue,
								$temp$_v0 = _Utils_Tuple2(
								rest,
								A3(leftStep, lKey, lValue, result));
							rKey = $temp$rKey;
							rValue = $temp$rValue;
							_v0 = $temp$_v0;
							continue stepState;
						} else {
							if (_Utils_cmp(lKey, rKey) > 0) {
								return _Utils_Tuple2(
									list,
									A3(rightStep, rKey, rValue, result));
							} else {
								return _Utils_Tuple2(
									rest,
									A4(bothStep, lKey, lValue, rValue, result));
							}
						}
					}
				}
			});
		var _v3 = A3(
			$elm$core$Dict$foldl,
			stepState,
			_Utils_Tuple2(
				$elm$core$Dict$toList(leftDict),
				initialResult),
			rightDict);
		var leftovers = _v3.a;
		var intermediateResult = _v3.b;
		return A3(
			$elm$core$List$foldl,
			F2(
				function (_v4, result) {
					var k = _v4.a;
					var v = _v4.b;
					return A3(leftStep, k, v, result);
				}),
			intermediateResult,
			leftovers);
	});
var $elm$browser$Browser$Events$Event = F2(
	function (key, event) {
		return {event: event, key: key};
	});
var $elm$browser$Browser$Events$spawn = F3(
	function (router, key, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var actualNode = function () {
			if (node.$ === 'Document') {
				return _Browser_doc;
			} else {
				return _Browser_window;
			}
		}();
		return A2(
			$elm$core$Task$map,
			function (value) {
				return _Utils_Tuple2(key, value);
			},
			A3(
				_Browser_on,
				actualNode,
				name,
				function (event) {
					return A2(
						$elm$core$Platform$sendToSelf,
						router,
						A2($elm$browser$Browser$Events$Event, key, event));
				}));
	});
var $elm$core$Dict$union = F2(
	function (t1, t2) {
		return A3($elm$core$Dict$foldl, $elm$core$Dict$insert, t2, t1);
	});
var $elm$browser$Browser$Events$onEffects = F3(
	function (router, subs, state) {
		var stepRight = F3(
			function (key, sub, _v6) {
				var deads = _v6.a;
				var lives = _v6.b;
				var news = _v6.c;
				return _Utils_Tuple3(
					deads,
					lives,
					A2(
						$elm$core$List$cons,
						A3($elm$browser$Browser$Events$spawn, router, key, sub),
						news));
			});
		var stepLeft = F3(
			function (_v4, pid, _v5) {
				var deads = _v5.a;
				var lives = _v5.b;
				var news = _v5.c;
				return _Utils_Tuple3(
					A2($elm$core$List$cons, pid, deads),
					lives,
					news);
			});
		var stepBoth = F4(
			function (key, pid, _v2, _v3) {
				var deads = _v3.a;
				var lives = _v3.b;
				var news = _v3.c;
				return _Utils_Tuple3(
					deads,
					A3($elm$core$Dict$insert, key, pid, lives),
					news);
			});
		var newSubs = A2($elm$core$List$map, $elm$browser$Browser$Events$addKey, subs);
		var _v0 = A6(
			$elm$core$Dict$merge,
			stepLeft,
			stepBoth,
			stepRight,
			state.pids,
			$elm$core$Dict$fromList(newSubs),
			_Utils_Tuple3(_List_Nil, $elm$core$Dict$empty, _List_Nil));
		var deadPids = _v0.a;
		var livePids = _v0.b;
		var makeNewPids = _v0.c;
		return A2(
			$elm$core$Task$andThen,
			function (pids) {
				return $elm$core$Task$succeed(
					A2(
						$elm$browser$Browser$Events$State,
						newSubs,
						A2(
							$elm$core$Dict$union,
							livePids,
							$elm$core$Dict$fromList(pids))));
			},
			A2(
				$elm$core$Task$andThen,
				function (_v1) {
					return $elm$core$Task$sequence(makeNewPids);
				},
				$elm$core$Task$sequence(
					A2($elm$core$List$map, $elm$core$Process$kill, deadPids))));
	});
var $elm$browser$Browser$Events$onSelfMsg = F3(
	function (router, _v0, state) {
		var key = _v0.key;
		var event = _v0.event;
		var toMessage = function (_v2) {
			var subKey = _v2.a;
			var _v3 = _v2.b;
			var node = _v3.a;
			var name = _v3.b;
			var decoder = _v3.c;
			return _Utils_eq(subKey, key) ? A2(_Browser_decodeEvent, decoder, event) : $elm$core$Maybe$Nothing;
		};
		var messages = A2($elm$core$List$filterMap, toMessage, state.subs);
		return A2(
			$elm$core$Task$andThen,
			function (_v1) {
				return $elm$core$Task$succeed(state);
			},
			$elm$core$Task$sequence(
				A2(
					$elm$core$List$map,
					$elm$core$Platform$sendToApp(router),
					messages)));
	});
var $elm$browser$Browser$Events$subMap = F2(
	function (func, _v0) {
		var node = _v0.a;
		var name = _v0.b;
		var decoder = _v0.c;
		return A3(
			$elm$browser$Browser$Events$MySub,
			node,
			name,
			A2($elm$json$Json$Decode$map, func, decoder));
	});
_Platform_effectManagers['Browser.Events'] = _Platform_createManager($elm$browser$Browser$Events$init, $elm$browser$Browser$Events$onEffects, $elm$browser$Browser$Events$onSelfMsg, 0, $elm$browser$Browser$Events$subMap);
var $elm$browser$Browser$Events$subscription = _Platform_leaf('Browser.Events');
var $elm$browser$Browser$Events$on = F3(
	function (node, name, decoder) {
		return $elm$browser$Browser$Events$subscription(
			A3($elm$browser$Browser$Events$MySub, node, name, decoder));
	});
var $elm$browser$Browser$Events$onResize = function (func) {
	return A3(
		$elm$browser$Browser$Events$on,
		$elm$browser$Browser$Events$Window,
		'resize',
		A2(
			$elm$json$Json$Decode$field,
			'target',
			A3(
				$elm$json$Json$Decode$map2,
				func,
				A2($elm$json$Json$Decode$field, 'innerWidth', $elm$json$Json$Decode$int),
				A2($elm$json$Json$Decode$field, 'innerHeight', $elm$json$Json$Decode$int))));
};
var $elm$core$Basics$round = _Basics_round;
var $author$project$NethysSearch$subscriptions = function (model) {
	return $elm$core$Platform$Sub$batch(
		_List_fromArray(
			[
				$elm$browser$Browser$Events$onResize($author$project$NethysSearch$WindowResized),
				$author$project$NethysSearch$document_receiveElementHeight(
				function (_v0) {
					var id = _v0.id;
					var height = _v0.height;
					return A2(
						$author$project$NethysSearch$GotElementHeight,
						id,
						$elm$core$Basics$round(height));
				}),
				$author$project$NethysSearch$localStorage_receive($author$project$NethysSearch$LocalStorageValueReceived),
				$author$project$NethysSearch$navigation_urlChanged($author$project$NethysSearch$UrlChanged)
			]));
};
var $author$project$NethysSearch$DebouncePassed = function (a) {
	return {$: 'DebouncePassed', a: a};
};
var $author$project$NethysSearch$ExtraContrast = {$: 'ExtraContrast'};
var $author$project$NethysSearch$Lavender = {$: 'Lavender'};
var $author$project$NethysSearch$Light = {$: 'Light'};
var $author$project$NethysSearch$MenuOpenDelayPassed = {$: 'MenuOpenDelayPassed'};
var $author$project$NethysSearch$NoOp = {$: 'NoOp'};
var $author$project$NethysSearch$Paper = {$: 'Paper'};
var $elm$core$Dict$filter = F2(
	function (isGood, dict) {
		return A3(
			$elm$core$Dict$foldl,
			F3(
				function (k, v, d) {
					return A2(isGood, k, v) ? A3($elm$core$Dict$insert, k, v, d) : d;
				}),
			$elm$core$Dict$empty,
			dict);
	});
var $author$project$NethysSearch$filterCreaturesMeasureWrapperId = 'filter-creatures-measure-wrapper';
var $author$project$NethysSearch$filterItemCategoriesMeasureWrapperId = 'filter-item-categories-measure-wrapper';
var $author$project$NethysSearch$filterSourcesMeasureWrapperId = 'filter-sources-measure-wrapper';
var $author$project$NethysSearch$filterTraitsMeasureWrapperId = 'filter-traits-measure-wrapper';
var $author$project$NethysSearch$filterTypesMeasureWrapperId = 'filter-types-measure-wrapper';
var $author$project$NethysSearch$document_getElementHeight = _Platform_outgoingPort('document_getElementHeight', $elm$json$Json$Encode$string);
var $author$project$NethysSearch$getElementHeight = function (id) {
	return $author$project$NethysSearch$document_getElementHeight(id);
};
var $elm_community$result_extra$Result$Extra$isOk = function (x) {
	if (x.$ === 'Ok') {
		return true;
	} else {
		return false;
	}
};
var $elm$core$Tuple$mapSecond = F2(
	function (func, _v0) {
		var x = _v0.a;
		var y = _v0.b;
		return _Utils_Tuple2(
			x,
			func(y));
	});
var $author$project$NethysSearch$filterAlignmentsMeasureWrapperId = 'filter-alignments-measure-wrapper';
var $author$project$NethysSearch$filterPfsMeasureWrapperId = 'filter-pfs-measure-wrapper';
var $author$project$NethysSearch$filterSizesMeasureWrapperId = 'filter-sizes-measure-wrapper';
var $author$project$NethysSearch$filterSpellsMeasureWrapperId = 'filter-spells-measure-wrapper';
var $author$project$NethysSearch$filterValuesMeasureWrapperId = 'filter-values-measure-wrapper';
var $author$project$NethysSearch$filterWeaponsMeasureWrapperId = 'filter-weapons-measure-wrapper';
var $author$project$NethysSearch$queryOptionsMeasureWrapperId = 'query-options-measure-wrapper';
var $author$project$NethysSearch$queryTypeMeasureWrapperId = 'query-type-measure-wrapper';
var $author$project$NethysSearch$resultDisplayMeasureWrapperId = 'result-display-measure-wrapper';
var $author$project$NethysSearch$sortResultsMeasureWrapperId = 'sort-results-measure-wrapper';
var $author$project$NethysSearch$measureWrapperIds = _List_fromArray(
	[$author$project$NethysSearch$queryOptionsMeasureWrapperId, $author$project$NethysSearch$queryTypeMeasureWrapperId, $author$project$NethysSearch$filterAlignmentsMeasureWrapperId, $author$project$NethysSearch$filterCreaturesMeasureWrapperId, $author$project$NethysSearch$filterItemCategoriesMeasureWrapperId, $author$project$NethysSearch$filterPfsMeasureWrapperId, $author$project$NethysSearch$filterSizesMeasureWrapperId, $author$project$NethysSearch$filterSourcesMeasureWrapperId, $author$project$NethysSearch$filterSpellsMeasureWrapperId, $author$project$NethysSearch$filterTraitsMeasureWrapperId, $author$project$NethysSearch$filterTypesMeasureWrapperId, $author$project$NethysSearch$filterValuesMeasureWrapperId, $author$project$NethysSearch$filterWeaponsMeasureWrapperId, $author$project$NethysSearch$resultDisplayMeasureWrapperId, $author$project$NethysSearch$sortResultsMeasureWrapperId]);
var $author$project$NethysSearch$navigation_loadUrl = _Platform_outgoingPort('navigation_loadUrl', $elm$json$Json$Encode$string);
var $author$project$NethysSearch$navigation_pushUrl = _Platform_outgoingPort('navigation_pushUrl', $elm$json$Json$Encode$string);
var $author$project$NethysSearch$localStorage_set = _Platform_outgoingPort('localStorage_set', $elm$core$Basics$identity);
var $author$project$NethysSearch$saveToLocalStorage = F2(
	function (key, value) {
		return $author$project$NethysSearch$localStorage_set(
			$elm$json$Json$Encode$object(
				_List_fromArray(
					[
						_Utils_Tuple2(
						'key',
						$elm$json$Json$Encode$string(key)),
						_Utils_Tuple2(
						'value',
						$elm$json$Json$Encode$string(value))
					])));
	});
var $elm$browser$Browser$Dom$setViewport = _Browser_setViewport;
var $elm$core$Process$sleep = _Process_sleep;
var $elm$core$List$drop = F2(
	function (n, list) {
		drop:
		while (true) {
			if (n <= 0) {
				return list;
			} else {
				if (!list.b) {
					return list;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs;
					n = $temp$n;
					list = $temp$list;
					continue drop;
				}
			}
		}
	});
var $elm$core$List$takeReverse = F3(
	function (n, list, kept) {
		takeReverse:
		while (true) {
			if (n <= 0) {
				return kept;
			} else {
				if (!list.b) {
					return kept;
				} else {
					var x = list.a;
					var xs = list.b;
					var $temp$n = n - 1,
						$temp$list = xs,
						$temp$kept = A2($elm$core$List$cons, x, kept);
					n = $temp$n;
					list = $temp$list;
					kept = $temp$kept;
					continue takeReverse;
				}
			}
		}
	});
var $elm$core$List$takeTailRec = F2(
	function (n, list) {
		return $elm$core$List$reverse(
			A3($elm$core$List$takeReverse, n, list, _List_Nil));
	});
var $elm$core$List$takeFast = F3(
	function (ctr, n, list) {
		if (n <= 0) {
			return _List_Nil;
		} else {
			var _v0 = _Utils_Tuple2(n, list);
			_v0$1:
			while (true) {
				_v0$5:
				while (true) {
					if (!_v0.b.b) {
						return list;
					} else {
						if (_v0.b.b.b) {
							switch (_v0.a) {
								case 1:
									break _v0$1;
								case 2:
									var _v2 = _v0.b;
									var x = _v2.a;
									var _v3 = _v2.b;
									var y = _v3.a;
									return _List_fromArray(
										[x, y]);
								case 3:
									if (_v0.b.b.b.b) {
										var _v4 = _v0.b;
										var x = _v4.a;
										var _v5 = _v4.b;
										var y = _v5.a;
										var _v6 = _v5.b;
										var z = _v6.a;
										return _List_fromArray(
											[x, y, z]);
									} else {
										break _v0$5;
									}
								default:
									if (_v0.b.b.b.b && _v0.b.b.b.b.b) {
										var _v7 = _v0.b;
										var x = _v7.a;
										var _v8 = _v7.b;
										var y = _v8.a;
										var _v9 = _v8.b;
										var z = _v9.a;
										var _v10 = _v9.b;
										var w = _v10.a;
										var tl = _v10.b;
										return (ctr > 1000) ? A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A2($elm$core$List$takeTailRec, n - 4, tl))))) : A2(
											$elm$core$List$cons,
											x,
											A2(
												$elm$core$List$cons,
												y,
												A2(
													$elm$core$List$cons,
													z,
													A2(
														$elm$core$List$cons,
														w,
														A3($elm$core$List$takeFast, ctr + 1, n - 4, tl)))));
									} else {
										break _v0$5;
									}
							}
						} else {
							if (_v0.a === 1) {
								break _v0$1;
							} else {
								break _v0$5;
							}
						}
					}
				}
				return list;
			}
			var _v1 = _v0.b;
			var x = _v1.a;
			return _List_fromArray(
				[x]);
		}
	});
var $elm$core$List$take = F2(
	function (n, list) {
		return A3($elm$core$List$takeFast, 0, n, list);
	});
var $elm_community$list_extra$List$Extra$splitAt = F2(
	function (n, xs) {
		return _Utils_Tuple2(
			A2($elm$core$List$take, n, xs),
			A2($elm$core$List$drop, n, xs));
	});
var $elm_community$list_extra$List$Extra$uncons = function (list) {
	if (!list.b) {
		return $elm$core$Maybe$Nothing;
	} else {
		var first = list.a;
		var rest = list.b;
		return $elm$core$Maybe$Just(
			_Utils_Tuple2(first, rest));
	}
};
var $elm_community$list_extra$List$Extra$swapAt = F3(
	function (index1, index2, l) {
		swapAt:
		while (true) {
			if (_Utils_eq(index1, index2) || (index1 < 0)) {
				return l;
			} else {
				if (_Utils_cmp(index1, index2) > 0) {
					var $temp$index1 = index2,
						$temp$index2 = index1,
						$temp$l = l;
					index1 = $temp$index1;
					index2 = $temp$index2;
					l = $temp$l;
					continue swapAt;
				} else {
					var _v0 = A2($elm_community$list_extra$List$Extra$splitAt, index1, l);
					var part1 = _v0.a;
					var tail1 = _v0.b;
					var _v1 = A2($elm_community$list_extra$List$Extra$splitAt, index2 - index1, tail1);
					var head2 = _v1.a;
					var tail2 = _v1.b;
					var _v2 = _Utils_Tuple2(
						$elm_community$list_extra$List$Extra$uncons(head2),
						$elm_community$list_extra$List$Extra$uncons(tail2));
					if ((_v2.a.$ === 'Just') && (_v2.b.$ === 'Just')) {
						var _v3 = _v2.a.a;
						var value1 = _v3.a;
						var part2 = _v3.b;
						var _v4 = _v2.b.a;
						var value2 = _v4.a;
						var part3 = _v4.b;
						return $elm$core$List$concat(
							_List_fromArray(
								[
									part1,
									A2($elm$core$List$cons, value2, part2),
									A2($elm$core$List$cons, value1, part3)
								]));
					} else {
						return l;
					}
				}
			}
		}
	});
var $elm$url$Url$addPort = F2(
	function (maybePort, starter) {
		if (maybePort.$ === 'Nothing') {
			return starter;
		} else {
			var port_ = maybePort.a;
			return starter + (':' + $elm$core$String$fromInt(port_));
		}
	});
var $elm$url$Url$addPrefixed = F3(
	function (prefix, maybeSegment, starter) {
		if (maybeSegment.$ === 'Nothing') {
			return starter;
		} else {
			var segment = maybeSegment.a;
			return _Utils_ap(
				starter,
				_Utils_ap(prefix, segment));
		}
	});
var $elm$url$Url$toString = function (url) {
	var http = function () {
		var _v0 = url.protocol;
		if (_v0.$ === 'Http') {
			return 'http://';
		} else {
			return 'https://';
		}
	}();
	return A3(
		$elm$url$Url$addPrefixed,
		'#',
		url.fragment,
		A3(
			$elm$url$Url$addPrefixed,
			'?',
			url.query,
			_Utils_ap(
				A2(
					$elm$url$Url$addPort,
					url.port_,
					_Utils_ap(http, url.host)),
				url.path)));
};
var $author$project$NethysSearch$toggleBoolDict = F2(
	function (key, dict) {
		return A3(
			$elm$core$Dict$update,
			key,
			function (value) {
				if (value.$ === 'Just') {
					if (value.a) {
						return $elm$core$Maybe$Just(false);
					} else {
						return $elm$core$Maybe$Nothing;
					}
				} else {
					return $elm$core$Maybe$Just(true);
				}
			},
			dict);
	});
var $elm_community$list_extra$List$Extra$updateIf = F3(
	function (predicate, update, list) {
		return A2(
			$elm$core$List$map,
			function (item) {
				return predicate(item) ? update(item) : item;
			},
			list);
	});
var $elm$url$Url$Builder$QueryParameter = F2(
	function (a, b) {
		return {$: 'QueryParameter', a: a, b: b};
	});
var $elm$url$Url$percentEncode = _Url_percentEncode;
var $elm$url$Url$Builder$string = F2(
	function (key, value) {
		return A2(
			$elm$url$Url$Builder$QueryParameter,
			$elm$url$Url$percentEncode(key),
			$elm$url$Url$percentEncode(value));
	});
var $elm$url$Url$Builder$toQueryPair = function (_v0) {
	var key = _v0.a;
	var value = _v0.b;
	return key + ('=' + value);
};
var $elm$url$Url$Builder$toQuery = function (parameters) {
	if (!parameters.b) {
		return '';
	} else {
		return '?' + A2(
			$elm$core$String$join,
			'&',
			A2($elm$core$List$map, $elm$url$Url$Builder$toQueryPair, parameters));
	}
};
var $author$project$NethysSearch$updateUrl = function (model) {
	var url = model.url;
	return $author$project$NethysSearch$navigation_pushUrl(
		$elm$url$Url$toString(
			_Utils_update(
				url,
				{
					query: $elm_community$string_extra$String$Extra$nonEmpty(
						A2(
							$elm$core$String$dropLeft,
							1,
							$elm$url$Url$Builder$toQuery(
								A2(
									$elm$core$List$map,
									function (_v4) {
										var key = _v4.a;
										var val = _v4.b;
										return A2($elm$url$Url$Builder$string, key, val);
									},
									A2(
										$elm$core$List$filter,
										A2(
											$elm$core$Basics$composeR,
											$elm$core$Tuple$second,
											A2($elm$core$Basics$composeR, $elm$core$String$isEmpty, $elm$core$Basics$not)),
										_List_fromArray(
											[
												_Utils_Tuple2('q', model.query),
												_Utils_Tuple2(
												'type',
												function () {
													var _v0 = model.queryType;
													if (_v0.$ === 'Standard') {
														return '';
													} else {
														return 'eqs';
													}
												}()),
												_Utils_Tuple2(
												'include-traits',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredTraits))),
												_Utils_Tuple2(
												'exclude-traits',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredTraits))),
												_Utils_Tuple2(
												'traits-operator',
												model.filterTraitsOperator ? '' : 'or'),
												_Utils_Tuple2(
												'include-types',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredTypes))),
												_Utils_Tuple2(
												'exclude-types',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredTypes))),
												_Utils_Tuple2(
												'include-actions',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredActions))),
												_Utils_Tuple2(
												'exclude-actions',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredActions))),
												_Utils_Tuple2(
												'include-alignments',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredAlignments))),
												_Utils_Tuple2(
												'exclude-alignments',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredAlignments))),
												_Utils_Tuple2(
												'include-components',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredComponents))),
												_Utils_Tuple2(
												'exclude-components',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredComponents))),
												_Utils_Tuple2(
												'components-operator',
												model.filterComponentsOperator ? '' : 'or'),
												_Utils_Tuple2(
												'include-creature-families',
												A2(
													$elm$core$String$join,
													';',
													$author$project$NethysSearch$boolDictIncluded(model.filteredCreatureFamilies))),
												_Utils_Tuple2(
												'exclude-creature-families',
												A2(
													$elm$core$String$join,
													';',
													$author$project$NethysSearch$boolDictExcluded(model.filteredCreatureFamilies))),
												_Utils_Tuple2(
												'include-item-categories',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredItemCategories))),
												_Utils_Tuple2(
												'exclude-item-categories',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredItemCategories))),
												_Utils_Tuple2(
												'include-item-subcategories',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredItemSubcategories))),
												_Utils_Tuple2(
												'exclude-item-subcategories',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredItemSubcategories))),
												_Utils_Tuple2(
												'include-pfs',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredPfs))),
												_Utils_Tuple2(
												'exclude-pfs',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredPfs))),
												_Utils_Tuple2(
												'include-saving-throws',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredSavingThrows))),
												_Utils_Tuple2(
												'exclude-saving-throws',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredSavingThrows))),
												_Utils_Tuple2(
												'include-schools',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredSchools))),
												_Utils_Tuple2(
												'exclude-schools',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredSchools))),
												_Utils_Tuple2(
												'include-sizes',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredSizes))),
												_Utils_Tuple2(
												'exclude-sizes',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredSizes))),
												_Utils_Tuple2(
												'include-sources',
												A2(
													$elm$core$String$join,
													';',
													$author$project$NethysSearch$boolDictIncluded(model.filteredSources))),
												_Utils_Tuple2(
												'exclude-sources',
												A2(
													$elm$core$String$join,
													';',
													$author$project$NethysSearch$boolDictExcluded(model.filteredSources))),
												_Utils_Tuple2(
												'include-source-categories',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredSourceCategories))),
												_Utils_Tuple2(
												'exclude-source-categories',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredSourceCategories))),
												_Utils_Tuple2(
												'include-strongest-saves',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredStrongestSaves))),
												_Utils_Tuple2(
												'exclude-strongest-saves',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredStrongestSaves))),
												_Utils_Tuple2(
												'include-traditions',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredTraditions))),
												_Utils_Tuple2(
												'exclude-traditions',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredTraditions))),
												_Utils_Tuple2(
												'traditions-operator',
												model.filterTraditionsOperator ? '' : 'or'),
												_Utils_Tuple2(
												'include-weakest-saves',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredWeakestSaves))),
												_Utils_Tuple2(
												'exclude-weakest-saves',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredWeakestSaves))),
												_Utils_Tuple2(
												'include-weapon-categories',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredWeaponCategories))),
												_Utils_Tuple2(
												'exclude-weapon-categories',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredWeaponCategories))),
												_Utils_Tuple2(
												'include-weapon-groups',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredWeaponGroups))),
												_Utils_Tuple2(
												'exclude-weapon-groups',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredWeaponGroups))),
												_Utils_Tuple2(
												'include-weapon-types',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictIncluded(model.filteredWeaponTypes))),
												_Utils_Tuple2(
												'exclude-weapon-types',
												A2(
													$elm$core$String$join,
													',',
													$author$project$NethysSearch$boolDictExcluded(model.filteredWeaponTypes))),
												_Utils_Tuple2(
												'values-from',
												A2(
													$elm$core$String$join,
													',',
													A2(
														$elm$core$List$map,
														function (_v1) {
															var field = _v1.a;
															var value = _v1.b;
															return field + (':' + value);
														},
														$elm$core$Dict$toList(model.filteredFromValues)))),
												_Utils_Tuple2(
												'values-to',
												A2(
													$elm$core$String$join,
													',',
													A2(
														$elm$core$List$map,
														function (_v2) {
															var field = _v2.a;
															var value = _v2.b;
															return field + (':' + value);
														},
														$elm$core$Dict$toList(model.filteredToValues)))),
												_Utils_Tuple2(
												'spoilers',
												model.filterSpoilers ? 'hide' : ''),
												_Utils_Tuple2(
												'display',
												_Utils_eq(model.resultDisplay, $author$project$NethysSearch$Table) ? 'table' : ''),
												_Utils_Tuple2(
												'columns',
												_Utils_eq(model.resultDisplay, $author$project$NethysSearch$Table) ? A2($elm$core$String$join, ',', model.tableColumns) : ''),
												_Utils_Tuple2(
												'sort',
												A2(
													$elm$core$String$join,
													',',
													A2(
														$elm$core$List$map,
														function (_v3) {
															var field = _v3.a;
															var dir = _v3.b;
															return field + ('-' + $author$project$NethysSearch$sortDirToString(dir));
														},
														model.sort)))
											]))))))
				})));
};
var $author$project$NethysSearch$update = F2(
	function (msg, model) {
		switch (msg.$) {
			case 'ActionsFilterAdded':
				var actions = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredActions: A2($author$project$NethysSearch$toggleBoolDict, actions, model.filteredActions)
							})));
			case 'ActionsFilterRemoved':
				var actions = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredActions: A2($elm$core$Dict$remove, actions, model.filteredActions)
							})));
			case 'AlignmentFilterAdded':
				var alignment = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredAlignments: A2($author$project$NethysSearch$toggleBoolDict, alignment, model.filteredAlignments)
							})));
			case 'AlignmentFilterRemoved':
				var alignment = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredAlignments: A2($elm$core$Dict$remove, alignment, model.filteredAlignments)
							})));
			case 'ColumnResistanceChanged':
				var resistance = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedColumnResistance: resistance}),
					$elm$core$Platform$Cmd$none);
			case 'ColumnSpeedChanged':
				var speed = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedColumnSpeed: speed}),
					$elm$core$Platform$Cmd$none);
			case 'ColumnWeaknessChanged':
				var weakness = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedColumnWeakness: weakness}),
					$elm$core$Platform$Cmd$none);
			case 'ComponentFilterAdded':
				var component = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredComponents: A2($author$project$NethysSearch$toggleBoolDict, component, model.filteredComponents)
							})));
			case 'ComponentFilterRemoved':
				var component = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredComponents: A2($elm$core$Dict$remove, component, model.filteredComponents)
							})));
			case 'CreatureFamilyFilterAdded':
				var creatureFamily = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredCreatureFamilies: A2($author$project$NethysSearch$toggleBoolDict, creatureFamily, model.filteredCreatureFamilies)
							})));
			case 'CreatureFamilyFilterRemoved':
				var creatureFamily = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredCreatureFamilies: A2($elm$core$Dict$remove, creatureFamily, model.filteredCreatureFamilies)
							})));
			case 'DebouncePassed':
				var debounce = msg.a;
				return _Utils_eq(model.debounce, debounce) ? _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(model)) : _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
			case 'GotAggregationsResult':
				var result = msg.a;
				return ((!$elm$core$Dict$isEmpty(model.filteredSourceCategories)) ? $author$project$NethysSearch$searchWithCurrentQuery(false) : $elm$core$Basics$identity)(
					_Utils_Tuple2(
						_Utils_update(
							model,
							{
								aggregations: $elm$core$Maybe$Just(result)
							}),
						$elm$core$Platform$Cmd$none));
			case 'GotElementHeight':
				var id = msg.a;
				var height = msg.b;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							elementHeights: A3($elm$core$Dict$insert, id, height, model.elementHeights)
						}),
					$elm$core$Platform$Cmd$none);
			case 'GotSearchResult':
				var result = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{
							searchResults: A2(
								$elm$core$List$append,
								A2($elm$core$List$filter, $elm_community$result_extra$Result$Extra$isOk, model.searchResults),
								_List_fromArray(
									[result])),
							tracker: $elm$core$Maybe$Nothing
						}),
					$elm$core$Platform$Cmd$none);
			case 'FilterAbilityChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedFilterAbility: value}),
					$elm$core$Platform$Cmd$none);
			case 'FilterComponentsOperatorChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filterComponentsOperator: value})));
			case 'FilterResistanceChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedFilterResistance: value}),
					$elm$core$Platform$Cmd$none);
			case 'FilterSpeedChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedFilterSpeed: value}),
					$elm$core$Platform$Cmd$none);
			case 'FilterSpoilersChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filterSpoilers: value})));
			case 'FilterTraditionsOperatorChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filterTraditionsOperator: value})));
			case 'FilterTraitsOperatorChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filterTraitsOperator: value})));
			case 'FilterWeaknessChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedFilterWeakness: value}),
					$elm$core$Platform$Cmd$none);
			case 'FilteredFromValueChanged':
				var key = msg.a;
				var value = msg.b;
				var updatedModel = _Utils_update(
					model,
					{
						filteredFromValues: $elm$core$String$isEmpty(value) ? A2($elm$core$Dict$remove, key, model.filteredFromValues) : A3($elm$core$Dict$insert, key, value, model.filteredFromValues)
					});
				return _Utils_Tuple2(
					updatedModel,
					$author$project$NethysSearch$updateUrl(updatedModel));
			case 'FilteredToValueChanged':
				var key = msg.a;
				var value = msg.b;
				var updatedModel = _Utils_update(
					model,
					{
						filteredToValues: $elm$core$String$isEmpty(value) ? A2($elm$core$Dict$remove, key, model.filteredToValues) : A3($elm$core$Dict$insert, key, value, model.filteredToValues)
					});
				return _Utils_Tuple2(
					updatedModel,
					$author$project$NethysSearch$updateUrl(updatedModel));
			case 'ItemCategoryFilterAdded':
				var category = msg.a;
				var newFilteredItemCategories = A2($author$project$NethysSearch$toggleBoolDict, category, model.filteredItemCategories);
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredItemCategories: newFilteredItemCategories,
								filteredItemSubcategories: function () {
									var _v1 = A2($elm$core$Dict$get, category, newFilteredItemCategories);
									if (_v1.$ === 'Just') {
										if (_v1.a) {
											return A2(
												$elm$core$Dict$filter,
												F2(
													function (source, _v2) {
														return A2(
															$elm$core$List$member,
															source,
															A2(
																$elm$core$List$map,
																function ($) {
																	return $.name;
																},
																A2(
																	$elm$core$List$filter,
																	function (sc) {
																		return A2(
																			$elm$core$List$member,
																			sc.category,
																			$author$project$NethysSearch$boolDictIncluded(newFilteredItemCategories));
																	},
																	A2(
																		$elm$core$Maybe$withDefault,
																		_List_Nil,
																		A2(
																			$elm$core$Maybe$map,
																			function ($) {
																				return $.itemSubcategories;
																			},
																			A2($elm$core$Maybe$andThen, $elm$core$Result$toMaybe, model.aggregations))))));
													}),
												model.filteredItemSubcategories);
										} else {
											return A2(
												$elm$core$Dict$filter,
												F2(
													function (source, _v3) {
														return !_Utils_eq(
															$elm$core$Maybe$Just(category),
															A2(
																$elm$core$Maybe$map,
																$elm$core$String$toLower,
																A2(
																	$elm$core$Maybe$map,
																	function ($) {
																		return $.category;
																	},
																	A2(
																		$elm$core$Maybe$andThen,
																		$elm_community$list_extra$List$Extra$find(
																			A2(
																				$elm$core$Basics$composeR,
																				function ($) {
																					return $.name;
																				},
																				$elm$core$Basics$eq(source))),
																		A2(
																			$elm$core$Maybe$map,
																			function ($) {
																				return $.itemSubcategories;
																			},
																			A2($elm$core$Maybe$andThen, $elm$core$Result$toMaybe, model.aggregations))))));
													}),
												model.filteredItemSubcategories);
										}
									} else {
										return model.filteredItemSubcategories;
									}
								}()
							})));
			case 'ItemCategoryFilterRemoved':
				var category = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredItemCategories: A2($elm$core$Dict$remove, category, model.filteredItemCategories)
							})));
			case 'ItemSubcategoryFilterAdded':
				var subcategory = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredItemSubcategories: A2($author$project$NethysSearch$toggleBoolDict, subcategory, model.filteredItemSubcategories)
							})));
			case 'ItemSubcategoryFilterRemoved':
				var subcategory = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredItemSubcategories: A2($elm$core$Dict$remove, subcategory, model.filteredItemSubcategories)
							})));
			case 'LimitTableWidthChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{limitTableWidth: value}),
					A2(
						$author$project$NethysSearch$saveToLocalStorage,
						'limit-table-width',
						value ? '1' : '0'));
			case 'LoadMorePressed':
				return A2(
					$author$project$NethysSearch$searchWithCurrentQuery,
					true,
					_Utils_Tuple2(model, $elm$core$Platform$Cmd$none));
			case 'LocalStorageValueReceived':
				var value = msg.a;
				return _Utils_Tuple2(
					function () {
						var _v4 = A2(
							$elm$json$Json$Decode$decodeValue,
							A2($elm$json$Json$Decode$field, 'key', $elm$json$Json$Decode$string),
							value);
						_v4$5:
						while (true) {
							if (_v4.$ === 'Ok') {
								switch (_v4.a) {
									case 'theme':
										var _v5 = A2(
											$elm$json$Json$Decode$decodeValue,
											A2($elm$json$Json$Decode$field, 'value', $elm$json$Json$Decode$string),
											value);
										_v5$8:
										while (true) {
											if (_v5.$ === 'Ok') {
												switch (_v5.a) {
													case 'dark':
														return _Utils_update(
															model,
															{theme: $author$project$NethysSearch$Dark});
													case 'light':
														return _Utils_update(
															model,
															{theme: $author$project$NethysSearch$Light});
													case 'book-print':
														return _Utils_update(
															model,
															{theme: $author$project$NethysSearch$Paper});
													case 'paper':
														return _Utils_update(
															model,
															{theme: $author$project$NethysSearch$Paper});
													case 'extra-contrast':
														return _Utils_update(
															model,
															{theme: $author$project$NethysSearch$ExtraContrast});
													case 'contrast-dark':
														return _Utils_update(
															model,
															{theme: $author$project$NethysSearch$ExtraContrast});
													case 'lavender':
														return _Utils_update(
															model,
															{theme: $author$project$NethysSearch$Lavender});
													case 'lavander':
														return _Utils_update(
															model,
															{theme: $author$project$NethysSearch$Lavender});
													default:
														break _v5$8;
												}
											} else {
												break _v5$8;
											}
										}
										return model;
									case 'limit-table-width':
										var _v6 = A2(
											$elm$json$Json$Decode$decodeValue,
											A2($elm$json$Json$Decode$field, 'value', $elm$json$Json$Decode$string),
											value);
										_v6$2:
										while (true) {
											if (_v6.$ === 'Ok') {
												switch (_v6.a) {
													case '1':
														return _Utils_update(
															model,
															{limitTableWidth: true});
													case '0':
														return _Utils_update(
															model,
															{limitTableWidth: false});
													default:
														break _v6$2;
												}
											} else {
												break _v6$2;
											}
										}
										return model;
									case 'show-additional-info':
										var _v7 = A2(
											$elm$json$Json$Decode$decodeValue,
											A2($elm$json$Json$Decode$field, 'value', $elm$json$Json$Decode$string),
											value);
										_v7$2:
										while (true) {
											if (_v7.$ === 'Ok') {
												switch (_v7.a) {
													case '1':
														return _Utils_update(
															model,
															{showResultAdditionalInfo: true});
													case '0':
														return _Utils_update(
															model,
															{showResultAdditionalInfo: false});
													default:
														break _v7$2;
												}
											} else {
												break _v7$2;
											}
										}
										return model;
									case 'show-spoilers':
										var _v8 = A2(
											$elm$json$Json$Decode$decodeValue,
											A2($elm$json$Json$Decode$field, 'value', $elm$json$Json$Decode$string),
											value);
										_v8$2:
										while (true) {
											if (_v8.$ === 'Ok') {
												switch (_v8.a) {
													case '1':
														return _Utils_update(
															model,
															{showResultSpoilers: true});
													case '0':
														return _Utils_update(
															model,
															{showResultSpoilers: false});
													default:
														break _v8$2;
												}
											} else {
												break _v8$2;
											}
										}
										return model;
									case 'show-traits':
										var _v9 = A2(
											$elm$json$Json$Decode$decodeValue,
											A2($elm$json$Json$Decode$field, 'value', $elm$json$Json$Decode$string),
											value);
										_v9$2:
										while (true) {
											if (_v9.$ === 'Ok') {
												switch (_v9.a) {
													case '1':
														return _Utils_update(
															model,
															{showResultTraits: true});
													case '0':
														return _Utils_update(
															model,
															{showResultTraits: false});
													default:
														break _v9$2;
												}
											} else {
												break _v9$2;
											}
										}
										return model;
									default:
										break _v4$5;
								}
							} else {
								break _v4$5;
							}
						}
						return model;
					}(),
					$elm$core$Platform$Cmd$none);
			case 'MenuOpenDelayPassed':
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{overlayActive: true}),
					$elm$core$Platform$Cmd$none);
			case 'NoOp':
				return _Utils_Tuple2(model, $elm$core$Platform$Cmd$none);
			case 'PfsFilterAdded':
				var pfs = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredPfs: A2($author$project$NethysSearch$toggleBoolDict, pfs, model.filteredPfs)
							})));
			case 'PfsFilterRemoved':
				var pfs = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredPfs: A2($elm$core$Dict$remove, pfs, model.filteredPfs)
							})));
			case 'QueryChanged':
				var str = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{debounce: model.debounce + 1, query: str}),
					A2(
						$elm$core$Task$perform,
						function (_v10) {
							return $author$project$NethysSearch$DebouncePassed(model.debounce + 1);
						},
						$elm$core$Process$sleep(250)));
			case 'QueryTypeSelected':
				var queryType = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{queryType: queryType})));
			case 'RemoveAllSortsPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{sort: _List_Nil})));
			case 'RemoveAllActionsFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredActions: $elm$core$Dict$empty})));
			case 'RemoveAllAlignmentFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredAlignments: $elm$core$Dict$empty})));
			case 'RemoveAllComponentFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredComponents: $elm$core$Dict$empty})));
			case 'RemoveAllCreatureFamilyFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredCreatureFamilies: $elm$core$Dict$empty})));
			case 'RemoveAllItemCategoryFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredItemCategories: $elm$core$Dict$empty})));
			case 'RemoveAllItemSubcategoryFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredItemSubcategories: $elm$core$Dict$empty})));
			case 'RemoveAllPfsFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredPfs: $elm$core$Dict$empty})));
			case 'RemoveAllSavingThrowFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredSavingThrows: $elm$core$Dict$empty})));
			case 'RemoveAllSchoolFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredSchools: $elm$core$Dict$empty})));
			case 'RemoveAllSizeFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredSizes: $elm$core$Dict$empty})));
			case 'RemoveAllSourceCategoryFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredSourceCategories: $elm$core$Dict$empty})));
			case 'RemoveAllSourceFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredSources: $elm$core$Dict$empty})));
			case 'RemoveAllStrongestSaveFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredStrongestSaves: $elm$core$Dict$empty})));
			case 'RemoveAllTraditionFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredTraditions: $elm$core$Dict$empty})));
			case 'RemoveAllTraitFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredTraits: $elm$core$Dict$empty})));
			case 'RemoveAllTypeFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredTypes: $elm$core$Dict$empty})));
			case 'RemoveAllValueFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredFromValues: $elm$core$Dict$empty, filteredToValues: $elm$core$Dict$empty})));
			case 'RemoveAllWeakestSaveFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredWeakestSaves: $elm$core$Dict$empty})));
			case 'RemoveAllWeaponCategoryFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredWeaponCategories: $elm$core$Dict$empty})));
			case 'RemoveAllWeaponGroupFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredWeaponGroups: $elm$core$Dict$empty})));
			case 'RemoveAllWeaponTypeFiltersPressed':
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{filteredWeaponTypes: $elm$core$Dict$empty})));
			case 'ResultDisplayChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					model,
					$elm$core$Platform$Cmd$batch(
						_List_fromArray(
							[
								$author$project$NethysSearch$updateUrl(
								_Utils_update(
									model,
									{resultDisplay: value})),
								$author$project$NethysSearch$getElementHeight($author$project$NethysSearch$resultDisplayMeasureWrapperId)
							])));
			case 'SavingThrowFilterAdded':
				var savingThrow = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSavingThrows: A2($author$project$NethysSearch$toggleBoolDict, savingThrow, model.filteredSavingThrows)
							})));
			case 'SavingThrowFilterRemoved':
				var savingThrow = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSavingThrows: A2($elm$core$Dict$remove, savingThrow, model.filteredSavingThrows)
							})));
			case 'SchoolFilterAdded':
				var school = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSchools: A2($author$project$NethysSearch$toggleBoolDict, school, model.filteredSchools)
							})));
			case 'SchoolFilterRemoved':
				var school = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSchools: A2($elm$core$Dict$remove, school, model.filteredSchools)
							})));
			case 'ScrollToTopPressed':
				return _Utils_Tuple2(
					model,
					A2(
						$elm$core$Task$perform,
						function (_v11) {
							return $author$project$NethysSearch$NoOp;
						},
						A2($elm$browser$Browser$Dom$setViewport, 0, 0)));
			case 'SearchCreatureFamiliesChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{searchCreatureFamilies: value}),
					$author$project$NethysSearch$getElementHeight($author$project$NethysSearch$filterCreaturesMeasureWrapperId));
			case 'SearchItemCategoriesChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{searchItemCategories: value}),
					$author$project$NethysSearch$getElementHeight($author$project$NethysSearch$filterItemCategoriesMeasureWrapperId));
			case 'SearchItemSubcategoriesChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{searchItemSubcategories: value}),
					$author$project$NethysSearch$getElementHeight($author$project$NethysSearch$filterItemCategoriesMeasureWrapperId));
			case 'SearchSourcesChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{searchSources: value}),
					$author$project$NethysSearch$getElementHeight($author$project$NethysSearch$filterSourcesMeasureWrapperId));
			case 'SearchTraitsChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{searchTraits: value}),
					$author$project$NethysSearch$getElementHeight($author$project$NethysSearch$filterTraitsMeasureWrapperId));
			case 'SearchTypesChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{searchTypes: value}),
					$author$project$NethysSearch$getElementHeight($author$project$NethysSearch$filterTypesMeasureWrapperId));
			case 'ShowAdditionalInfoChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showResultAdditionalInfo: value}),
					A2(
						$author$project$NethysSearch$saveToLocalStorage,
						'show-additional-info',
						value ? '1' : '0'));
			case 'ShowFoldableOptionBoxPressed':
				var id = msg.a;
				var show = msg.b;
				return show ? _Utils_Tuple2(
					model,
					$author$project$NethysSearch$getElementHeight(id)) : _Utils_Tuple2(
					_Utils_update(
						model,
						{
							elementHeights: A3($elm$core$Dict$insert, id, 0, model.elementHeights)
						}),
					$elm$core$Platform$Cmd$none);
			case 'ShowMenuPressed':
				var show = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{menuOpen: show, overlayActive: false}),
					show ? A2(
						$elm$core$Task$perform,
						function (_v12) {
							return $author$project$NethysSearch$MenuOpenDelayPassed;
						},
						$elm$core$Process$sleep(250)) : $elm$core$Platform$Cmd$none);
			case 'ShowQueryOptionsPressed':
				var show = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{queryOptionsOpen: show}),
					$author$project$NethysSearch$getElementHeight($author$project$NethysSearch$queryOptionsMeasureWrapperId));
			case 'ShowSpoilersChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showResultSpoilers: value}),
					A2(
						$author$project$NethysSearch$saveToLocalStorage,
						'show-spoilers',
						value ? '1' : '0'));
			case 'ShowTraitsChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{showResultTraits: value}),
					A2(
						$author$project$NethysSearch$saveToLocalStorage,
						'show-traits',
						value ? '1' : '0'));
			case 'SizeFilterAdded':
				var size = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSizes: A2($author$project$NethysSearch$toggleBoolDict, size, model.filteredSizes)
							})));
			case 'SizeFilterRemoved':
				var size = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSizes: A2($elm$core$Dict$remove, size, model.filteredSizes)
							})));
			case 'SortAbilityChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedSortAbility: value}),
					$elm$core$Platform$Cmd$none);
			case 'SortAdded':
				var field = msg.a;
				var dir = msg.b;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								sort: A2(
									$elm$core$List$any,
									A2(
										$elm$core$Basics$composeR,
										$elm$core$Tuple$first,
										$elm$core$Basics$eq(field)),
									model.sort) ? A3(
									$elm_community$list_extra$List$Extra$updateIf,
									A2(
										$elm$core$Basics$composeR,
										$elm$core$Tuple$first,
										$elm$core$Basics$eq(field)),
									$elm$core$Tuple$mapSecond(
										function (_v13) {
											return dir;
										}),
									model.sort) : A2(
									$elm$core$List$append,
									model.sort,
									_List_fromArray(
										[
											_Utils_Tuple2(field, dir)
										]))
							})));
			case 'SortOrderChanged':
				var oldIndex = msg.a;
				var newIndex = msg.b;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								sort: A3($elm_community$list_extra$List$Extra$swapAt, oldIndex, newIndex, model.sort)
							})));
			case 'SortRemoved':
				var field = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								sort: A2(
									$elm$core$List$filter,
									A2(
										$elm$core$Basics$composeR,
										$elm$core$Tuple$first,
										$elm$core$Basics$neq(field)),
									model.sort)
							})));
			case 'SortResistanceChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedSortResistance: value}),
					$elm$core$Platform$Cmd$none);
			case 'SortSetChosen':
				var fields = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{sort: fields})));
			case 'SortSpeedChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedSortSpeed: value}),
					$elm$core$Platform$Cmd$none);
			case 'SortToggled':
				var field = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								sort: function () {
									var _v14 = A2(
										$elm_community$list_extra$List$Extra$find,
										A2(
											$elm$core$Basics$composeR,
											$elm$core$Tuple$first,
											$elm$core$Basics$eq(field)),
										model.sort);
									if (_v14.$ === 'Just') {
										if (_v14.a.b.$ === 'Asc') {
											var _v15 = _v14.a;
											var _v16 = _v15.b;
											return function (list) {
												return A2(
													$elm$core$List$append,
													list,
													_List_fromArray(
														[
															_Utils_Tuple2(field, $author$project$NethysSearch$Desc)
														]));
											}(
												A2(
													$elm$core$List$filter,
													A2(
														$elm$core$Basics$composeR,
														$elm$core$Tuple$first,
														$elm$core$Basics$neq(field)),
													model.sort));
										} else {
											var _v17 = _v14.a;
											var _v18 = _v17.b;
											return A2(
												$elm$core$List$filter,
												A2(
													$elm$core$Basics$composeR,
													$elm$core$Tuple$first,
													$elm$core$Basics$neq(field)),
												model.sort);
										}
									} else {
										return A2(
											$elm$core$List$append,
											model.sort,
											_List_fromArray(
												[
													_Utils_Tuple2(field, $author$project$NethysSearch$Asc)
												]));
									}
								}()
							})));
			case 'SortWeaknessChanged':
				var value = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{selectedSortWeakness: value}),
					$elm$core$Platform$Cmd$none);
			case 'SourceCategoryFilterAdded':
				var category = msg.a;
				var newFilteredSourceCategories = A2($author$project$NethysSearch$toggleBoolDict, category, model.filteredSourceCategories);
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSourceCategories: newFilteredSourceCategories,
								filteredSources: function () {
									var _v19 = A2($elm$core$Dict$get, category, newFilteredSourceCategories);
									if (_v19.$ === 'Just') {
										if (_v19.a) {
											return A2(
												$elm$core$Dict$filter,
												F2(
													function (source, _v20) {
														return A2(
															$elm$core$List$member,
															source,
															A2(
																$elm$core$List$map,
																function ($) {
																	return $.name;
																},
																A2(
																	$elm$core$List$filter,
																	function (s) {
																		return A2(
																			$elm$core$List$member,
																			s.category,
																			$author$project$NethysSearch$boolDictIncluded(newFilteredSourceCategories));
																	},
																	A2(
																		$elm$core$Maybe$withDefault,
																		_List_Nil,
																		A2(
																			$elm$core$Maybe$map,
																			function ($) {
																				return $.sources;
																			},
																			A2($elm$core$Maybe$andThen, $elm$core$Result$toMaybe, model.aggregations))))));
													}),
												model.filteredSources);
										} else {
											return A2(
												$elm$core$Dict$filter,
												F2(
													function (source, _v21) {
														return !_Utils_eq(
															$elm$core$Maybe$Just(category),
															A2(
																$elm$core$Maybe$map,
																$elm$core$String$toLower,
																A2(
																	$elm$core$Maybe$map,
																	function ($) {
																		return $.category;
																	},
																	A2(
																		$elm$core$Maybe$andThen,
																		$elm_community$list_extra$List$Extra$find(
																			A2(
																				$elm$core$Basics$composeR,
																				function ($) {
																					return $.name;
																				},
																				$elm$core$Basics$eq(source))),
																		A2(
																			$elm$core$Maybe$map,
																			function ($) {
																				return $.sources;
																			},
																			A2($elm$core$Maybe$andThen, $elm$core$Result$toMaybe, model.aggregations))))));
													}),
												model.filteredSources);
										}
									} else {
										return model.filteredSources;
									}
								}()
							})));
			case 'SourceCategoryFilterRemoved':
				var category = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSourceCategories: A2($elm$core$Dict$remove, category, model.filteredSourceCategories)
							})));
			case 'SourceFilterAdded':
				var book = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSources: A2($author$project$NethysSearch$toggleBoolDict, book, model.filteredSources)
							})));
			case 'SourceFilterRemoved':
				var book = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredSources: A2($elm$core$Dict$remove, book, model.filteredSources)
							})));
			case 'StrongestSaveFilterAdded':
				var strongestSave = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredStrongestSaves: A2($author$project$NethysSearch$toggleBoolDict, strongestSave, model.filteredStrongestSaves)
							})));
			case 'StrongestSaveFilterRemoved':
				var strongestSave = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredStrongestSaves: A2($elm$core$Dict$remove, strongestSave, model.filteredStrongestSaves)
							})));
			case 'TableColumnAdded':
				var column = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								tableColumns: A2(
									$elm$core$List$append,
									model.tableColumns,
									_List_fromArray(
										[column]))
							})));
			case 'TableColumnMoved':
				var oldIndex = msg.a;
				var newIndex = msg.b;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								tableColumns: A3($elm_community$list_extra$List$Extra$swapAt, oldIndex, newIndex, model.tableColumns)
							})));
			case 'TableColumnRemoved':
				var column = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								tableColumns: A2(
									$elm$core$List$filter,
									$elm$core$Basics$neq(column),
									model.tableColumns)
							})));
			case 'TableColumnSetChosen':
				var columns = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{tableColumns: columns})));
			case 'ThemeSelected':
				var theme = msg.a;
				return _Utils_Tuple2(
					_Utils_update(
						model,
						{theme: theme}),
					A2(
						$author$project$NethysSearch$saveToLocalStorage,
						'theme',
						function () {
							switch (theme.$) {
								case 'Dark':
									return 'dark';
								case 'Light':
									return 'light';
								case 'Paper':
									return 'paper';
								case 'ExtraContrast':
									return 'extra-contrast';
								default:
									return 'lavender';
							}
						}()));
			case 'TraditionFilterAdded':
				var tradition = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredTraditions: A2($author$project$NethysSearch$toggleBoolDict, tradition, model.filteredTraditions)
							})));
			case 'TraditionFilterRemoved':
				var tradition = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredTraditions: A2($elm$core$Dict$remove, tradition, model.filteredTraditions)
							})));
			case 'TraitFilterAdded':
				var trait = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredTraits: A2($author$project$NethysSearch$toggleBoolDict, trait, model.filteredTraits)
							})));
			case 'TraitFilterRemoved':
				var trait = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredTraits: A2($elm$core$Dict$remove, trait, model.filteredTraits)
							})));
			case 'TypeFilterAdded':
				var type_ = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredTypes: A2($author$project$NethysSearch$toggleBoolDict, type_, model.filteredTypes)
							})));
			case 'TypeFilterRemoved':
				var type_ = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredTypes: A2($elm$core$Dict$remove, type_, model.filteredTypes)
							})));
			case 'UrlChanged':
				var url = msg.a;
				return $author$project$NethysSearch$updateTitle(
					A2(
						$author$project$NethysSearch$searchWithCurrentQuery,
						false,
						_Utils_Tuple2(
							A2(
								$author$project$NethysSearch$updateModelFromUrl,
								$author$project$NethysSearch$parseUrl(url),
								model),
							$elm$core$Platform$Cmd$none)));
			case 'UrlRequested':
				var urlRequest = msg.a;
				if (urlRequest.$ === 'Internal') {
					var url = urlRequest.a;
					return _Utils_Tuple2(
						model,
						$author$project$NethysSearch$navigation_pushUrl(
							$elm$url$Url$toString(url)));
				} else {
					var url = urlRequest.a;
					return _Utils_Tuple2(
						model,
						$author$project$NethysSearch$navigation_loadUrl(url));
				}
			case 'WeakestSaveFilterAdded':
				var weakestSave = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredWeakestSaves: A2($author$project$NethysSearch$toggleBoolDict, weakestSave, model.filteredWeakestSaves)
							})));
			case 'WeakestSaveFilterRemoved':
				var weakestSave = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredWeakestSaves: A2($elm$core$Dict$remove, weakestSave, model.filteredWeakestSaves)
							})));
			case 'WeaponCategoryFilterAdded':
				var category = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredWeaponCategories: A2($author$project$NethysSearch$toggleBoolDict, category, model.filteredWeaponCategories)
							})));
			case 'WeaponCategoryFilterRemoved':
				var category = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredWeaponCategories: A2($elm$core$Dict$remove, category, model.filteredWeaponCategories)
							})));
			case 'WeaponGroupFilterAdded':
				var group = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredWeaponGroups: A2($author$project$NethysSearch$toggleBoolDict, group, model.filteredWeaponGroups)
							})));
			case 'WeaponGroupFilterRemoved':
				var group = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredWeaponGroups: A2($elm$core$Dict$remove, group, model.filteredWeaponGroups)
							})));
			case 'WeaponTypeFilterAdded':
				var type_ = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredWeaponTypes: A2($author$project$NethysSearch$toggleBoolDict, type_, model.filteredWeaponTypes)
							})));
			case 'WeaponTypeFilterRemoved':
				var type_ = msg.a;
				return _Utils_Tuple2(
					model,
					$author$project$NethysSearch$updateUrl(
						_Utils_update(
							model,
							{
								filteredWeaponTypes: A2($elm$core$Dict$remove, type_, model.filteredWeaponTypes)
							})));
			default:
				var width = msg.a;
				var height = msg.b;
				return _Utils_Tuple2(
					model,
					$elm$core$Platform$Cmd$batch(
						A2(
							$elm$core$List$map,
							$author$project$NethysSearch$getElementHeight,
							A2(
								$elm$core$List$filter,
								function (id) {
									return !(!A2(
										$elm$core$Maybe$withDefault,
										0,
										A2($elm$core$Dict$get, id, model.elementHeights)));
								},
								$author$project$NethysSearch$measureWrapperIds))));
		}
	});
var $author$project$NethysSearch$ShowMenuPressed = function (a) {
	return {$: 'ShowMenuPressed', a: a};
};
var $elm$html$Html$Attributes$stringProperty = F2(
	function (key, string) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$string(string));
	});
var $elm$html$Html$Attributes$class = $elm$html$Html$Attributes$stringProperty('className');
var $elm$html$Html$Attributes$classList = function (classes) {
	return $elm$html$Html$Attributes$class(
		A2(
			$elm$core$String$join,
			' ',
			A2(
				$elm$core$List$map,
				$elm$core$Tuple$first,
				A2($elm$core$List$filter, $elm$core$Tuple$second, classes))));
};
var $elm_community$html_extra$Html$Attributes$Extra$empty = $elm$html$Html$Attributes$classList(_List_Nil);
var $elm_community$html_extra$Html$Attributes$Extra$attributeIf = F2(
	function (condition, attr) {
		return condition ? attr : $elm_community$html_extra$Html$Attributes$Extra$empty;
	});
var $lattyware$elm_fontawesome$FontAwesome$Icon$Icon = F5(
	function (prefix, name, width, height, paths) {
		return {height: height, name: name, paths: paths, prefix: prefix, width: width};
	});
var $lattyware$elm_fontawesome$FontAwesome$Solid$bars = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'bars',
	448,
	512,
	_List_fromArray(
		['M16 132h416c8.837 0 16-7.163 16-16V76c0-8.837-7.163-16-16-16H16C7.163 60 0 67.163 0 76v40c0 8.837 7.163 16 16 16zm0 160h416c8.837 0 16-7.163 16-16v-40c0-8.837-7.163-16-16-16H16c-8.837 0-16 7.163-16 16v40c0 8.837 7.163 16 16 16zm0 160h416c8.837 0 16-7.163 16-16v-40c0-8.837-7.163-16-16-16H16c-8.837 0-16 7.163-16 16v40c0 8.837 7.163 16 16 16z']));
var $elm$html$Html$button = _VirtualDom_node('button');
var $elm$virtual_dom$VirtualDom$node = function (tag) {
	return _VirtualDom_node(
		_VirtualDom_noScript(tag));
};
var $elm$html$Html$node = $elm$virtual_dom$VirtualDom$node;
var $elm$virtual_dom$VirtualDom$text = _VirtualDom_text;
var $elm$html$Html$text = $elm$virtual_dom$VirtualDom$text;
var $lattyware$elm_fontawesome$FontAwesome$Styles$css = A3(
	$elm$html$Html$node,
	'style',
	_List_Nil,
	_List_fromArray(
		[
			$elm$html$Html$text('svg:not(:root).svg-inline--fa {  overflow: visible;}.svg-inline--fa {  display: inline-block;  font-size: inherit;  height: 1em;  overflow: visible;  vertical-align: -0.125em;}.svg-inline--fa.fa-lg {  vertical-align: -0.225em;}.svg-inline--fa.fa-w-1 {  width: 0.0625em;}.svg-inline--fa.fa-w-2 {  width: 0.125em;}.svg-inline--fa.fa-w-3 {  width: 0.1875em;}.svg-inline--fa.fa-w-4 {  width: 0.25em;}.svg-inline--fa.fa-w-5 {  width: 0.3125em;}.svg-inline--fa.fa-w-6 {  width: 0.375em;}.svg-inline--fa.fa-w-7 {  width: 0.4375em;}.svg-inline--fa.fa-w-8 {  width: 0.5em;}.svg-inline--fa.fa-w-9 {  width: 0.5625em;}.svg-inline--fa.fa-w-10 {  width: 0.625em;}.svg-inline--fa.fa-w-11 {  width: 0.6875em;}.svg-inline--fa.fa-w-12 {  width: 0.75em;}.svg-inline--fa.fa-w-13 {  width: 0.8125em;}.svg-inline--fa.fa-w-14 {  width: 0.875em;}.svg-inline--fa.fa-w-15 {  width: 0.9375em;}.svg-inline--fa.fa-w-16 {  width: 1em;}.svg-inline--fa.fa-w-17 {  width: 1.0625em;}.svg-inline--fa.fa-w-18 {  width: 1.125em;}.svg-inline--fa.fa-w-19 {  width: 1.1875em;}.svg-inline--fa.fa-w-20 {  width: 1.25em;}.svg-inline--fa.fa-pull-left {  margin-right: 0.3em;  width: auto;}.svg-inline--fa.fa-pull-right {  margin-left: 0.3em;  width: auto;}.svg-inline--fa.fa-border {  height: 1.5em;}.svg-inline--fa.fa-li {  width: 2em;}.svg-inline--fa.fa-fw {  width: 1.25em;}.fa-layers svg.svg-inline--fa {  bottom: 0;  left: 0;  margin: auto;  position: absolute;  right: 0;  top: 0;}.fa-layers {  display: inline-block;  height: 1em;  position: relative;  text-align: center;  vertical-align: -0.125em;  width: 1em;}.fa-layers svg.svg-inline--fa {  -webkit-transform-origin: center center;          transform-origin: center center;}.fa-layers-counter, .fa-layers-text {  display: inline-block;  position: absolute;  text-align: center;}.fa-layers-text {  left: 50%;  top: 50%;  -webkit-transform: translate(-50%, -50%);          transform: translate(-50%, -50%);  -webkit-transform-origin: center center;          transform-origin: center center;}.fa-layers-counter {  background-color: #ff253a;  border-radius: 1em;  -webkit-box-sizing: border-box;          box-sizing: border-box;  color: #fff;  height: 1.5em;  line-height: 1;  max-width: 5em;  min-width: 1.5em;  overflow: hidden;  padding: 0.25em;  right: 0;  text-overflow: ellipsis;  top: 0;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: top right;          transform-origin: top right;}.fa-layers-bottom-right {  bottom: 0;  right: 0;  top: auto;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: bottom right;          transform-origin: bottom right;}.fa-layers-bottom-left {  bottom: 0;  left: 0;  right: auto;  top: auto;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: bottom left;          transform-origin: bottom left;}.fa-layers-top-right {  right: 0;  top: 0;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: top right;          transform-origin: top right;}.fa-layers-top-left {  left: 0;  right: auto;  top: 0;  -webkit-transform: scale(0.25);          transform: scale(0.25);  -webkit-transform-origin: top left;          transform-origin: top left;}.fa-lg {  font-size: 1.3333333333em;  line-height: 0.75em;  vertical-align: -0.0667em;}.fa-xs {  font-size: 0.75em;}.fa-sm {  font-size: 0.875em;}.fa-1x {  font-size: 1em;}.fa-2x {  font-size: 2em;}.fa-3x {  font-size: 3em;}.fa-4x {  font-size: 4em;}.fa-5x {  font-size: 5em;}.fa-6x {  font-size: 6em;}.fa-7x {  font-size: 7em;}.fa-8x {  font-size: 8em;}.fa-9x {  font-size: 9em;}.fa-10x {  font-size: 10em;}.fa-fw {  text-align: center;  width: 1.25em;}.fa-ul {  list-style-type: none;  margin-left: 2.5em;  padding-left: 0;}.fa-ul > li {  position: relative;}.fa-li {  left: -2em;  position: absolute;  text-align: center;  width: 2em;  line-height: inherit;}.fa-border {  border: solid 0.08em #eee;  border-radius: 0.1em;  padding: 0.2em 0.25em 0.15em;}.fa-pull-left {  float: left;}.fa-pull-right {  float: right;}.fa.fa-pull-left,.fas.fa-pull-left,.far.fa-pull-left,.fal.fa-pull-left,.fab.fa-pull-left {  margin-right: 0.3em;}.fa.fa-pull-right,.fas.fa-pull-right,.far.fa-pull-right,.fal.fa-pull-right,.fab.fa-pull-right {  margin-left: 0.3em;}.fa-spin {  -webkit-animation: fa-spin 2s infinite linear;          animation: fa-spin 2s infinite linear;}.fa-pulse {  -webkit-animation: fa-spin 1s infinite steps(8);          animation: fa-spin 1s infinite steps(8);}@-webkit-keyframes fa-spin {  0% {    -webkit-transform: rotate(0deg);            transform: rotate(0deg);  }  100% {    -webkit-transform: rotate(360deg);            transform: rotate(360deg);  }}@keyframes fa-spin {  0% {    -webkit-transform: rotate(0deg);            transform: rotate(0deg);  }  100% {    -webkit-transform: rotate(360deg);            transform: rotate(360deg);  }}.fa-rotate-90 {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=1)\";  -webkit-transform: rotate(90deg);          transform: rotate(90deg);}.fa-rotate-180 {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=2)\";  -webkit-transform: rotate(180deg);          transform: rotate(180deg);}.fa-rotate-270 {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=3)\";  -webkit-transform: rotate(270deg);          transform: rotate(270deg);}.fa-flip-horizontal {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=0, mirror=1)\";  -webkit-transform: scale(-1, 1);          transform: scale(-1, 1);}.fa-flip-vertical {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=2, mirror=1)\";  -webkit-transform: scale(1, -1);          transform: scale(1, -1);}.fa-flip-both, .fa-flip-horizontal.fa-flip-vertical {  -ms-filter: \"progid:DXImageTransform.Microsoft.BasicImage(rotation=2, mirror=1)\";  -webkit-transform: scale(-1, -1);          transform: scale(-1, -1);}:root .fa-rotate-90,:root .fa-rotate-180,:root .fa-rotate-270,:root .fa-flip-horizontal,:root .fa-flip-vertical,:root .fa-flip-both {  -webkit-filter: none;          filter: none;}.fa-stack {  display: inline-block;  height: 2em;  position: relative;  width: 2.5em;}.fa-stack-1x,.fa-stack-2x {  bottom: 0;  left: 0;  margin: auto;  position: absolute;  right: 0;  top: 0;}.svg-inline--fa.fa-stack-1x {  height: 1em;  width: 1.25em;}.svg-inline--fa.fa-stack-2x {  height: 2em;  width: 2.5em;}.fa-inverse {  color: #fff;}.sr-only {  border: 0;  clip: rect(0, 0, 0, 0);  height: 1px;  margin: -1px;  overflow: hidden;  padding: 0;  position: absolute;  width: 1px;}.sr-only-focusable:active, .sr-only-focusable:focus {  clip: auto;  height: auto;  margin: 0;  overflow: visible;  position: static;  width: auto;}.svg-inline--fa .fa-primary {  fill: var(--fa-primary-color, currentColor);  opacity: 1;  opacity: var(--fa-primary-opacity, 1);}.svg-inline--fa .fa-secondary {  fill: var(--fa-secondary-color, currentColor);  opacity: 0.4;  opacity: var(--fa-secondary-opacity, 0.4);}.svg-inline--fa.fa-swap-opacity .fa-primary {  opacity: 0.4;  opacity: var(--fa-secondary-opacity, 0.4);}.svg-inline--fa.fa-swap-opacity .fa-secondary {  opacity: 1;  opacity: var(--fa-primary-opacity, 1);}.svg-inline--fa mask .fa-primary,.svg-inline--fa mask .fa-secondary {  fill: black;}.fad.fa-inverse {  color: #fff;}')
		]));
var $author$project$NethysSearch$css = '\n    @font-face {\n        font-family: "Pathfinder-Icons";\n        src: url("Pathfinder-Icons.ttf");\n        font-display: swap;\n    }\n\n    body {\n        margin: 0px;\n    }\n\n    a {\n        color: inherit;\n    }\n\n    a:hover {\n        text-decoration: underline;\n    }\n\n    button {\n        border-color: var(--color-inactive-text);\n        border-width: 1px;\n        border-style: solid;\n        border-radius: 4px;\n        background-color: transparent;\n        color: var(--color-text);\n        font-size: var(--font-normal);\n    }\n\n    button.active {\n        background-color: var(--color-text);\n        color: var(--color-bg);\n    }\n\n    button.excluded, button:disabled {\n        color: var(--color-inactive-text);\n    }\n\n    button:hover:enabled {\n        border-color: var(--color-text);\n        text-decoration: underline;\n    }\n\n    h1 {\n        font-size: 48px;\n        font-weight: normal;\n        margin: 0;\n    }\n\n    h2 {\n        font-size: var(--font-very-large);\n        margin: 0;\n    }\n\n    h3 {\n        font-size: var(--font-large);\n        margin: 0;\n    }\n\n    h4 {\n        font-size: var(--font-medium);\n        margin: 0;\n    }\n\n    input[type=text], input[type=number] {\n        background-color: transparent;\n        border-width: 0;\n        color: var(--color-text);\n        padding: 4px;\n        flex-grow: 1;\n    }\n\n    input:invalid {\n        color: #ff8888;\n    }\n\n    input[type=number] {\n        width: 80px;\n    }\n\n    input:focus-visible {\n        border-width: 0;\n        border-style: none;\n        border-image: none;\n        outline: 0;\n    }\n\n    select {\n        color: var(--color-text);\n        font-size: var(--font-normal);\n    }\n\n    table {\n        border-collapse: separate;\n        border-spacing: 0;\n        color: var(--color-table-text);\n        position: relative;\n    }\n\n    tbody tr td {\n        background-color: var(--color-table-even);\n    }\n\n    tbody tr:nth-child(odd) td {\n        background-color: var(--color-table-odd);\n    }\n\n    td {\n        border-right: 1px solid var(--color-table-text);\n        border-bottom: 1px solid var(--color-table-text);\n        padding: 4px 12px 4px 4px;\n    }\n\n    th {\n        background-color: var(--color-element-bg);\n        border-top: 1px solid var(--color-table-text);\n        border-right: 1px solid var(--color-table-text);\n        border-bottom: 1px solid var(--color-table-text);\n        color: var(--color-element-text);\n        font-variant: small-caps;\n        font-size: var(--font-large);\n        font-weight: 700;\n        padding: 4px 12px 4px 4px;\n        position: sticky;\n        text-align: start;\n        top: 0px;\n    }\n\n    th button {\n        border: 0;\n        color: inherit;\n        font-size: inherit;\n        font-variant: inherit;\n        font-weight: inherit;\n        padding: 0;\n        text-align: inherit;\n    }\n\n    td:first-child, th:first-child {\n        border-left: 1px solid var(--color-table-text);\n    }\n\n    thead tr {\n        background-color: var(--color-element-bg);\n    }\n\n    .align-baseline {\n        align-items: baseline;\n    }\n\n    .align-center {\n        align-items: center;\n    }\n\n    .align-stretch {\n        align-items: stretch;\n    }\n\n    .body-container {\n        background-color: var(--color-bg);\n        color: var(--color-text);\n        font-family: "Century Gothic", CenturyGothic, AppleGothic, sans-serif;\n        font-size: var(--font-normal);\n        line-height: normal;\n        min-height: 100%;\n        min-width: 400px;\n        position: relative;\n        --font-normal: 16px;\n        --font-large: 20px;\n        --font-very-large: 24px;\n        --gap-tiny: 4px;\n        --gap-small: 8px;\n        --gap-medium: 12px;\n        --gap-large: 20px;\n    }\n\n    .bold {\n        font-weight: 700;\n    }\n\n    .column {\n        display: flex;\n        flex-direction: column;\n    }\n\n    .row {\n        display: flex;\n        flex-direction: row;\n        flex-wrap: wrap;\n    }\n\n    .grid {\n        display: grid;\n    }\n\n    .column:empty, .row:empty, .grid:empty {\n        display: none;\n    }\n\n    .fill-width-with-padding {\n        box-sizing: border-box;\n        padding-left: 8px;\n        padding-right: 8px;\n        width: 100%;\n    }\n\n    .filter-type {\n        border-radius: 4px;\n        border-width: 0;\n        background-color: var(--color-element-bg);\n        color: var(--color-element-text);\n        font-size: 16px;\n        font-variant: small-caps;\n        font-weight: 700;\n        padding: 4px 9px;\n    }\n\n    .filter-type.excluded {\n        background-color: var(--color-element-inactive-bg);\n        color: var(--color-element-inactive-text);\n    }\n\n    .gap-large {\n        gap: var(--gap-large);\n    }\n\n    .gap-medium {\n        gap: var(--gap-medium);\n    }\n\n    .gap-medium.row, .gap-large.row {\n        row-gap: var(--gap-tiny);\n    }\n\n    .gap-medium.grid, .gap-large.grid {\n        row-gap: var(--gap-small);\n    }\n\n    .gap-small {\n        gap: var(--gap-small);\n    }\n\n    .gap-tiny {\n        gap: var(--gap-tiny);\n    }\n\n    .grow {\n        flex-grow: 1;\n    }\n\n    .input-container {\n        background-color: var(--color-bg);\n        border-style: solid;\n        border-radius: 4px;\n        border-width: 2px;\n        border-color: #808080;\n    }\n\n    .input-container:focus-within {\n        border-color: var(--color-text);\n        outline: 0;\n    }\n\n    .icon-font {\n        color: var(--color-icon);\n        font-family: "Pathfinder-Icons";\n        font-variant-caps: normal;\n        font-weight: normal;\n    }\n\n    table .icon-font {\n        color: var(--color-table-text);\n    }\n\n    .input-button {\n        background-color: transparent;\n        border-width: 0;\n        color: var(--color-text);\n    }\n\n    .limit-width {\n        max-width: 1000px;\n    }\n\n    .menu {\n        align-self: flex-start;\n        background-color: var(--color-bg);\n        border-width: 0px 1px 1px 0px;\n        border-style: solid;\n        max-width: 400px;\n        padding: 8px;\n        position: absolute;\n        transition: transform ease-in-out 0.2s;\n        width: 85%;\n        z-index: 2;\n    }\n\n    .menu-close-button {\n        align-self: flex-end;\n        border: 0;\n        font-size: 32px;\n        margin-top: -8px;\n        padding: 8px;\n    }\n\n    .menu-open-button {\n        border: 0;\n        font-size: 32px;\n        left: 0;\n        padding: 8px;\n        position: absolute;\n    }\n\n    .menu-overlay {\n        background-color: #44444488;\n        height: 100%;\n        position: absolute;\n        transition: background-color ease-in-out 0.25s;\n        width: 100%;\n        z-index: 1;\n    }\n\n    .menu-overlay-hidden {\n        background-color: #44444400;\n        pointer-events: none;\n    }\n\n    .monospace {\n        background-color: var(--color-bg-secondary);\n        font-family: monospace;\n        font-size: var(--font-normal);\n    }\n\n    .nowrap {\n        flex-wrap: nowrap;\n    }\n\n    .option-container {\n        border-style: solid;\n        border-width: 1px;\n        background-color: var(--color-container-bg);\n        padding: 8px;\n    }\n\n    .query-input {\n        font-size: var(--font-very-large);\n    }\n\n    .foldable-container {\n        transition: height ease-in-out 0.2s;\n        overflow: hidden;\n    }\n\n    .rotatable {\n        transition: transform ease-in-out 0.2s\n    }\n\n    .rotate180 {\n        transform: rotate(-180deg);\n    }\n\n    .scrollbox {\n        background-color: var(--color-bg-secondary);\n        border-color: #767676;\n        border-radius: 4px;\n        border-style: solid;\n        border-width: 1px;\n        max-height: 200px;\n        overflow-y: auto;\n        padding: 4px;\n    }\n\n    .subtitle {\n        border-radius: 4px;\n        background-color: var(--color-subelement-bg);\n        color: var(--color-subelement-text);\n        font-variant: small-caps;\n        line-height: 1rem;\n        padding: 4px 9px;\n    }\n\n    .subtitle:empty {\n        display: none;\n    }\n\n    .sticky-left {\n        left: 0;\n        position: sticky;\n    }\n\n    .title {\n        border-radius: 4px;\n        background-color: var(--color-element-bg);\n        border-color: var(--color-container-border);\n        color: var(--color-element-text);\n        display: flex;\n        flex-direction: row;\n        font-size: var(--font-very-large);\n        font-variant: small-caps;\n        font-weight: 700;\n        gap: var(--gap-small);\n        justify-content: space-between;\n        padding: 4px 9px;\n    }\n\n    .title .icon-font {\n        color: var(--color-element-icon);\n    }\n\n    .title a {\n        text-decoration: none;\n    }\n\n    .title a:hover {\n        text-decoration: underline;\n    }\n\n    .title-type {\n        text-align: right;\n    }\n\n    .trait {\n        background-color: var(--color-element-bg);\n        border-color: var(--color-element-border);\n        border-style: double;\n        border-width: 2px;\n        color: #eeeeee;\n        padding: 3px 5px;\n        font-size: 16px;\n        font-variant: small-caps;\n        font-weight: 700;\n    }\n\n    .trait.excluded {\n        background-color: var(--color-element-inactive-bg);\n        border-color: var(--color-element-inactive-border);\n        color: var(--color-inactive-text);\n    }\n\n    .trait-alignment {\n        background-color: #4287f5;\n    }\n\n    .trait-rare {\n        background-color: #0c1466;\n    }\n\n    .trait-size {\n        background-color: #478c42;\n    }\n\n    .trait-uncommon {\n        background-color: #c45500;\n    }\n\n    .trait-unique {\n        background-color: #800080;\n    }\n\n    .loader {\n        width: 48px;\n        height: 48px;\n        border: 5px solid #FFF;\n        border-bottom-color: transparent;\n        border-radius: 50%;\n        display: inline-block;\n        box-sizing: border-box;\n        align-self: center;\n        animation: rotation 1s linear infinite;\n    }\n\n    @keyframes rotation {\n        0% {\n            transform: rotate(0deg);\n        }\n        100% {\n            transform: rotate(360deg);\n        }\n    }\n    ';
var $author$project$NethysSearch$cssDark = '\n    .body-container {\n        --color-bg: #111111;\n        --color-bg-secondary: #282828;\n        --color-container-bg: #333333;\n        --color-container-border: #eeeeee;\n        --color-element-bg: #522e2c;\n        --color-element-border: #d8c483;\n        --color-element-icon: #cccccc;\n        --color-element-inactive-bg: #291716;\n        --color-element-inactive-border: #6c6242;\n        --color-element-inactive-text: #656148;\n        --color-element-text: #cbc18f;\n        --color-subelement-bg: #806e45;\n        --color-subelement-text: #111111;\n        --color-icon: #cccccc;\n        --color-inactive-text: #999999;\n        --color-table-even: #64542f;\n        --color-table-odd: #342c19;\n        --color-table-text: #eeeeee;\n        --color-text: #eeeeee;\n    }\n    ';
var $author$project$NethysSearch$cssExtraContrast = '\n    .body-container {\n        --color-bg: #111111;\n        --color-bg-secondary: #282828;\n        --color-container-bg: #333333;\n        --color-container-border: #eeeeee;\n        --color-element-bg: #5d0000;\n        --color-element-border: #d8c483;\n        --color-element-icon: #cccccc;\n        --color-element-inactive-bg: #291716;\n        --color-element-inactive-border: #6c6242;\n        --color-element-inactive-text: #656148;\n        --color-element-text: #cbc18f;\n        --color-subelement-bg: #769477;\n        --color-subelement-text: #111111;\n        --color-icon: #cccccc;\n        --color-inactive-text: #999999;\n        --color-table-even: #ffffff;\n        --color-table-odd: #cccccc;\n        --color-table-text: #0f0f0f;\n        --color-text: #eeeeee;\n    }\n    ';
var $author$project$NethysSearch$cssLavender = '\n    .body-container {\n        --color-bg: #ffffff;\n        --color-bg-secondary: #cccccc;\n        --color-container-bg: #dddddd;\n        --color-container-border: #111111;\n        --color-element-bg: #493a88;\n        --color-element-border: #d8c483;\n        --color-element-icon: #cccccc;\n        --color-element-inactive-bg: #291716;\n        --color-element-inactive-border: #6c6242;\n        --color-element-inactive-text: #656148;\n        --color-element-text: #cbc18f;\n        --color-subelement-bg: #f0e6ff;\n        --color-subelement-text: #111111;\n        --color-icon: #000000;\n        --color-inactive-text: #999999;\n        --color-table-even: #8471a7;\n        --color-table-odd: #6f5f98;\n        --color-table-text: #ffffff;\n        --color-text: #000000;\n    }\n    ';
var $author$project$NethysSearch$cssLight = '\n    .body-container {\n        --color-bg: #eeeeee;\n        --color-bg-secondary: #cccccc;\n        --color-container-bg: #dddddd;\n        --color-container-border: #111111;\n        --color-element-bg: #6f413e;\n        --color-element-border: #d8c483;\n        --color-element-icon: #cccccc;\n        --color-element-inactive-bg: #462b29;\n        --color-element-inactive-border: #6c6242;\n        --color-element-inactive-text: #87805f;\n        --color-element-text: #cbc18f;\n        --color-subelement-bg: #cbc18f;\n        --color-subelement-text: #111111;\n        --color-icon: #111111;\n        --color-inactive-text: #999999;\n        --color-table-even: #cbc18f;\n        --color-table-odd: #ded7bb;\n        --color-table-text: #0f0f0f;\n        --color-text: #111111;\n    }\n    ';
var $author$project$NethysSearch$cssPaper = '\n    .body-container {\n        --color-bg: #f1ece5;\n        --color-bg-secondary: #cccccc;\n        --color-container-bg: #dddddd;\n        --color-container-border: #111111;\n        --color-element-bg: #5d0000;\n        --color-element-border: #d8c483;\n        --color-element-icon: #111111;\n        --color-element-inactive-bg: #3e0000;\n        --color-element-inactive-border: #48412c;\n        --color-element-inactive-text: #87805f;\n        --color-element-text: #cbc18f;\n        --color-subelement-bg: #dbd0bc;\n        --color-subelement-text: #111111;\n        --color-icon: #111111;\n        --color-inactive-text: #999999;\n        --color-table-even: #ede3c7;\n        --color-table-odd: #f4eee0;\n        --color-table-text: #0f0f0f;\n        --color-text: #111111;\n    }\n    ';
var $elm$html$Html$div = _VirtualDom_node('div');
var $elm$virtual_dom$VirtualDom$Normal = function (a) {
	return {$: 'Normal', a: a};
};
var $elm$virtual_dom$VirtualDom$on = _VirtualDom_on;
var $elm$html$Html$Events$on = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$Normal(decoder));
	});
var $elm$html$Html$Events$onClick = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'click',
		$elm$json$Json$Decode$succeed(msg));
};
var $elm$html$Html$Events$onMouseOver = function (msg) {
	return A2(
		$elm$html$Html$Events$on,
		'mouseover',
		$elm$json$Json$Decode$succeed(msg));
};
var $lattyware$elm_fontawesome$FontAwesome$Icon$Presentation = function (a) {
	return {$: 'Presentation', a: a};
};
var $lattyware$elm_fontawesome$FontAwesome$Icon$present = function (icon) {
	return $lattyware$elm_fontawesome$FontAwesome$Icon$Presentation(
		{attributes: _List_Nil, icon: icon, id: $elm$core$Maybe$Nothing, outer: $elm$core$Maybe$Nothing, role: 'img', title: $elm$core$Maybe$Nothing, transforms: _List_Nil});
};
var $elm$virtual_dom$VirtualDom$attribute = F2(
	function (key, value) {
		return A2(
			_VirtualDom_attribute,
			_VirtualDom_noOnOrFormAction(key),
			_VirtualDom_noJavaScriptOrHtmlUri(value));
	});
var $elm$html$Html$Attributes$attribute = $elm$virtual_dom$VirtualDom$attribute;
var $elm$svg$Svg$Attributes$class = _VirtualDom_attribute('class');
var $elm$core$Basics$negate = function (n) {
	return -n;
};
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$add = F2(
	function (transform, combined) {
		switch (transform.$) {
			case 'Scale':
				var direction = transform.a;
				var amount = function () {
					if (direction.$ === 'Grow') {
						var by = direction.a;
						return by;
					} else {
						var by = direction.a;
						return -by;
					}
				}();
				return _Utils_update(
					combined,
					{size: combined.size + amount});
			case 'Reposition':
				var direction = transform.a;
				var _v2 = function () {
					switch (direction.$) {
						case 'Up':
							var by = direction.a;
							return _Utils_Tuple2(0, -by);
						case 'Down':
							var by = direction.a;
							return _Utils_Tuple2(0, by);
						case 'Left':
							var by = direction.a;
							return _Utils_Tuple2(-by, 0);
						default:
							var by = direction.a;
							return _Utils_Tuple2(by, 0);
					}
				}();
				var x = _v2.a;
				var y = _v2.b;
				return _Utils_update(
					combined,
					{x: combined.x + x, y: combined.y + y});
			case 'Rotate':
				var rotation = transform.a;
				return _Utils_update(
					combined,
					{rotate: combined.rotate + rotation});
			default:
				if (transform.a.$ === 'Vertical') {
					var _v4 = transform.a;
					return _Utils_update(
						combined,
						{flipX: true});
				} else {
					var _v5 = transform.a;
					return _Utils_update(
						combined,
						{flipY: true});
				}
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize = 16;
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform = {flipX: false, flipY: false, rotate: 0, size: $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize, x: 0, y: 0};
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$combine = function (transforms) {
	return A3($elm$core$List$foldl, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$add, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform, transforms);
};
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaningfulTransform = function (transforms) {
	var combined = $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$combine(transforms);
	return _Utils_eq(combined, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(combined);
};
var $elm$svg$Svg$trustedNode = _VirtualDom_nodeNS('http://www.w3.org/2000/svg');
var $elm$svg$Svg$svg = $elm$svg$Svg$trustedNode('svg');
var $elm$svg$Svg$Attributes$id = _VirtualDom_attribute('id');
var $elm$svg$Svg$text = $elm$virtual_dom$VirtualDom$text;
var $elm$svg$Svg$title = $elm$svg$Svg$trustedNode('title');
var $lattyware$elm_fontawesome$FontAwesome$Icon$titledContents = F3(
	function (titleId, contents, title) {
		return A2(
			$elm$core$List$cons,
			A2(
				$elm$svg$Svg$title,
				_List_fromArray(
					[
						$elm$svg$Svg$Attributes$id(titleId)
					]),
				_List_fromArray(
					[
						$elm$svg$Svg$text(title)
					])),
			contents);
	});
var $elm$core$String$fromFloat = _String_fromNumber;
var $elm$svg$Svg$Attributes$transform = _VirtualDom_attribute('transform');
var $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$transformForSvg = F3(
	function (containerWidth, iconWidth, transform) {
		var path = 'translate(' + ($elm$core$String$fromFloat((iconWidth / 2) * (-1)) + ' -256)');
		var outer = 'translate(' + ($elm$core$String$fromFloat(containerWidth / 2) + ' 256)');
		var innerTranslate = 'translate(' + ($elm$core$String$fromFloat(transform.x * 32) + (',' + ($elm$core$String$fromFloat(transform.y * 32) + ') ')));
		var innerRotate = 'rotate(' + ($elm$core$String$fromFloat(transform.rotate) + ' 0 0)');
		var flipY = transform.flipY ? (-1) : 1;
		var scaleY = (transform.size / $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize) * flipY;
		var flipX = transform.flipX ? (-1) : 1;
		var scaleX = (transform.size / $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$baseSize) * flipX;
		var innerScale = 'scale(' + ($elm$core$String$fromFloat(scaleX) + (', ' + ($elm$core$String$fromFloat(scaleY) + ') ')));
		return {
			inner: $elm$svg$Svg$Attributes$transform(
				_Utils_ap(
					innerTranslate,
					_Utils_ap(innerScale, innerRotate))),
			outer: $elm$svg$Svg$Attributes$transform(outer),
			path: $elm$svg$Svg$Attributes$transform(path)
		};
	});
var $elm$svg$Svg$Attributes$viewBox = _VirtualDom_attribute('viewBox');
var $elm$svg$Svg$Attributes$height = _VirtualDom_attribute('height');
var $elm$svg$Svg$Attributes$width = _VirtualDom_attribute('width');
var $elm$svg$Svg$Attributes$x = _VirtualDom_attribute('x');
var $elm$svg$Svg$Attributes$y = _VirtualDom_attribute('y');
var $lattyware$elm_fontawesome$FontAwesome$Icon$allSpace = _List_fromArray(
	[
		$elm$svg$Svg$Attributes$x('0'),
		$elm$svg$Svg$Attributes$y('0'),
		$elm$svg$Svg$Attributes$width('100%'),
		$elm$svg$Svg$Attributes$height('100%')
	]);
var $elm$svg$Svg$clipPath = $elm$svg$Svg$trustedNode('clipPath');
var $elm$svg$Svg$Attributes$clipPath = _VirtualDom_attribute('clip-path');
var $elm$svg$Svg$Attributes$d = _VirtualDom_attribute('d');
var $elm$svg$Svg$Attributes$fill = _VirtualDom_attribute('fill');
var $elm$svg$Svg$path = $elm$svg$Svg$trustedNode('path');
var $lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath = F2(
	function (attrs, d) {
		return A2(
			$elm$svg$Svg$path,
			A2(
				$elm$core$List$cons,
				$elm$svg$Svg$Attributes$fill('currentColor'),
				A2(
					$elm$core$List$cons,
					$elm$svg$Svg$Attributes$d(d),
					attrs)),
			_List_Nil);
	});
var $elm$svg$Svg$g = $elm$svg$Svg$trustedNode('g');
var $lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths = F2(
	function (attrs, icon) {
		var _v0 = icon.paths;
		if (!_v0.b) {
			return A2($lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath, attrs, '');
		} else {
			if (!_v0.b.b) {
				var only = _v0.a;
				return A2($lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath, attrs, only);
			} else {
				var secondary = _v0.a;
				var _v1 = _v0.b;
				var primary = _v1.a;
				return A2(
					$elm$svg$Svg$g,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$class('fa-group')
						]),
					_List_fromArray(
						[
							A2(
							$lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath,
							A2(
								$elm$core$List$cons,
								$elm$svg$Svg$Attributes$class('fa-secondary'),
								attrs),
							secondary),
							A2(
							$lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePath,
							A2(
								$elm$core$List$cons,
								$elm$svg$Svg$Attributes$class('fa-primary'),
								attrs),
							primary)
						]));
			}
		}
	});
var $elm$svg$Svg$defs = $elm$svg$Svg$trustedNode('defs');
var $elm$svg$Svg$mask = $elm$svg$Svg$trustedNode('mask');
var $elm$svg$Svg$Attributes$mask = _VirtualDom_attribute('mask');
var $elm$svg$Svg$Attributes$maskContentUnits = _VirtualDom_attribute('maskContentUnits');
var $elm$svg$Svg$Attributes$maskUnits = _VirtualDom_attribute('maskUnits');
var $elm$svg$Svg$rect = $elm$svg$Svg$trustedNode('rect');
var $lattyware$elm_fontawesome$FontAwesome$Icon$viewMaskedWithTransform = F4(
	function (id, transforms, inner, outer) {
		var maskInnerGroup = A2(
			$elm$svg$Svg$g,
			_List_fromArray(
				[transforms.inner]),
			_List_fromArray(
				[
					A2(
					$lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$fill('black'),
							transforms.path
						]),
					inner)
				]));
		var maskId = 'mask-' + (inner.name + ('-' + id));
		var maskTag = A2(
			$elm$svg$Svg$mask,
			_Utils_ap(
				_List_fromArray(
					[
						$elm$svg$Svg$Attributes$id(maskId),
						$elm$svg$Svg$Attributes$maskUnits('userSpaceOnUse'),
						$elm$svg$Svg$Attributes$maskContentUnits('userSpaceOnUse')
					]),
				$lattyware$elm_fontawesome$FontAwesome$Icon$allSpace),
			_List_fromArray(
				[
					A2(
					$elm$svg$Svg$rect,
					A2(
						$elm$core$List$cons,
						$elm$svg$Svg$Attributes$fill('white'),
						$lattyware$elm_fontawesome$FontAwesome$Icon$allSpace),
					_List_Nil),
					A2(
					$elm$svg$Svg$g,
					_List_fromArray(
						[transforms.outer]),
					_List_fromArray(
						[maskInnerGroup]))
				]));
		var clipId = 'clip-' + (outer.name + ('-' + id));
		var defs = A2(
			$elm$svg$Svg$defs,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$svg$Svg$clipPath,
					_List_fromArray(
						[
							$elm$svg$Svg$Attributes$id(clipId)
						]),
					_List_fromArray(
						[
							A2($lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths, _List_Nil, outer)
						])),
					maskTag
				]));
		return _List_fromArray(
			[
				defs,
				A2(
				$elm$svg$Svg$rect,
				$elm$core$List$concat(
					_List_fromArray(
						[
							_List_fromArray(
							[
								$elm$svg$Svg$Attributes$fill('currentColor'),
								$elm$svg$Svg$Attributes$clipPath('url(#' + (clipId + ')')),
								$elm$svg$Svg$Attributes$mask('url(#' + (maskId + ')'))
							]),
							$lattyware$elm_fontawesome$FontAwesome$Icon$allSpace
						])),
				_List_Nil)
			]);
	});
var $lattyware$elm_fontawesome$FontAwesome$Icon$viewWithTransform = F2(
	function (transforms, icon) {
		if (transforms.$ === 'Just') {
			var ts = transforms.a;
			return A2(
				$elm$svg$Svg$g,
				_List_fromArray(
					[ts.outer]),
				_List_fromArray(
					[
						A2(
						$elm$svg$Svg$g,
						_List_fromArray(
							[ts.inner]),
						_List_fromArray(
							[
								A2(
								$lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths,
								_List_fromArray(
									[ts.path]),
								icon)
							]))
					]));
		} else {
			return A2($lattyware$elm_fontawesome$FontAwesome$Svg$Internal$corePaths, _List_Nil, icon);
		}
	});
var $lattyware$elm_fontawesome$FontAwesome$Icon$internalView = function (_v0) {
	var icon = _v0.a.icon;
	var attributes = _v0.a.attributes;
	var transforms = _v0.a.transforms;
	var role = _v0.a.role;
	var id = _v0.a.id;
	var title = _v0.a.title;
	var outer = _v0.a.outer;
	var alwaysId = A2($elm$core$Maybe$withDefault, icon.name, id);
	var titleId = alwaysId + '-title';
	var semantics = A2(
		$elm$core$Maybe$withDefault,
		A2($elm$html$Html$Attributes$attribute, 'aria-hidden', 'true'),
		A2(
			$elm$core$Maybe$map,
			$elm$core$Basics$always(
				A2($elm$html$Html$Attributes$attribute, 'aria-labelledby', titleId)),
			title));
	var _v1 = A2(
		$elm$core$Maybe$withDefault,
		_Utils_Tuple2(icon.width, icon.height),
		A2(
			$elm$core$Maybe$map,
			function (o) {
				return _Utils_Tuple2(o.width, o.height);
			},
			outer));
	var width = _v1.a;
	var height = _v1.b;
	var classes = _List_fromArray(
		[
			'svg-inline--fa',
			'fa-' + icon.name,
			'fa-w-' + $elm$core$String$fromInt(
			$elm$core$Basics$ceiling((width / height) * 16))
		]);
	var svgTransform = A2(
		$elm$core$Maybe$map,
		A2($lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$transformForSvg, width, icon.width),
		$lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaningfulTransform(transforms));
	var contents = function () {
		var resolvedSvgTransform = A2(
			$elm$core$Maybe$withDefault,
			A3($lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$transformForSvg, width, icon.width, $lattyware$elm_fontawesome$FontAwesome$Transforms$Internal$meaninglessTransform),
			svgTransform);
		return A2(
			$elm$core$Maybe$withDefault,
			_List_fromArray(
				[
					A2($lattyware$elm_fontawesome$FontAwesome$Icon$viewWithTransform, svgTransform, icon)
				]),
			A2(
				$elm$core$Maybe$map,
				A3($lattyware$elm_fontawesome$FontAwesome$Icon$viewMaskedWithTransform, alwaysId, resolvedSvgTransform, icon),
				outer));
	}();
	var potentiallyTitledContents = A2(
		$elm$core$Maybe$withDefault,
		contents,
		A2(
			$elm$core$Maybe$map,
			A2($lattyware$elm_fontawesome$FontAwesome$Icon$titledContents, titleId, contents),
			title));
	return A2(
		$elm$svg$Svg$svg,
		$elm$core$List$concat(
			_List_fromArray(
				[
					_List_fromArray(
					[
						A2($elm$html$Html$Attributes$attribute, 'role', role),
						A2($elm$html$Html$Attributes$attribute, 'xmlns', 'http://www.w3.org/2000/svg'),
						$elm$svg$Svg$Attributes$viewBox(
						'0 0 ' + ($elm$core$String$fromInt(width) + (' ' + $elm$core$String$fromInt(height)))),
						semantics
					]),
					A2($elm$core$List$map, $elm$svg$Svg$Attributes$class, classes),
					attributes
				])),
		potentiallyTitledContents);
};
var $lattyware$elm_fontawesome$FontAwesome$Icon$view = function (presentation) {
	return $lattyware$elm_fontawesome$FontAwesome$Icon$internalView(presentation);
};
var $lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon = A2($elm$core$Basics$composeR, $lattyware$elm_fontawesome$FontAwesome$Icon$present, $lattyware$elm_fontawesome$FontAwesome$Icon$view);
var $author$project$NethysSearch$ThemeSelected = function (a) {
	return {$: 'ThemeSelected', a: a};
};
var $elm$html$Html$a = _VirtualDom_node('a');
var $elm$html$Html$h2 = _VirtualDom_node('h2');
var $elm$html$Html$h3 = _VirtualDom_node('h3');
var $elm$html$Html$Attributes$href = function (url) {
	return A2(
		$elm$html$Html$Attributes$stringProperty,
		'href',
		_VirtualDom_noJavaScriptUri(url));
};
var $elm$html$Html$section = _VirtualDom_node('section');
var $elm$virtual_dom$VirtualDom$style = _VirtualDom_style;
var $elm$html$Html$Attributes$style = $elm$virtual_dom$VirtualDom$style;
var $elm$html$Html$Attributes$target = $elm$html$Html$Attributes$stringProperty('target');
var $lattyware$elm_fontawesome$FontAwesome$Solid$times = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'times',
	352,
	512,
	_List_fromArray(
		['M242.72 256l100.07-100.07c12.28-12.28 12.28-32.19 0-44.48l-22.24-22.24c-12.28-12.28-32.19-12.28-44.48 0L176 189.28 75.93 89.21c-12.28-12.28-32.19-12.28-44.48 0L9.21 111.45c-12.28 12.28-12.28 32.19 0 44.48L109.28 256 9.21 356.07c-12.28 12.28-12.28 32.19 0 44.48l22.24 22.24c12.28 12.28 32.2 12.28 44.48 0L176 322.72l100.07 100.07c12.28 12.28 32.2 12.28 44.48 0l22.24-22.24c12.28-12.28 12.28-32.19 0-44.48L242.72 256z']));
var $author$project$NethysSearch$viewFaq = F2(
	function (question, answer) {
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('column'),
					$elm$html$Html$Attributes$class('gap-tiny')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$h3,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('subtitle')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(question)
						])),
					A2($elm$html$Html$div, _List_Nil, answer)
				]));
	});
var $elm$json$Json$Encode$bool = _Json_wrap;
var $elm$html$Html$Attributes$boolProperty = F2(
	function (key, bool) {
		return A2(
			_VirtualDom_property,
			key,
			$elm$json$Json$Encode$bool(bool));
	});
var $elm$html$Html$Attributes$checked = $elm$html$Html$Attributes$boolProperty('checked');
var $elm$html$Html$input = _VirtualDom_node('input');
var $elm$html$Html$label = _VirtualDom_node('label');
var $elm$html$Html$Attributes$name = $elm$html$Html$Attributes$stringProperty('name');
var $elm$html$Html$Attributes$type_ = $elm$html$Html$Attributes$stringProperty('type');
var $author$project$NethysSearch$viewRadioButton = function (_v0) {
	var checked = _v0.checked;
	var name = _v0.name;
	var onInput = _v0.onInput;
	var text = _v0.text;
	return A2(
		$elm$html$Html$label,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('row'),
				$elm$html$Html$Attributes$class('align-baseline')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$input,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$type_('radio'),
						$elm$html$Html$Attributes$checked(checked),
						$elm$html$Html$Attributes$name(name),
						$elm$html$Html$Events$onClick(onInput)
					]),
				_List_Nil),
				A2(
				$elm$html$Html$div,
				_List_Nil,
				_List_fromArray(
					[
						$elm$html$Html$text(text)
					]))
			]));
};
var $author$project$NethysSearch$viewMenu = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('menu'),
				$elm$html$Html$Attributes$class('column'),
				A2(
				$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
				!model.menuOpen,
				A2($elm$html$Html$Attributes$style, 'transform', 'translate(-100%, 0px)'))
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$button,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('menu-close-button'),
						$elm$html$Html$Events$onClick(
						$author$project$NethysSearch$ShowMenuPressed(false)),
						A2(
						$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
						model.overlayActive,
						$elm$html$Html$Events$onMouseOver(
							$author$project$NethysSearch$ShowMenuPressed(false)))
					]),
				_List_fromArray(
					[
						$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
					])),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('column'),
						$elm$html$Html$Attributes$class('gap-large')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$section,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('column'),
								$elm$html$Html$Attributes$class('gap-medium')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$h2,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('title')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Options')
									])),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('column'),
										$elm$html$Html$Attributes$class('gap-tiny')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$h3,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('subtitle')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Theme')
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										_List_fromArray(
											[
												$author$project$NethysSearch$viewRadioButton(
												{
													checked: _Utils_eq(model.theme, $author$project$NethysSearch$Dark),
													name: 'theme-type',
													onInput: $author$project$NethysSearch$ThemeSelected($author$project$NethysSearch$Dark),
													text: 'Dark'
												}),
												$author$project$NethysSearch$viewRadioButton(
												{
													checked: _Utils_eq(model.theme, $author$project$NethysSearch$Light),
													name: 'theme-type',
													onInput: $author$project$NethysSearch$ThemeSelected($author$project$NethysSearch$Light),
													text: 'Light'
												}),
												$author$project$NethysSearch$viewRadioButton(
												{
													checked: _Utils_eq(model.theme, $author$project$NethysSearch$Paper),
													name: 'theme-type',
													onInput: $author$project$NethysSearch$ThemeSelected($author$project$NethysSearch$Paper),
													text: 'Paper'
												}),
												$author$project$NethysSearch$viewRadioButton(
												{
													checked: _Utils_eq(model.theme, $author$project$NethysSearch$ExtraContrast),
													name: 'theme-type',
													onInput: $author$project$NethysSearch$ThemeSelected($author$project$NethysSearch$ExtraContrast),
													text: 'Extra Contrast'
												}),
												$author$project$NethysSearch$viewRadioButton(
												{
													checked: _Utils_eq(model.theme, $author$project$NethysSearch$Lavender),
													name: 'theme-type',
													onInput: $author$project$NethysSearch$ThemeSelected($author$project$NethysSearch$Lavender),
													text: 'Lavender'
												})
											]))
									]))
							])),
						A2(
						$elm$html$Html$section,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('column'),
								$elm$html$Html$Attributes$class('gap-medium')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$h2,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('title')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('About / F.A.Q.')
									])),
								A2(
								$author$project$NethysSearch$viewFaq,
								'What is this?',
								_List_fromArray(
									[
										$elm$html$Html$text('A search engine that searches '),
										A2(
										$elm$html$Html$a,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$href('https://2e.aonprd.com/'),
												$elm$html$Html$Attributes$target('_blank')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Archives of Nethys')
											])),
										$elm$html$Html$text(', the System Reference Document for Pathfinder Second Edition.')
									])),
								A2(
								$author$project$NethysSearch$viewFaq,
								'How can I contact you?',
								_List_fromArray(
									[
										$elm$html$Html$text('You can send me an email (nethys-search <at> galdiuz.com), message me on Discord (Galdiuz#7937), or '),
										A2(
										$elm$html$Html$a,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$href('https://github.com/galdiuz/nethys-search/issues'),
												$elm$html$Html$Attributes$target('_blank')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('submit an issue on GitHub')
											])),
										$elm$html$Html$text('.')
									]))
							]))
					]))
			]));
};
var $author$project$NethysSearch$QueryChanged = function (a) {
	return {$: 'QueryChanged', a: a};
};
var $author$project$NethysSearch$QueryTypeSelected = function (a) {
	return {$: 'QueryTypeSelected', a: a};
};
var $author$project$NethysSearch$ShowQueryOptionsPressed = function (a) {
	return {$: 'ShowQueryOptionsPressed', a: a};
};
var $author$project$NethysSearch$SortRemoved = function (a) {
	return {$: 'SortRemoved', a: a};
};
var $elm$html$Html$Attributes$autofocus = $elm$html$Html$Attributes$boolProperty('autofocus');
var $lattyware$elm_fontawesome$FontAwesome$Solid$chevronDown = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'chevron-down',
	448,
	512,
	_List_fromArray(
		['M207.029 381.476L12.686 187.132c-9.373-9.373-9.373-24.569 0-33.941l22.667-22.667c9.357-9.357 24.522-9.375 33.901-.04L224 284.505l154.745-154.021c9.379-9.335 24.544-9.317 33.901.04l22.667 22.667c9.373 9.373 9.373 24.569 0 33.941L240.971 381.476c-9.373 9.372-24.569 9.372-33.942 0z']));
var $lattyware$elm_fontawesome$FontAwesome$Solid$chevronUp = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'chevron-up',
	448,
	512,
	_List_fromArray(
		['M240.971 130.524l194.343 194.343c9.373 9.373 9.373 24.569 0 33.941l-22.667 22.667c-9.357 9.357-24.522 9.375-33.901.04L224 227.495 69.255 381.516c-9.379 9.335-24.544 9.317-33.901-.04l-22.667-22.667c-9.373-9.373-9.373-24.569 0-33.941L207.03 130.525c9.372-9.373 24.568-9.373 33.941-.001z']));
var $lattyware$elm_fontawesome$FontAwesome$Solid$exclamation = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'exclamation',
	192,
	512,
	_List_fromArray(
		['M176 432c0 44.112-35.888 80-80 80s-80-35.888-80-80 35.888-80 80-80 80 35.888 80 80zM25.26 25.199l13.6 272C39.499 309.972 50.041 320 62.83 320h66.34c12.789 0 23.331-10.028 23.97-22.801l13.6-272C167.425 11.49 156.496 0 142.77 0H49.23C35.504 0 24.575 11.49 25.26 25.199z']));
var $elm$core$List$sum = function (numbers) {
	return A3($elm$core$List$foldl, $elm$core$Basics$add, 0, numbers);
};
var $author$project$NethysSearch$getQueryOptionsHeight = function (model) {
	return $elm$core$List$sum(
		A2(
			$elm$core$List$map,
			$elm$core$Maybe$withDefault(0),
			A2(
				$elm$core$List$map,
				function (id) {
					return A2($elm$core$Dict$get, id, model.elementHeights);
				},
				$author$project$NethysSearch$measureWrapperIds)));
};
var $lattyware$elm_fontawesome$FontAwesome$Solid$sortAlphaDownAlt = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'sort-alpha-down-alt',
	448,
	512,
	_List_fromArray(
		['M176 352h-48V48a16 16 0 0 0-16-16H80a16 16 0 0 0-16 16v304H16c-14.19 0-21.36 17.24-11.29 27.31l80 96a16 16 0 0 0 22.62 0l80-96C197.35 369.26 190.22 352 176 352zm112-128h128a16 16 0 0 0 16-16v-32a16 16 0 0 0-16-16h-56l61.26-70.45A32 32 0 0 0 432 65.63V48a16 16 0 0 0-16-16H288a16 16 0 0 0-16 16v32a16 16 0 0 0 16 16h56l-61.26 70.45A32 32 0 0 0 272 190.37V208a16 16 0 0 0 16 16zm159.06 234.62l-59.27-160A16 16 0 0 0 372.72 288h-41.44a16 16 0 0 0-15.07 10.62l-59.27 160A16 16 0 0 0 272 480h24.83a16 16 0 0 0 15.23-11.08l4.42-12.92h71l4.41 12.92A16 16 0 0 0 407.16 480H432a16 16 0 0 0 15.06-21.38zM335.61 400L352 352l16.39 48z']));
var $lattyware$elm_fontawesome$FontAwesome$Solid$sortAlphaUp = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'sort-alpha-up',
	448,
	512,
	_List_fromArray(
		['M16 160h48v304a16 16 0 0 0 16 16h32a16 16 0 0 0 16-16V160h48c14.21 0 21.38-17.24 11.31-27.31l-80-96a16 16 0 0 0-22.62 0l-80 96C-5.35 142.74 1.78 160 16 160zm400 128H288a16 16 0 0 0-16 16v32a16 16 0 0 0 16 16h56l-61.26 70.45A32 32 0 0 0 272 446.37V464a16 16 0 0 0 16 16h128a16 16 0 0 0 16-16v-32a16 16 0 0 0-16-16h-56l61.26-70.45A32 32 0 0 0 432 321.63V304a16 16 0 0 0-16-16zm31.06-85.38l-59.27-160A16 16 0 0 0 372.72 32h-41.44a16 16 0 0 0-15.07 10.62l-59.27 160A16 16 0 0 0 272 224h24.83a16 16 0 0 0 15.23-11.08l4.42-12.92h71l4.41 12.92A16 16 0 0 0 407.16 224H432a16 16 0 0 0 15.06-21.38zM335.61 144L352 96l16.39 48z']));
var $lattyware$elm_fontawesome$FontAwesome$Solid$sortNumericDownAlt = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'sort-numeric-down-alt',
	448,
	512,
	_List_fromArray(
		['M176 352h-48V48a16 16 0 0 0-16-16H80a16 16 0 0 0-16 16v304H16c-14.19 0-21.36 17.24-11.29 27.31l80 96a16 16 0 0 0 22.62 0l80-96C197.35 369.26 190.22 352 176 352zm224 64h-16V304a16 16 0 0 0-16-16h-48a16 16 0 0 0-14.29 8.83l-16 32A16 16 0 0 0 304 352h16v64h-16a16 16 0 0 0-16 16v32a16 16 0 0 0 16 16h96a16 16 0 0 0 16-16v-32a16 16 0 0 0-16-16zM330.17 34.91a79 79 0 0 0-55 54.17c-14.27 51.05 21.19 97.77 68.83 102.53a84.07 84.07 0 0 1-20.85 12.91c-7.57 3.4-10.8 12.47-8.18 20.34l9.9 20c2.87 8.63 12.53 13.49 20.9 9.91 58-24.77 86.25-61.61 86.25-132V112c-.02-51.21-48.4-91.34-101.85-77.09zM352 132a20 20 0 1 1 20-20 20 20 0 0 1-20 20z']));
var $lattyware$elm_fontawesome$FontAwesome$Solid$sortNumericUp = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'sort-numeric-up',
	448,
	512,
	_List_fromArray(
		['M330.17 258.91a79 79 0 0 0-55 54.17c-14.27 51.05 21.19 97.77 68.83 102.53a84.07 84.07 0 0 1-20.85 12.91c-7.57 3.4-10.8 12.47-8.18 20.34l9.9 20c2.87 8.63 12.53 13.49 20.9 9.91 58-24.76 86.25-61.61 86.25-132V336c-.02-51.21-48.4-91.34-101.85-77.09zM352 356a20 20 0 1 1 20-20 20 20 0 0 1-20 20zM304 96h16v64h-16a16 16 0 0 0-16 16v32a16 16 0 0 0 16 16h96a16 16 0 0 0 16-16v-32a16 16 0 0 0-16-16h-16V48a16 16 0 0 0-16-16h-48a16 16 0 0 0-14.29 8.83l-16 32A16 16 0 0 0 304 96zM107.31 36.69a16 16 0 0 0-22.62 0l-80 96C-5.35 142.74 1.78 160 16 160h48v304a16 16 0 0 0 16 16h32a16 16 0 0 0 16-16V160h48c14.21 0 21.38-17.24 11.31-27.31z']));
var $author$project$NethysSearch$getSortIcon = F2(
	function (field, dir) {
		var _v0 = _Utils_Tuple2(
			dir,
			A2(
				$elm_community$list_extra$List$Extra$find,
				A2(
					$elm$core$Basics$composeR,
					$TSFoster$elm_tuple_extra$Tuple3$first,
					$elm$core$Basics$eq(field)),
				$author$project$Data$sortFields));
		_v0$4:
		while (true) {
			if (_v0.a.$ === 'Just') {
				if (_v0.a.a.$ === 'Asc') {
					if (_v0.b.$ === 'Just') {
						if (_v0.b.a.c) {
							var _v1 = _v0.a.a;
							var _v2 = _v0.b.a;
							return $lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$sortNumericUp);
						} else {
							var _v3 = _v0.a.a;
							var _v4 = _v0.b.a;
							return $lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$sortAlphaUp);
						}
					} else {
						break _v0$4;
					}
				} else {
					if (_v0.b.$ === 'Just') {
						if (_v0.b.a.c) {
							var _v5 = _v0.a.a;
							var _v6 = _v0.b.a;
							return $lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$sortNumericDownAlt);
						} else {
							var _v7 = _v0.a.a;
							var _v8 = _v0.b.a;
							return $lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$sortAlphaDownAlt);
						}
					} else {
						break _v0$4;
					}
				}
			} else {
				break _v0$4;
			}
		}
		return $elm$html$Html$text('');
	});
var $elm$html$Html$Attributes$id = $elm$html$Html$Attributes$stringProperty('id');
var $elm$html$Html$Events$alwaysStop = function (x) {
	return _Utils_Tuple2(x, true);
};
var $elm$virtual_dom$VirtualDom$MayStopPropagation = function (a) {
	return {$: 'MayStopPropagation', a: a};
};
var $elm$html$Html$Events$stopPropagationOn = F2(
	function (event, decoder) {
		return A2(
			$elm$virtual_dom$VirtualDom$on,
			event,
			$elm$virtual_dom$VirtualDom$MayStopPropagation(decoder));
	});
var $elm$html$Html$Events$targetValue = A2(
	$elm$json$Json$Decode$at,
	_List_fromArray(
		['target', 'value']),
	$elm$json$Json$Decode$string);
var $elm$html$Html$Events$onInput = function (tagger) {
	return A2(
		$elm$html$Html$Events$stopPropagationOn,
		'input',
		A2(
			$elm$json$Json$Decode$map,
			$elm$html$Html$Events$alwaysStop,
			A2($elm$json$Json$Decode$map, tagger, $elm$html$Html$Events$targetValue)));
};
var $elm$html$Html$Attributes$placeholder = $elm$html$Html$Attributes$stringProperty('placeholder');
var $elm$core$String$any = _String_any;
var $elm$core$String$fromChar = function (_char) {
	return A2($elm$core$String$cons, _char, '');
};
var $author$project$NethysSearch$stringContainsChar = F2(
	function (str, chars) {
		return A2(
			$elm$core$String$any,
			function (_char) {
				return A2(
					$elm$core$String$contains,
					$elm$core$String$fromChar(_char),
					str);
			},
			chars);
	});
var $elm$html$Html$Attributes$value = $elm$html$Html$Attributes$stringProperty('value');
var $author$project$NethysSearch$ActionsFilterRemoved = function (a) {
	return {$: 'ActionsFilterRemoved', a: a};
};
var $author$project$NethysSearch$AlignmentFilterRemoved = function (a) {
	return {$: 'AlignmentFilterRemoved', a: a};
};
var $author$project$NethysSearch$ComponentFilterRemoved = function (a) {
	return {$: 'ComponentFilterRemoved', a: a};
};
var $author$project$NethysSearch$CreatureFamilyFilterRemoved = function (a) {
	return {$: 'CreatureFamilyFilterRemoved', a: a};
};
var $author$project$NethysSearch$FilterSpoilersChanged = function (a) {
	return {$: 'FilterSpoilersChanged', a: a};
};
var $author$project$NethysSearch$FilteredFromValueChanged = F2(
	function (a, b) {
		return {$: 'FilteredFromValueChanged', a: a, b: b};
	});
var $author$project$NethysSearch$FilteredToValueChanged = F2(
	function (a, b) {
		return {$: 'FilteredToValueChanged', a: a, b: b};
	});
var $author$project$NethysSearch$ItemCategoryFilterRemoved = function (a) {
	return {$: 'ItemCategoryFilterRemoved', a: a};
};
var $author$project$NethysSearch$ItemSubcategoryFilterRemoved = function (a) {
	return {$: 'ItemSubcategoryFilterRemoved', a: a};
};
var $author$project$NethysSearch$PfsFilterRemoved = function (a) {
	return {$: 'PfsFilterRemoved', a: a};
};
var $author$project$NethysSearch$SavingThrowFilterRemoved = function (a) {
	return {$: 'SavingThrowFilterRemoved', a: a};
};
var $author$project$NethysSearch$SchoolFilterRemoved = function (a) {
	return {$: 'SchoolFilterRemoved', a: a};
};
var $author$project$NethysSearch$SizeFilterRemoved = function (a) {
	return {$: 'SizeFilterRemoved', a: a};
};
var $author$project$NethysSearch$SourceCategoryFilterRemoved = function (a) {
	return {$: 'SourceCategoryFilterRemoved', a: a};
};
var $author$project$NethysSearch$SourceFilterRemoved = function (a) {
	return {$: 'SourceFilterRemoved', a: a};
};
var $author$project$NethysSearch$StrongestSaveFilterRemoved = function (a) {
	return {$: 'StrongestSaveFilterRemoved', a: a};
};
var $author$project$NethysSearch$TraditionFilterRemoved = function (a) {
	return {$: 'TraditionFilterRemoved', a: a};
};
var $author$project$NethysSearch$TraitFilterRemoved = function (a) {
	return {$: 'TraitFilterRemoved', a: a};
};
var $author$project$NethysSearch$TypeFilterRemoved = function (a) {
	return {$: 'TypeFilterRemoved', a: a};
};
var $author$project$NethysSearch$WeakestSaveFilterRemoved = function (a) {
	return {$: 'WeakestSaveFilterRemoved', a: a};
};
var $author$project$NethysSearch$WeaponCategoryFilterRemoved = function (a) {
	return {$: 'WeaponCategoryFilterRemoved', a: a};
};
var $author$project$NethysSearch$WeaponGroupFilterRemoved = function (a) {
	return {$: 'WeaponGroupFilterRemoved', a: a};
};
var $author$project$NethysSearch$WeaponTypeFilterRemoved = function (a) {
	return {$: 'WeaponTypeFilterRemoved', a: a};
};
var $elm_community$html_extra$Html$Attributes$Extra$attributeMaybe = function (fn) {
	return A2(
		$elm$core$Basics$composeR,
		$elm$core$Maybe$map(fn),
		$elm$core$Maybe$withDefault($elm_community$html_extra$Html$Attributes$Extra$empty));
};
var $author$project$NethysSearch$getTraitClass = function (trait) {
	var _v0 = $elm$core$String$toLower(trait);
	switch (_v0) {
		case 'uncommon':
			return $elm$html$Html$Attributes$class('trait-uncommon');
		case 'rare':
			return $elm$html$Html$Attributes$class('trait-rare');
		case 'unique':
			return $elm$html$Html$Attributes$class('trait-unique');
		case 'tiny':
			return $elm$html$Html$Attributes$class('trait-size');
		case 'small':
			return $elm$html$Html$Attributes$class('trait-size');
		case 'medium':
			return $elm$html$Html$Attributes$class('trait-size');
		case 'large':
			return $elm$html$Html$Attributes$class('trait-size');
		case 'huge':
			return $elm$html$Html$Attributes$class('trait-size');
		case 'gargantuan':
			return $elm$html$Html$Attributes$class('trait-size');
		case 'no alignment':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'lg':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'ln':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'le':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'ng':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'n':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'ne':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'cg':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'cn':
			return $elm$html$Html$Attributes$class('trait-alignment');
		case 'ce':
			return $elm$html$Html$Attributes$class('trait-alignment');
		default:
			return $elm_community$html_extra$Html$Attributes$Extra$empty;
	}
};
var $author$project$NethysSearch$sortFieldSuffix = function (field) {
	switch (field) {
		case 'price':
			return 'cp';
		case 'range':
			return 'ft.';
		default:
			return '';
	}
};
var $author$project$NethysSearch$sortFieldToLabel = function (field) {
	return $elm_community$string_extra$String$Extra$humanize(
		A2(
			$elm$core$String$join,
			' ',
			$elm$core$List$reverse(
				A2($elm$core$String$split, '.', field))));
};
var $elm_community$string_extra$String$Extra$toTitleCase = function (ws) {
	var uppercaseMatch = A2(
		$elm$regex$Regex$replace,
		$elm_community$string_extra$String$Extra$regexFromString('\\w+'),
		A2(
			$elm$core$Basics$composeR,
			function ($) {
				return $.match;
			},
			$elm_community$string_extra$String$Extra$toSentenceCase));
	return A3(
		$elm$regex$Regex$replace,
		$elm_community$string_extra$String$Extra$regexFromString('^([a-z])|\\s+([a-z])'),
		A2(
			$elm$core$Basics$composeR,
			function ($) {
				return $.match;
			},
			uppercaseMatch),
		ws);
};
var $elm$svg$Svg$Attributes$points = _VirtualDom_attribute('points');
var $elm$svg$Svg$polygon = $elm$svg$Svg$trustedNode('polygon');
var $author$project$NethysSearch$viewPfsLimited = A2(
	$elm$svg$Svg$svg,
	_List_fromArray(
		[
			$elm$svg$Svg$Attributes$viewBox('0 0 100 100'),
			$elm$svg$Svg$Attributes$height('1em')
		]),
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$rect,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$height('80'),
					$elm$svg$Svg$Attributes$width('90'),
					$elm$svg$Svg$Attributes$fill('#ecef23'),
					$elm$svg$Svg$Attributes$x('5'),
					$elm$svg$Svg$Attributes$y('15')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$polygon,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$points('15,100 25,50 50,0 75,50 85,100'),
					$elm$svg$Svg$Attributes$fill('#476468')
				]),
			_List_Nil)
		]));
var $elm$svg$Svg$circle = $elm$svg$Svg$trustedNode('circle');
var $elm$svg$Svg$Attributes$cx = _VirtualDom_attribute('cx');
var $elm$svg$Svg$Attributes$cy = _VirtualDom_attribute('cy');
var $elm$svg$Svg$line = $elm$svg$Svg$trustedNode('line');
var $elm$svg$Svg$Attributes$r = _VirtualDom_attribute('r');
var $elm$svg$Svg$Attributes$stroke = _VirtualDom_attribute('stroke');
var $elm$svg$Svg$Attributes$strokeWidth = _VirtualDom_attribute('stroke-width');
var $elm$svg$Svg$Attributes$x1 = _VirtualDom_attribute('x1');
var $elm$svg$Svg$Attributes$x2 = _VirtualDom_attribute('x2');
var $elm$svg$Svg$Attributes$y1 = _VirtualDom_attribute('y1');
var $elm$svg$Svg$Attributes$y2 = _VirtualDom_attribute('y2');
var $author$project$NethysSearch$viewPfsRestricted = A2(
	$elm$svg$Svg$svg,
	_List_fromArray(
		[
			$elm$svg$Svg$Attributes$viewBox('0 0 100 100'),
			$elm$svg$Svg$Attributes$height('1em')
		]),
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$x2('90'),
					$elm$svg$Svg$Attributes$y1('10'),
					$elm$svg$Svg$Attributes$y2('90'),
					$elm$svg$Svg$Attributes$strokeWidth('30'),
					$elm$svg$Svg$Attributes$stroke('#e81d1d')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$line,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$x1('10'),
					$elm$svg$Svg$Attributes$x2('90'),
					$elm$svg$Svg$Attributes$y1('90'),
					$elm$svg$Svg$Attributes$y2('10'),
					$elm$svg$Svg$Attributes$strokeWidth('30'),
					$elm$svg$Svg$Attributes$stroke('#e81d1d')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('50'),
					$elm$svg$Svg$Attributes$cy('50'),
					$elm$svg$Svg$Attributes$r('35'),
					$elm$svg$Svg$Attributes$fill('#dddddd')
				]),
			_List_Nil)
		]));
var $author$project$NethysSearch$viewPfsStandard = A2(
	$elm$svg$Svg$svg,
	_List_fromArray(
		[
			$elm$svg$Svg$Attributes$viewBox('0 0 100 100'),
			$elm$svg$Svg$Attributes$height('1em')
		]),
	_List_fromArray(
		[
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('50'),
					$elm$svg$Svg$Attributes$cy('50'),
					$elm$svg$Svg$Attributes$r('50'),
					$elm$svg$Svg$Attributes$fill('#4ab5f1')
				]),
			_List_Nil),
			A2(
			$elm$svg$Svg$circle,
			_List_fromArray(
				[
					$elm$svg$Svg$Attributes$cx('50'),
					$elm$svg$Svg$Attributes$cy('50'),
					$elm$svg$Svg$Attributes$r('40'),
					$elm$svg$Svg$Attributes$fill('#94805d')
				]),
			_List_Nil)
		]));
var $author$project$NethysSearch$viewPfsIcon = function (pfs) {
	var _v0 = $elm$core$String$toLower(pfs);
	switch (_v0) {
		case 'standard':
			return $author$project$NethysSearch$viewPfsStandard;
		case 'limited':
			return $author$project$NethysSearch$viewPfsLimited;
		case 'restricted':
			return $author$project$NethysSearch$viewPfsRestricted;
		default:
			return $elm$html$Html$text('');
	}
};
var $elm$html$Html$span = _VirtualDom_node('span');
var $author$project$NethysSearch$replaceActionLigatures = F3(
	function (text, _v0, rem) {
		replaceActionLigatures:
		while (true) {
			var find = _v0.a;
			var replace = _v0.b;
			if (A2(
				$elm$core$String$contains,
				find,
				$elm$core$String$toLower(text))) {
				var _v1 = A2(
					$elm$core$String$split,
					find,
					$elm$core$String$toLower(text));
				if (_v1.b) {
					var before = _v1.a;
					var after = _v1.b;
					return A2(
						$elm$core$List$append,
						_List_fromArray(
							[
								$elm$html$Html$text(before),
								A2(
								$elm$html$Html$span,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('icon-font')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(replace)
									]))
							]),
						A3(
							$author$project$NethysSearch$replaceActionLigatures,
							A2($elm$core$String$join, find, after),
							_Utils_Tuple2(find, replace),
							rem));
				} else {
					return _List_fromArray(
						[
							$elm$html$Html$text(text)
						]);
				}
			} else {
				if (rem.b) {
					var next = rem.a;
					var remNext = rem.b;
					var $temp$text = text,
						$temp$_v0 = next,
						$temp$rem = remNext;
					text = $temp$text;
					_v0 = $temp$_v0;
					rem = $temp$rem;
					continue replaceActionLigatures;
				} else {
					return _List_fromArray(
						[
							$elm$html$Html$text(text)
						]);
				}
			}
		}
	});
var $author$project$NethysSearch$viewTextWithActionIcons = function (text) {
	return A2(
		$elm$html$Html$span,
		_List_Nil,
		A3(
			$author$project$NethysSearch$replaceActionLigatures,
			text,
			_Utils_Tuple2('single action', '[one-action]'),
			_List_fromArray(
				[
					_Utils_Tuple2('two actions', '[two-actions]'),
					_Utils_Tuple2('three actions', '[three-actions]'),
					_Utils_Tuple2('reaction', '[reaction]'),
					_Utils_Tuple2('free action', '[free-action]')
				])));
};
var $author$project$NethysSearch$viewFilters = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('row'),
				$elm$html$Html$Attributes$class('gap-medium'),
				$elm$html$Html$Attributes$class('align-center')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('gap-medium'),
						$elm$html$Html$Attributes$class('align-center')
					]),
				A2(
					$elm$core$List$map,
					function (_v0) {
						var _class = _v0._class;
						var label = _v0.label;
						var list = _v0.list;
						var removeMsg = _v0.removeMsg;
						return $elm$core$List$isEmpty(list) ? $elm$html$Html$text('') : A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('row'),
									$elm$html$Html$Attributes$class('gap-tiny'),
									$elm$html$Html$Attributes$class('align-center')
								]),
							A2(
								$elm$core$List$append,
								_List_fromArray(
									[
										$elm$html$Html$text(label)
									]),
								A2(
									$elm$core$List$map,
									function (value) {
										return A2(
											$elm$html$Html$button,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('gap-tiny'),
													A2($elm_community$html_extra$Html$Attributes$Extra$attributeMaybe, $elm$html$Html$Attributes$class, _class),
													$author$project$NethysSearch$getTraitClass(value),
													$elm$html$Html$Events$onClick(
													removeMsg(value))
												]),
											_List_fromArray(
												[
													$author$project$NethysSearch$viewPfsIcon(value),
													$author$project$NethysSearch$viewTextWithActionIcons(
													$elm_community$string_extra$String$Extra$toTitleCase(value))
												]));
									},
									list)));
					},
					_List_fromArray(
						[
							{
							_class: $elm$core$Maybe$Just('trait'),
							label: model.filterTraitsOperator ? 'Include all traits:' : 'Include any trait:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredTraits),
							removeMsg: $author$project$NethysSearch$TraitFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('trait'),
							label: 'Exclude traits:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredTraits),
							removeMsg: $author$project$NethysSearch$TraitFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('filter-type'),
							label: 'Include types:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredTypes),
							removeMsg: $author$project$NethysSearch$TypeFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('filter-type'),
							label: 'Exclude types:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredTypes),
							removeMsg: $author$project$NethysSearch$TypeFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: model.filterTraditionsOperator ? 'Include all traditions:' : 'Include any tradition:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredTraditions),
							removeMsg: $author$project$NethysSearch$TraditionFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude traditions:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredTraditions),
							removeMsg: $author$project$NethysSearch$TraditionFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include actions:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredActions),
							removeMsg: $author$project$NethysSearch$ActionsFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude actions:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredActions),
							removeMsg: $author$project$NethysSearch$ActionsFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('trait trait-alignment'),
							label: 'Include alignments:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredAlignments),
							removeMsg: $author$project$NethysSearch$AlignmentFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('trait trait-alignment'),
							label: 'Exclude alignments:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredAlignments),
							removeMsg: $author$project$NethysSearch$AlignmentFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: model.filterComponentsOperator ? 'Include all components:' : 'Include any component:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredComponents),
							removeMsg: $author$project$NethysSearch$ComponentFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude components:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredComponents),
							removeMsg: $author$project$NethysSearch$ComponentFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include creature families:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredCreatureFamilies),
							removeMsg: $author$project$NethysSearch$CreatureFamilyFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude creature families:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredCreatureFamilies),
							removeMsg: $author$project$NethysSearch$CreatureFamilyFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include item categories:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredItemCategories),
							removeMsg: $author$project$NethysSearch$ItemCategoryFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude item categories:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredItemCategories),
							removeMsg: $author$project$NethysSearch$ItemCategoryFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include item subcategories:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredItemSubcategories),
							removeMsg: $author$project$NethysSearch$ItemSubcategoryFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude item subcategories:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredItemSubcategories),
							removeMsg: $author$project$NethysSearch$ItemSubcategoryFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include PFS:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredPfs),
							removeMsg: $author$project$NethysSearch$PfsFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude PFS:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredPfs),
							removeMsg: $author$project$NethysSearch$PfsFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include saving throws:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredSavingThrows),
							removeMsg: $author$project$NethysSearch$SavingThrowFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude saving throws:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredSavingThrows),
							removeMsg: $author$project$NethysSearch$SavingThrowFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('trait'),
							label: 'Include schools:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredSchools),
							removeMsg: $author$project$NethysSearch$SchoolFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('trait'),
							label: 'Exclude schools:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredSchools),
							removeMsg: $author$project$NethysSearch$SchoolFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('trait trait-size'),
							label: 'Include sizes:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredSizes),
							removeMsg: $author$project$NethysSearch$SizeFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Just('trait trait-size'),
							label: 'Exclude sizes:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredSizes),
							removeMsg: $author$project$NethysSearch$SizeFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include sources:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredSources),
							removeMsg: $author$project$NethysSearch$SourceFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude sources:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredSources),
							removeMsg: $author$project$NethysSearch$SourceFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include source categories:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredSourceCategories),
							removeMsg: $author$project$NethysSearch$SourceCategoryFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude source categories:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredSourceCategories),
							removeMsg: $author$project$NethysSearch$SourceCategoryFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include strongest saves:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredStrongestSaves),
							removeMsg: $author$project$NethysSearch$StrongestSaveFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude strongest saves:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredStrongestSaves),
							removeMsg: $author$project$NethysSearch$StrongestSaveFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include weakest saves:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredWeakestSaves),
							removeMsg: $author$project$NethysSearch$WeakestSaveFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude weakest saves:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredWeakestSaves),
							removeMsg: $author$project$NethysSearch$WeakestSaveFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include weapon categories:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredWeaponCategories),
							removeMsg: $author$project$NethysSearch$WeaponCategoryFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude weapon categories:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredWeaponCategories),
							removeMsg: $author$project$NethysSearch$WeaponCategoryFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include weapon groups:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredWeaponGroups),
							removeMsg: $author$project$NethysSearch$WeaponGroupFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude weapon groups:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredWeaponGroups),
							removeMsg: $author$project$NethysSearch$WeaponGroupFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Include weapon types:',
							list: $author$project$NethysSearch$boolDictIncluded(model.filteredWeaponTypes),
							removeMsg: $author$project$NethysSearch$WeaponTypeFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Exclude weapon types:',
							list: $author$project$NethysSearch$boolDictExcluded(model.filteredWeaponTypes),
							removeMsg: $author$project$NethysSearch$WeaponTypeFilterRemoved
						},
							{
							_class: $elm$core$Maybe$Nothing,
							label: 'Spoilers:',
							list: model.filterSpoilers ? _List_fromArray(
								['Hide spoilers']) : _List_Nil,
							removeMsg: function (_v1) {
								return $author$project$NethysSearch$FilterSpoilersChanged(false);
							}
						}
						]))),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('gap-medium'),
						$elm$html$Html$Attributes$class('align-baseline')
					]),
				A2(
					$elm$core$List$map,
					function (_v2) {
						var field = _v2.a;
						var maybeFrom = _v2.b;
						var maybeTo = _v2.c;
						return A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('row'),
									$elm$html$Html$Attributes$class('gap-tiny'),
									$elm$html$Html$Attributes$class('align-baseline')
								]),
							_List_fromArray(
								[
									$elm$html$Html$text(
									$author$project$NethysSearch$sortFieldToLabel(field) + ':'),
									A2(
									$elm$core$Maybe$withDefault,
									$elm$html$Html$text(''),
									A2(
										$elm$core$Maybe$map,
										function (from) {
											return A2(
												$elm$html$Html$button,
												_List_fromArray(
													[
														$elm$html$Html$Events$onClick(
														A2($author$project$NethysSearch$FilteredFromValueChanged, field, ''))
													]),
												_List_fromArray(
													[
														$elm$html$Html$text(
														'at least ' + (from + (' ' + $author$project$NethysSearch$sortFieldSuffix(field))))
													]));
										},
										maybeFrom)),
									A2(
									$elm$core$Maybe$withDefault,
									$elm$html$Html$text(''),
									A2(
										$elm$core$Maybe$map,
										function (to) {
											return A2(
												$elm$html$Html$button,
												_List_fromArray(
													[
														$elm$html$Html$Events$onClick(
														A2($author$project$NethysSearch$FilteredToValueChanged, field, ''))
													]),
												_List_fromArray(
													[
														$elm$html$Html$text(
														'up to ' + (to + (' ' + $author$project$NethysSearch$sortFieldSuffix(field))))
													]));
										},
										maybeTo))
								]));
					},
					A6(
						$elm$core$Dict$merge,
						F2(
							function (field, from) {
								return $elm$core$List$cons(
									_Utils_Tuple3(
										field,
										$elm$core$Maybe$Just(from),
										$elm$core$Maybe$Nothing));
							}),
						F3(
							function (field, from, to) {
								return $elm$core$List$cons(
									_Utils_Tuple3(
										field,
										$elm$core$Maybe$Just(from),
										$elm$core$Maybe$Just(to)));
							}),
						F2(
							function (field, to) {
								return $elm$core$List$cons(
									_Utils_Tuple3(
										field,
										$elm$core$Maybe$Nothing,
										$elm$core$Maybe$Just(to)));
							}),
						model.filteredFromValues,
						model.filteredToValues,
						_List_Nil)))
			]));
};
var $author$project$NethysSearch$AlignmentFilterAdded = function (a) {
	return {$: 'AlignmentFilterAdded', a: a};
};
var $author$project$NethysSearch$RemoveAllAlignmentFiltersPressed = {$: 'RemoveAllAlignmentFiltersPressed'};
var $author$project$Data$alignments = _List_fromArray(
	[
		_Utils_Tuple2('ce', 'Chaotic Evil'),
		_Utils_Tuple2('cg', 'Chaotic Good'),
		_Utils_Tuple2('cn', 'Chaotic Neutral'),
		_Utils_Tuple2('le', 'Lawful Evil'),
		_Utils_Tuple2('lg', 'Lawful Good'),
		_Utils_Tuple2('ln', 'Lawful Neutral'),
		_Utils_Tuple2('n', 'Neutral'),
		_Utils_Tuple2('ne', 'Neutral Evil'),
		_Utils_Tuple2('ng', 'Neutral Good'),
		_Utils_Tuple2('no alignment', 'No Alignment')
	]);
var $lattyware$elm_fontawesome$FontAwesome$Solid$checkCircle = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'check-circle',
	512,
	512,
	_List_fromArray(
		['M504 256c0 136.967-111.033 248-248 248S8 392.967 8 256 119.033 8 256 8s248 111.033 248 248zM227.314 387.314l184-184c6.248-6.248 6.248-16.379 0-22.627l-22.627-22.627c-6.248-6.249-16.379-6.249-22.628 0L216 308.118l-70.059-70.059c-6.248-6.248-16.379-6.248-22.628 0l-22.627 22.627c-6.248 6.248-6.248 16.379 0 22.627l104 104c6.249 6.249 16.379 6.249 22.628.001z']));
var $lattyware$elm_fontawesome$FontAwesome$Regular$circle = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'far',
	'circle',
	512,
	512,
	_List_fromArray(
		['M256 8C119 8 8 119 8 256s111 248 248 248 248-111 248-248S393 8 256 8zm0 448c-110.5 0-200-89.5-200-200S145.5 56 256 56s200 89.5 200 200-89.5 200-200 200z']));
var $lattyware$elm_fontawesome$FontAwesome$Solid$minusCircle = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'minus-circle',
	512,
	512,
	_List_fromArray(
		['M256 8C119 8 8 119 8 256s111 248 248 248 248-111 248-248S393 8 256 8zM124 296c-6.6 0-12-5.4-12-12v-56c0-6.6 5.4-12 12-12h264c6.6 0 12 5.4 12 12v56c0 6.6-5.4 12-12 12H124z']));
var $author$project$NethysSearch$viewFilterIcon = function (value) {
	if (value.$ === 'Just') {
		if (value.a) {
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						A2($elm$html$Html$Attributes$style, 'color', '#00cc00')
					]),
				_List_fromArray(
					[
						$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$checkCircle)
					]));
		} else {
			return A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						A2($elm$html$Html$Attributes$style, 'color', '#dd0000')
					]),
				_List_fromArray(
					[
						$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$minusCircle)
					]));
		}
	} else {
		return A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Regular$circle)
				]));
	}
};
var $author$project$NethysSearch$viewFilterAlignments = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllAlignmentFiltersPressed)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Reset selection')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (_v0) {
					var alignment = _v0.a;
					var label = _v0.b;
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Attributes$class('trait'),
								$elm$html$Html$Attributes$class('trait-alignment'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$AlignmentFilterAdded(alignment))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(label),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, alignment, model.filteredAlignments))
							]));
				},
				$author$project$Data$alignments))
		]);
};
var $author$project$NethysSearch$CreatureFamilyFilterAdded = function (a) {
	return {$: 'CreatureFamilyFilterAdded', a: a};
};
var $author$project$NethysSearch$RemoveAllCreatureFamilyFiltersPressed = {$: 'RemoveAllCreatureFamilyFiltersPressed'};
var $author$project$NethysSearch$RemoveAllStrongestSaveFiltersPressed = {$: 'RemoveAllStrongestSaveFiltersPressed'};
var $author$project$NethysSearch$RemoveAllWeakestSaveFiltersPressed = {$: 'RemoveAllWeakestSaveFiltersPressed'};
var $author$project$NethysSearch$SearchCreatureFamiliesChanged = function (a) {
	return {$: 'SearchCreatureFamiliesChanged', a: a};
};
var $author$project$NethysSearch$StrongestSaveFilterAdded = function (a) {
	return {$: 'StrongestSaveFilterAdded', a: a};
};
var $author$project$NethysSearch$WeakestSaveFilterAdded = function (a) {
	return {$: 'WeakestSaveFilterAdded', a: a};
};
var $elm$html$Html$h4 = _VirtualDom_node('h4');
var $author$project$Data$saves = _List_fromArray(
	['fortitude', 'reflex', 'will']);
var $elm$core$List$sortBy = _List_sortBy;
var $elm$core$List$sort = function (xs) {
	return A2($elm$core$List$sortBy, $elm$core$Basics$identity, xs);
};
var $author$project$NethysSearch$viewScrollboxLoader = A2(
	$elm$html$Html$div,
	_List_fromArray(
		[
			$elm$html$Html$Attributes$class('row'),
			A2($elm$html$Html$Attributes$style, 'height', '72px'),
			A2($elm$html$Html$Attributes$style, 'margin', 'auto')
		]),
	_List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('loader')
				]),
			_List_Nil)
		]));
var $author$project$NethysSearch$viewFilterCreatures = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter strongest save')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllStrongestSaveFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (save) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Attributes$class('nowrap'),
								$elm$html$Html$Attributes$class('align-center'),
								A2($elm$html$Html$Attributes$style, 'text-align', 'left'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$StrongestSaveFilterAdded(
									$elm$core$String$toLower(save)))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(save)),
								$author$project$NethysSearch$viewFilterIcon(
								A2(
									$elm$core$Dict$get,
									$elm$core$String$toLower(save),
									model.filteredStrongestSaves))
							]));
				},
				$author$project$Data$saves)),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter weakest save')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllWeakestSaveFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (save) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Attributes$class('nowrap'),
								$elm$html$Html$Attributes$class('align-center'),
								A2($elm$html$Html$Attributes$style, 'text-align', 'left'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$WeakestSaveFilterAdded(
									$elm$core$String$toLower(save)))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(save)),
								$author$project$NethysSearch$viewFilterIcon(
								A2(
									$elm$core$Dict$get,
									$elm$core$String$toLower(save),
									model.filteredWeakestSaves))
							]));
				},
				$author$project$Data$saves)),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter creature families')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllCreatureFamilyFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('input-container')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$input,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$placeholder('Search among creature families'),
							$elm$html$Html$Attributes$value(model.searchCreatureFamilies),
							$elm$html$Html$Attributes$type_('text'),
							$elm$html$Html$Events$onInput($author$project$NethysSearch$SearchCreatureFamiliesChanged)
						]),
					_List_Nil),
					$elm$core$String$isEmpty(model.searchCreatureFamilies) ? $elm$html$Html$text('') : A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('input-button'),
							$elm$html$Html$Events$onClick(
							$author$project$NethysSearch$SearchCreatureFamiliesChanged(''))
						]),
					_List_fromArray(
						[
							$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			function () {
				var _v0 = model.aggregations;
				if (_v0.$ === 'Just') {
					if (_v0.a.$ === 'Ok') {
						var aggregations = _v0.a.a;
						return A2(
							$elm$core$List$map,
							function (creatureFamily) {
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('nowrap'),
											$elm$html$Html$Attributes$class('align-center'),
											A2($elm$html$Html$Attributes$style, 'text-align', 'left'),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$CreatureFamilyFilterAdded(
												$elm$core$String$toLower(creatureFamily)))
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											$elm_community$string_extra$String$Extra$toTitleCase(creatureFamily)),
											$author$project$NethysSearch$viewFilterIcon(
											A2(
												$elm$core$Dict$get,
												$elm$core$String$toLower(creatureFamily),
												model.filteredCreatureFamilies))
										]));
							},
							$elm$core$List$sort(
								A2(
									$elm$core$List$filter,
									A2(
										$elm$core$Basics$composeR,
										$elm$core$String$toLower,
										$elm$core$String$contains(
											$elm$core$String$toLower(model.searchCreatureFamilies))),
									aggregations.creatureFamilies)));
					} else {
						return _List_Nil;
					}
				} else {
					return _List_fromArray(
						[$author$project$NethysSearch$viewScrollboxLoader]);
				}
			}())
		]);
};
var $author$project$NethysSearch$ItemCategoryFilterAdded = function (a) {
	return {$: 'ItemCategoryFilterAdded', a: a};
};
var $author$project$NethysSearch$ItemSubcategoryFilterAdded = function (a) {
	return {$: 'ItemSubcategoryFilterAdded', a: a};
};
var $author$project$NethysSearch$RemoveAllItemCategoryFiltersPressed = {$: 'RemoveAllItemCategoryFiltersPressed'};
var $author$project$NethysSearch$RemoveAllItemSubcategoryFiltersPressed = {$: 'RemoveAllItemSubcategoryFiltersPressed'};
var $author$project$NethysSearch$SearchItemCategoriesChanged = function (a) {
	return {$: 'SearchItemCategoriesChanged', a: a};
};
var $author$project$NethysSearch$SearchItemSubcategoriesChanged = function (a) {
	return {$: 'SearchItemSubcategoriesChanged', a: a};
};
var $elm$html$Html$Attributes$disabled = $elm$html$Html$Attributes$boolProperty('disabled');
var $elm_community$maybe_extra$Maybe$Extra$isJust = function (m) {
	if (m.$ === 'Nothing') {
		return false;
	} else {
		return true;
	}
};
var $elm_community$maybe_extra$Maybe$Extra$or = F2(
	function (ma, mb) {
		if (ma.$ === 'Nothing') {
			return mb;
		} else {
			return ma;
		}
	});
var $author$project$NethysSearch$viewFilterItemCategories = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter item categories')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllItemCategoryFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('input-container')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$input,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$placeholder('Search among item categories'),
							$elm$html$Html$Attributes$value(model.searchItemCategories),
							$elm$html$Html$Attributes$type_('text'),
							$elm$html$Html$Events$onInput($author$project$NethysSearch$SearchItemCategoriesChanged)
						]),
					_List_Nil),
					$elm$core$String$isEmpty(model.searchItemCategories) ? $elm$html$Html$text('') : A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('input-button'),
							$elm$html$Html$Events$onClick(
							$author$project$NethysSearch$SearchItemCategoriesChanged(''))
						]),
					_List_fromArray(
						[
							$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			function () {
				var _v0 = model.aggregations;
				if (_v0.$ === 'Just') {
					if (_v0.a.$ === 'Ok') {
						var aggregations = _v0.a.a;
						return A2(
							$elm$core$List$map,
							function (category) {
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('nowrap'),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$ItemCategoryFilterAdded(category))
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_Nil,
											_List_fromArray(
												[
													$elm$html$Html$text(
													$elm_community$string_extra$String$Extra$toTitleCase(category))
												])),
											$author$project$NethysSearch$viewFilterIcon(
											A2($elm$core$Dict$get, category, model.filteredItemCategories))
										]));
							},
							$elm$core$List$sort(
								A2(
									$elm$core$List$filter,
									A2(
										$elm$core$Basics$composeR,
										$elm$core$String$toLower,
										$elm$core$String$contains(
											$elm$core$String$toLower(model.searchItemCategories))),
									aggregations.itemCategories)));
					} else {
						return _List_Nil;
					}
				} else {
					return _List_fromArray(
						[$author$project$NethysSearch$viewScrollboxLoader]);
				}
			}()),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter item subcategories')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllItemSubcategoryFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('input-container')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$input,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$placeholder('Search among item subcategories'),
							$elm$html$Html$Attributes$value(model.searchItemSubcategories),
							$elm$html$Html$Attributes$type_('text'),
							$elm$html$Html$Events$onInput($author$project$NethysSearch$SearchItemSubcategoriesChanged)
						]),
					_List_Nil),
					$elm$core$String$isEmpty(model.searchItemSubcategories) ? $elm$html$Html$text('') : A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('input-button'),
							$elm$html$Html$Events$onClick(
							$author$project$NethysSearch$SearchItemSubcategoriesChanged(''))
						]),
					_List_fromArray(
						[
							$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			function () {
				var _v1 = model.aggregations;
				if (_v1.$ === 'Just') {
					if (_v1.a.$ === 'Ok') {
						var aggregations = _v1.a.a;
						return A2(
							$elm$core$List$map,
							function (subcategory) {
								var filteredCategory = A2(
									$elm_community$maybe_extra$Maybe$Extra$or,
									function () {
										var _v2 = $author$project$NethysSearch$boolDictIncluded(model.filteredItemCategories);
										if (!_v2.b) {
											return $elm$core$Maybe$Nothing;
										} else {
											var categories = _v2;
											return A2($elm$core$List$member, subcategory.category, categories) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(false);
										}
									}(),
									function () {
										var _v3 = $author$project$NethysSearch$boolDictExcluded(model.filteredItemCategories);
										if (!_v3.b) {
											return $elm$core$Maybe$Nothing;
										} else {
											var categories = _v3;
											return A2($elm$core$List$member, subcategory.category, categories) ? $elm$core$Maybe$Just(false) : $elm$core$Maybe$Nothing;
										}
									}());
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('nowrap'),
											$elm$html$Html$Attributes$disabled(
											$elm_community$maybe_extra$Maybe$Extra$isJust(filteredCategory)),
											A2(
											$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
											$elm_community$maybe_extra$Maybe$Extra$isJust(filteredCategory),
											$elm$html$Html$Attributes$class('excluded')),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$ItemSubcategoryFilterAdded(subcategory.name))
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_Nil,
											_List_fromArray(
												[
													$elm$html$Html$text(
													$elm_community$string_extra$String$Extra$toTitleCase(subcategory.name))
												])),
											$author$project$NethysSearch$viewFilterIcon(
											A2(
												$elm_community$maybe_extra$Maybe$Extra$or,
												A2($elm$core$Dict$get, subcategory.name, model.filteredItemSubcategories),
												filteredCategory))
										]));
							},
							A2(
								$elm$core$List$sortBy,
								function ($) {
									return $.name;
								},
								A2(
									$elm$core$List$filter,
									A2(
										$elm$core$Basics$composeR,
										function ($) {
											return $.name;
										},
										A2(
											$elm$core$Basics$composeR,
											$elm$core$String$toLower,
											$elm$core$String$contains(
												$elm$core$String$toLower(model.searchItemSubcategories)))),
									aggregations.itemSubcategories)));
					} else {
						return _List_Nil;
					}
				} else {
					return _List_fromArray(
						[$author$project$NethysSearch$viewScrollboxLoader]);
				}
			}())
		]);
};
var $author$project$NethysSearch$PfsFilterAdded = function (a) {
	return {$: 'PfsFilterAdded', a: a};
};
var $author$project$NethysSearch$RemoveAllPfsFiltersPressed = {$: 'RemoveAllPfsFiltersPressed'};
var $author$project$NethysSearch$viewFilterPfs = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllPfsFiltersPressed)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Reset selection')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (pfs) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$PfsFilterAdded(pfs))
							]),
						_List_fromArray(
							[
								$author$project$NethysSearch$viewPfsIcon(pfs),
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(pfs)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, pfs, model.filteredPfs))
							]));
				},
				_List_fromArray(
					['none', 'standard', 'limited', 'restricted'])))
		]);
};
var $author$project$NethysSearch$RemoveAllSizeFiltersPressed = {$: 'RemoveAllSizeFiltersPressed'};
var $author$project$NethysSearch$SizeFilterAdded = function (a) {
	return {$: 'SizeFilterAdded', a: a};
};
var $author$project$Data$sizes = _List_fromArray(
	['tiny', 'small', 'medium', 'large', 'huge', 'gargantuan']);
var $author$project$NethysSearch$viewFilterSizes = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllSizeFiltersPressed)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Reset selection')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (size) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Attributes$class('trait'),
								$elm$html$Html$Attributes$class('trait-size'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$SizeFilterAdded(size))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(size)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, size, model.filteredSizes))
							]));
				},
				$author$project$Data$sizes))
		]);
};
var $author$project$NethysSearch$RemoveAllSourceCategoryFiltersPressed = {$: 'RemoveAllSourceCategoryFiltersPressed'};
var $author$project$NethysSearch$RemoveAllSourceFiltersPressed = {$: 'RemoveAllSourceFiltersPressed'};
var $author$project$NethysSearch$SearchSourcesChanged = function (a) {
	return {$: 'SearchSourcesChanged', a: a};
};
var $author$project$NethysSearch$SourceCategoryFilterAdded = function (a) {
	return {$: 'SourceCategoryFilterAdded', a: a};
};
var $author$project$NethysSearch$SourceFilterAdded = function (a) {
	return {$: 'SourceFilterAdded', a: a};
};
var $author$project$Data$sourceCategories = _List_fromArray(
	['adventure paths', 'adventures', 'blog posts', 'comics', 'lost omens', 'rulebooks', 'society']);
var $elm$html$Html$Events$targetChecked = A2(
	$elm$json$Json$Decode$at,
	_List_fromArray(
		['target', 'checked']),
	$elm$json$Json$Decode$bool);
var $elm$html$Html$Events$onCheck = function (tagger) {
	return A2(
		$elm$html$Html$Events$on,
		'change',
		A2($elm$json$Json$Decode$map, tagger, $elm$html$Html$Events$targetChecked));
};
var $author$project$NethysSearch$viewCheckbox = function (_v0) {
	var checked = _v0.checked;
	var onCheck = _v0.onCheck;
	var text = _v0.text;
	return A2(
		$elm$html$Html$label,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('row'),
				$elm$html$Html$Attributes$class('align-baseline')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$input,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$type_('checkbox'),
						$elm$html$Html$Attributes$checked(checked),
						$elm$html$Html$Events$onCheck(onCheck)
					]),
				_List_Nil),
				$elm$html$Html$text(text)
			]));
};
var $author$project$NethysSearch$viewFilterSources = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter spoilers')
				])),
			$author$project$NethysSearch$viewCheckbox(
			{checked: model.filterSpoilers, onCheck: $author$project$NethysSearch$FilterSpoilersChanged, text: 'Hide results with spoilers'}),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter source categories')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					A2($elm$html$Html$Attributes$style, 'justify-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllSourceCategoryFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (category) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$SourceCategoryFilterAdded(category))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(category)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, category, model.filteredSourceCategories))
							]));
				},
				$author$project$Data$sourceCategories)),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter sources')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					A2($elm$html$Html$Attributes$style, 'justify-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllSourceFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('input-container')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$input,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$placeholder('Search among sources'),
							$elm$html$Html$Attributes$value(model.searchSources),
							$elm$html$Html$Attributes$type_('text'),
							$elm$html$Html$Events$onInput($author$project$NethysSearch$SearchSourcesChanged)
						]),
					_List_Nil),
					$elm$core$String$isEmpty(model.searchSources) ? $elm$html$Html$text('') : A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('input-button'),
							$elm$html$Html$Events$onClick(
							$author$project$NethysSearch$SearchSourcesChanged(''))
						]),
					_List_fromArray(
						[
							$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			function () {
				var _v0 = model.aggregations;
				if (_v0.$ === 'Just') {
					if (_v0.a.$ === 'Ok') {
						var sources = _v0.a.a.sources;
						return A2(
							$elm$core$List$map,
							function (source) {
								var filteredCategory = A2(
									$elm_community$maybe_extra$Maybe$Extra$or,
									function () {
										var _v1 = $author$project$NethysSearch$boolDictIncluded(model.filteredSourceCategories);
										if (!_v1.b) {
											return $elm$core$Maybe$Nothing;
										} else {
											var categories = _v1;
											return A2($elm$core$List$member, source.category, categories) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(false);
										}
									}(),
									function () {
										var _v2 = $author$project$NethysSearch$boolDictExcluded(model.filteredSourceCategories);
										if (!_v2.b) {
											return $elm$core$Maybe$Nothing;
										} else {
											var categories = _v2;
											return A2($elm$core$List$member, source.category, categories) ? $elm$core$Maybe$Just(false) : $elm$core$Maybe$Nothing;
										}
									}());
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('nowrap'),
											$elm$html$Html$Attributes$class('align-center'),
											A2($elm$html$Html$Attributes$style, 'text-align', 'left'),
											$elm$html$Html$Attributes$disabled(
											$elm_community$maybe_extra$Maybe$Extra$isJust(filteredCategory)),
											A2(
											$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
											$elm_community$maybe_extra$Maybe$Extra$isJust(filteredCategory),
											$elm$html$Html$Attributes$class('excluded')),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$SourceFilterAdded(source.name))
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_Nil,
											_List_fromArray(
												[
													$elm$html$Html$text(source.name)
												])),
											$author$project$NethysSearch$viewFilterIcon(
											A2(
												$elm_community$maybe_extra$Maybe$Extra$or,
												A2($elm$core$Dict$get, source.name, model.filteredSources),
												filteredCategory))
										]));
							},
							A2(
								$elm$core$List$filter,
								A2(
									$elm$core$Basics$composeR,
									function ($) {
										return $.name;
									},
									A2(
										$elm$core$Basics$composeR,
										$elm$core$String$toLower,
										$elm$core$String$contains(
											$elm$core$String$toLower(model.searchSources)))),
								A2(
									$elm$core$List$sortBy,
									function ($) {
										return $.name;
									},
									sources)));
					} else {
						return _List_Nil;
					}
				} else {
					return _List_fromArray(
						[$author$project$NethysSearch$viewScrollboxLoader]);
				}
			}())
		]);
};
var $author$project$NethysSearch$ActionsFilterAdded = function (a) {
	return {$: 'ActionsFilterAdded', a: a};
};
var $author$project$NethysSearch$ComponentFilterAdded = function (a) {
	return {$: 'ComponentFilterAdded', a: a};
};
var $author$project$NethysSearch$FilterComponentsOperatorChanged = function (a) {
	return {$: 'FilterComponentsOperatorChanged', a: a};
};
var $author$project$NethysSearch$FilterTraditionsOperatorChanged = function (a) {
	return {$: 'FilterTraditionsOperatorChanged', a: a};
};
var $author$project$NethysSearch$RemoveAllActionsFiltersPressed = {$: 'RemoveAllActionsFiltersPressed'};
var $author$project$NethysSearch$RemoveAllComponentFiltersPressed = {$: 'RemoveAllComponentFiltersPressed'};
var $author$project$NethysSearch$RemoveAllSavingThrowFiltersPressed = {$: 'RemoveAllSavingThrowFiltersPressed'};
var $author$project$NethysSearch$RemoveAllSchoolFiltersPressed = {$: 'RemoveAllSchoolFiltersPressed'};
var $author$project$NethysSearch$RemoveAllTraditionFiltersPressed = {$: 'RemoveAllTraditionFiltersPressed'};
var $author$project$NethysSearch$SavingThrowFilterAdded = function (a) {
	return {$: 'SavingThrowFilterAdded', a: a};
};
var $author$project$NethysSearch$SchoolFilterAdded = function (a) {
	return {$: 'SchoolFilterAdded', a: a};
};
var $author$project$NethysSearch$TraditionFilterAdded = function (a) {
	return {$: 'TraditionFilterAdded', a: a};
};
var $author$project$Data$magicSchools = _List_fromArray(
	['abjuration', 'conjuration', 'divination', 'enchantment', 'evocation', 'illusion', 'necromancy', 'transmutation']);
var $author$project$Data$traditions = _List_fromArray(
	['arcane', 'divine', 'occult', 'primal']);
var $author$project$NethysSearch$viewFilterSpells = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter actions / cast time')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllActionsFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			function () {
				var _v0 = model.aggregations;
				if (_v0.$ === 'Just') {
					if (_v0.a.$ === 'Ok') {
						var aggregations = _v0.a.a;
						return A2(
							$elm$core$List$map,
							function (actions) {
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('align-center'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$ActionsFilterAdded(actions))
										]),
									_List_fromArray(
										[
											$author$project$NethysSearch$viewTextWithActionIcons(actions),
											$author$project$NethysSearch$viewFilterIcon(
											A2($elm$core$Dict$get, actions, model.filteredActions))
										]));
							},
							$elm$core$List$sort(aggregations.actions));
					} else {
						return _List_Nil;
					}
				} else {
					return _List_fromArray(
						[$author$project$NethysSearch$viewScrollboxLoader]);
				}
			}()),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter casting components')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllComponentFiltersPressed)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Reset selection')
						])),
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: model.filterComponentsOperator,
						name: 'filter-components',
						onInput: $author$project$NethysSearch$FilterComponentsOperatorChanged(true),
						text: 'Include all (AND)'
					}),
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: !model.filterComponentsOperator,
						name: 'filter-components',
						onInput: $author$project$NethysSearch$FilterComponentsOperatorChanged(false),
						text: 'Include any (OR)'
					})
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (component) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$ComponentFilterAdded(component))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(component)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, component, model.filteredComponents))
							]));
				},
				_List_fromArray(
					['material', 'somatic', 'verbal']))),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter magic schools')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllSchoolFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (school) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Attributes$class('nowrap'),
								$elm$html$Html$Attributes$class('align-center'),
								A2($elm$html$Html$Attributes$style, 'text-align', 'left'),
								$elm$html$Html$Attributes$class('trait'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$SchoolFilterAdded(school))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(school)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, school, model.filteredSchools))
							]));
				},
				$author$project$Data$magicSchools)),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter saving throws')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllSavingThrowFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (save) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Attributes$class('nowrap'),
								$elm$html$Html$Attributes$class('align-center'),
								A2($elm$html$Html$Attributes$style, 'text-align', 'left'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$SavingThrowFilterAdded(save))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(save)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, save, model.filteredSavingThrows))
							]));
				},
				$author$project$Data$saves)),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter traditions')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllTraditionFiltersPressed)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Reset selection')
						])),
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: model.filterTraditionsOperator,
						name: 'filter-traditions',
						onInput: $author$project$NethysSearch$FilterTraditionsOperatorChanged(true),
						text: 'Include all (AND)'
					}),
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: !model.filterTraditionsOperator,
						name: 'filter-traditions',
						onInput: $author$project$NethysSearch$FilterTraditionsOperatorChanged(false),
						text: 'Include any (OR)'
					})
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (tradition) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$TraditionFilterAdded(tradition))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(tradition)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, tradition, model.filteredTraditions))
							]));
				},
				$author$project$Data$traditions))
		]);
};
var $author$project$NethysSearch$FilterTraitsOperatorChanged = function (a) {
	return {$: 'FilterTraitsOperatorChanged', a: a};
};
var $author$project$NethysSearch$RemoveAllTraitFiltersPressed = {$: 'RemoveAllTraitFiltersPressed'};
var $author$project$NethysSearch$SearchTraitsChanged = function (a) {
	return {$: 'SearchTraitsChanged', a: a};
};
var $author$project$NethysSearch$TraitFilterAdded = function (a) {
	return {$: 'TraitFilterAdded', a: a};
};
var $author$project$NethysSearch$viewFilterTraits = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllTraitFiltersPressed)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Reset selection')
						])),
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: model.filterTraitsOperator,
						name: 'filter-traits',
						onInput: $author$project$NethysSearch$FilterTraitsOperatorChanged(true),
						text: 'Include all (AND)'
					}),
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: !model.filterTraitsOperator,
						name: 'filter-traits',
						onInput: $author$project$NethysSearch$FilterTraitsOperatorChanged(false),
						text: 'Include any (OR)'
					})
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('input-container')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$input,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$placeholder('Search among traits'),
							$elm$html$Html$Attributes$value(model.searchTraits),
							$elm$html$Html$Attributes$type_('text'),
							$elm$html$Html$Events$onInput($author$project$NethysSearch$SearchTraitsChanged)
						]),
					_List_Nil),
					$elm$core$String$isEmpty(model.searchTraits) ? $elm$html$Html$text('') : A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('input-button'),
							$elm$html$Html$Events$onClick(
							$author$project$NethysSearch$SearchTraitsChanged(''))
						]),
					_List_fromArray(
						[
							$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			function () {
				var _v0 = model.aggregations;
				if (_v0.$ === 'Just') {
					if (_v0.a.$ === 'Ok') {
						var aggregations = _v0.a.a;
						return A2(
							$elm$core$List$map,
							function (trait) {
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('trait'),
											$author$project$NethysSearch$getTraitClass(trait),
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('align-center'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$TraitFilterAdded(trait))
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											$elm_community$string_extra$String$Extra$toTitleCase(trait)),
											$author$project$NethysSearch$viewFilterIcon(
											A2($elm$core$Dict$get, trait, model.filteredTraits))
										]));
							},
							$elm$core$List$sort(
								A2(
									$elm$core$List$filter,
									A2(
										$elm$core$Basics$composeR,
										$elm$core$String$toLower,
										$elm$core$String$contains(
											$elm$core$String$toLower(model.searchTraits))),
									A2(
										$elm$core$List$filter,
										function (trait) {
											return !A2($elm$core$List$member, trait, $author$project$Data$sizes);
										},
										A2(
											$elm$core$List$filter,
											function (trait) {
												return !A2(
													$elm$core$List$member,
													trait,
													A2($elm$core$List$map, $elm$core$Tuple$first, $author$project$Data$alignments));
											},
											aggregations.traits)))));
					} else {
						return _List_Nil;
					}
				} else {
					return _List_fromArray(
						[$author$project$NethysSearch$viewScrollboxLoader]);
				}
			}())
		]);
};
var $author$project$NethysSearch$RemoveAllTypeFiltersPressed = {$: 'RemoveAllTypeFiltersPressed'};
var $author$project$NethysSearch$SearchTypesChanged = function (a) {
	return {$: 'SearchTypesChanged', a: a};
};
var $author$project$NethysSearch$TypeFilterAdded = function (a) {
	return {$: 'TypeFilterAdded', a: a};
};
var $author$project$NethysSearch$viewFilterTypes = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllTypeFiltersPressed)
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Reset selection')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('input-container')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$input,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$placeholder('Search among types'),
							$elm$html$Html$Attributes$type_('text'),
							$elm$html$Html$Attributes$value(model.searchTypes),
							$elm$html$Html$Events$onInput($author$project$NethysSearch$SearchTypesChanged)
						]),
					_List_Nil),
					$elm$core$String$isEmpty(model.searchTypes) ? $elm$html$Html$text('') : A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('input-button'),
							$elm$html$Html$Events$onClick(
							$author$project$NethysSearch$SearchTypesChanged(''))
						]),
					_List_fromArray(
						[
							$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			function () {
				var _v0 = model.aggregations;
				if (_v0.$ === 'Just') {
					if (_v0.a.$ === 'Ok') {
						var aggregations = _v0.a.a;
						return A2(
							$elm$core$List$map,
							function (type_) {
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('filter-type'),
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('align-center'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$TypeFilterAdded(type_))
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											$elm_community$string_extra$String$Extra$toTitleCase(type_)),
											$author$project$NethysSearch$viewFilterIcon(
											A2($elm$core$Dict$get, type_, model.filteredTypes))
										]));
							},
							A2(
								$elm$core$List$filter,
								A2(
									$elm$core$Basics$composeR,
									$elm$core$String$toLower,
									$elm$core$String$contains(
										$elm$core$String$toLower(model.searchTypes))),
								$elm$core$List$sort(aggregations.types)));
					} else {
						return _List_Nil;
					}
				} else {
					return _List_fromArray(
						[$author$project$NethysSearch$viewScrollboxLoader]);
				}
			}())
		]);
};
var $author$project$NethysSearch$FilterAbilityChanged = function (a) {
	return {$: 'FilterAbilityChanged', a: a};
};
var $author$project$NethysSearch$FilterResistanceChanged = function (a) {
	return {$: 'FilterResistanceChanged', a: a};
};
var $author$project$NethysSearch$FilterSpeedChanged = function (a) {
	return {$: 'FilterSpeedChanged', a: a};
};
var $author$project$NethysSearch$FilterWeaknessChanged = function (a) {
	return {$: 'FilterWeaknessChanged', a: a};
};
var $author$project$NethysSearch$RemoveAllValueFiltersPressed = {$: 'RemoveAllValueFiltersPressed'};
var $elm$html$Html$option = _VirtualDom_node('option');
var $elm$html$Html$select = _VirtualDom_node('select');
var $elm$html$Html$Attributes$step = function (n) {
	return A2($elm$html$Html$Attributes$stringProperty, 'step', n);
};
var $author$project$NethysSearch$viewFilterValues = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					A2($elm$html$Html$Attributes$style, 'justify-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllValueFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset all values')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('grid'),
					$elm$html$Html$Attributes$class('gap-large'),
					A2($elm$html$Html$Attributes$style, 'grid-template-columns', 'repeat(auto-fill,minmax(250px, 1fr))'),
					A2($elm$html$Html$Attributes$style, 'row-gap', 'var(--gap-medium)')
				]),
			$elm$core$List$concat(
				_List_fromArray(
					[
						A2(
						$elm$core$List$map,
						function (_v0) {
							var field = _v0.field;
							var hint = _v0.hint;
							var step = _v0.step;
							var suffix = _v0.suffix;
							return A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('column'),
										$elm$html$Html$Attributes$class('gap-tiny')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-small')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$h4,
												_List_Nil,
												_List_fromArray(
													[
														$elm$html$Html$text(
														$author$project$NethysSearch$sortFieldToLabel(field))
													])),
												$elm$html$Html$text(
												A2($elm$core$Maybe$withDefault, '', hint))
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-tiny'),
												$elm$html$Html$Attributes$class('align-baseline')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('input-container'),
														$elm$html$Html$Attributes$class('row'),
														$elm$html$Html$Attributes$class('align-baseline')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$input,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$type_('number'),
																$elm$html$Html$Attributes$step(step),
																$elm$html$Html$Attributes$value(
																A2(
																	$elm$core$Maybe$withDefault,
																	'',
																	A2($elm$core$Dict$get, field, model.filteredFromValues))),
																$elm$html$Html$Events$onInput(
																$author$project$NethysSearch$FilteredFromValueChanged(field))
															]),
														_List_Nil),
														function () {
														if (suffix.$ === 'Just') {
															var s = suffix.a;
															return A2(
																$elm$html$Html$div,
																_List_fromArray(
																	[
																		A2($elm$html$Html$Attributes$style, 'padding-right', '2px')
																	]),
																_List_fromArray(
																	[
																		$elm$html$Html$text(s)
																	]));
														} else {
															return $elm$html$Html$text('');
														}
													}()
													])),
												$elm$html$Html$text('to'),
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('input-container'),
														$elm$html$Html$Attributes$class('row'),
														$elm$html$Html$Attributes$class('align-baseline')
													]),
												_List_fromArray(
													[
														A2(
														$elm$html$Html$input,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$type_('number'),
																$elm$html$Html$Attributes$step(step),
																$elm$html$Html$Attributes$value(
																A2(
																	$elm$core$Maybe$withDefault,
																	'',
																	A2($elm$core$Dict$get, field, model.filteredToValues))),
																$elm$html$Html$Events$onInput(
																$author$project$NethysSearch$FilteredToValueChanged(field))
															]),
														_List_Nil),
														function () {
														if (suffix.$ === 'Just') {
															var s = suffix.a;
															return A2(
																$elm$html$Html$div,
																_List_fromArray(
																	[
																		A2($elm$html$Html$Attributes$style, 'padding-right', '2px')
																	]),
																_List_fromArray(
																	[
																		$elm$html$Html$text(s)
																	]));
														} else {
															return $elm$html$Html$text('');
														}
													}()
													]))
											]))
									]));
						},
						_List_fromArray(
							[
								{field: 'level', hint: $elm$core$Maybe$Nothing, step: '1', suffix: $elm$core$Maybe$Nothing},
								{
								field: 'price',
								hint: $elm$core$Maybe$Nothing,
								step: '1',
								suffix: $elm$core$Maybe$Just('cp')
							},
								{
								field: 'bulk',
								hint: $elm$core$Maybe$Just('(L bulk is 0,1)'),
								step: '0.1',
								suffix: $elm$core$Maybe$Nothing
							},
								{
								field: 'range',
								hint: $elm$core$Maybe$Nothing,
								step: '1',
								suffix: $elm$core$Maybe$Just('ft.')
							},
								{
								field: 'duration',
								hint: $elm$core$Maybe$Just('(1 round is 6s)'),
								step: '1',
								suffix: $elm$core$Maybe$Just('s')
							},
								{field: 'hp', hint: $elm$core$Maybe$Nothing, step: '1', suffix: $elm$core$Maybe$Nothing},
								{field: 'ac', hint: $elm$core$Maybe$Nothing, step: '1', suffix: $elm$core$Maybe$Nothing},
								{field: 'fortitude_save', hint: $elm$core$Maybe$Nothing, step: '1', suffix: $elm$core$Maybe$Nothing},
								{field: 'reflex_save', hint: $elm$core$Maybe$Nothing, step: '1', suffix: $elm$core$Maybe$Nothing},
								{field: 'will_save', hint: $elm$core$Maybe$Nothing, step: '1', suffix: $elm$core$Maybe$Nothing},
								{field: 'perception', hint: $elm$core$Maybe$Nothing, step: '1', suffix: $elm$core$Maybe$Nothing}
							])),
						_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-tiny')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$h4,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('align-center')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$select,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$value(model.selectedFilterAbility),
													$elm$html$Html$Events$onInput($author$project$NethysSearch$FilterAbilityChanged)
												]),
											A2(
												$elm$core$List$map,
												function (ability) {
													return A2(
														$elm$html$Html$option,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$value(ability)
															]),
														_List_fromArray(
															[
																$elm$html$Html$text(
																$author$project$NethysSearch$sortFieldToLabel(ability))
															]));
												},
												_List_fromArray(
													['strength', 'dexterity', 'constitution', 'intelligence', 'wisdom', 'charisma']))),
											$elm$html$Html$text('score')
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('align-center')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('align-baseline')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('number'),
															$elm$html$Html$Attributes$step('1'),
															$elm$html$Html$Attributes$value(
															A2(
																$elm$core$Maybe$withDefault,
																'',
																A2($elm$core$Dict$get, model.selectedFilterAbility, model.filteredFromValues))),
															$elm$html$Html$Events$onInput(
															$author$project$NethysSearch$FilteredFromValueChanged(model.selectedFilterAbility))
														]),
													_List_Nil)
												])),
											$elm$html$Html$text('to'),
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('align-baseline')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('number'),
															$elm$html$Html$Attributes$step('1'),
															$elm$html$Html$Attributes$value(
															A2(
																$elm$core$Maybe$withDefault,
																'',
																A2($elm$core$Dict$get, model.selectedFilterAbility, model.filteredToValues))),
															$elm$html$Html$Events$onInput(
															$author$project$NethysSearch$FilteredToValueChanged(model.selectedFilterAbility))
														]),
													_List_Nil)
												]))
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-tiny')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$h4,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('align-center')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$select,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$value(model.selectedFilterSpeed),
													$elm$html$Html$Events$onInput($author$project$NethysSearch$FilterSpeedChanged)
												]),
											A2(
												$elm$core$List$map,
												function (speed) {
													return A2(
														$elm$html$Html$option,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$value(speed)
															]),
														_List_fromArray(
															[
																$elm$html$Html$text(
																$elm_community$string_extra$String$Extra$toTitleCase(speed))
															]));
												},
												$author$project$Data$speedTypes)),
											$elm$html$Html$text('speed')
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('align-center')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('align-baseline')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('number'),
															$elm$html$Html$Attributes$step('1'),
															$elm$html$Html$Attributes$value(
															A2(
																$elm$core$Maybe$withDefault,
																'',
																A2($elm$core$Dict$get, 'speed.' + model.selectedFilterSpeed, model.filteredFromValues))),
															$elm$html$Html$Events$onInput(
															$author$project$NethysSearch$FilteredFromValueChanged('speed.' + model.selectedFilterSpeed))
														]),
													_List_Nil)
												])),
											$elm$html$Html$text('to'),
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('align-baseline')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('number'),
															$elm$html$Html$Attributes$step('1'),
															$elm$html$Html$Attributes$value(
															A2(
																$elm$core$Maybe$withDefault,
																'',
																A2($elm$core$Dict$get, 'speed.' + model.selectedFilterSpeed, model.filteredToValues))),
															$elm$html$Html$Events$onInput(
															$author$project$NethysSearch$FilteredToValueChanged('speed.' + model.selectedFilterSpeed))
														]),
													_List_Nil)
												]))
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-tiny')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$h4,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('align-baseline')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$select,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$value(model.selectedFilterResistance),
													$elm$html$Html$Events$onInput($author$project$NethysSearch$FilterResistanceChanged)
												]),
											A2(
												$elm$core$List$map,
												function (type_) {
													return A2(
														$elm$html$Html$option,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$value(type_)
															]),
														_List_fromArray(
															[
																$elm$html$Html$text(
																$elm_community$string_extra$String$Extra$humanize(type_))
															]));
												},
												$author$project$Data$damageTypes)),
											$elm$html$Html$text('resistance')
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('align-center')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('align-baseline')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('number'),
															$elm$html$Html$Attributes$step('1'),
															$elm$html$Html$Attributes$value(
															A2(
																$elm$core$Maybe$withDefault,
																'',
																A2($elm$core$Dict$get, 'resistance.' + model.selectedFilterResistance, model.filteredFromValues))),
															$elm$html$Html$Events$onInput(
															$author$project$NethysSearch$FilteredFromValueChanged('resistance.' + model.selectedFilterResistance))
														]),
													_List_Nil)
												])),
											$elm$html$Html$text('to'),
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('align-baseline')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('number'),
															$elm$html$Html$Attributes$step('1'),
															$elm$html$Html$Attributes$value(
															A2(
																$elm$core$Maybe$withDefault,
																'',
																A2($elm$core$Dict$get, 'resistance.' + model.selectedFilterResistance, model.filteredToValues))),
															$elm$html$Html$Events$onInput(
															$author$project$NethysSearch$FilteredToValueChanged('resistance.' + model.selectedFilterResistance))
														]),
													_List_Nil)
												]))
										]))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-tiny')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$h4,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('align-baseline')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$select,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$value(model.selectedFilterWeakness),
													$elm$html$Html$Events$onInput($author$project$NethysSearch$FilterWeaknessChanged)
												]),
											A2(
												$elm$core$List$map,
												function (type_) {
													return A2(
														$elm$html$Html$option,
														_List_fromArray(
															[
																$elm$html$Html$Attributes$value(type_)
															]),
														_List_fromArray(
															[
																$elm$html$Html$text(
																$elm_community$string_extra$String$Extra$humanize(type_))
															]));
												},
												$author$project$Data$damageTypes)),
											$elm$html$Html$text('weakness')
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Attributes$class('align-center')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('align-baseline')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('number'),
															$elm$html$Html$Attributes$step('1'),
															$elm$html$Html$Attributes$value(
															A2(
																$elm$core$Maybe$withDefault,
																'',
																A2($elm$core$Dict$get, 'weakness.' + model.selectedFilterWeakness, model.filteredFromValues))),
															$elm$html$Html$Events$onInput(
															$author$project$NethysSearch$FilteredFromValueChanged('weakness.' + model.selectedFilterWeakness))
														]),
													_List_Nil)
												])),
											$elm$html$Html$text('to'),
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('input-container'),
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('align-baseline')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$input,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$type_('number'),
															$elm$html$Html$Attributes$step('1'),
															$elm$html$Html$Attributes$value(
															A2(
																$elm$core$Maybe$withDefault,
																'',
																A2($elm$core$Dict$get, 'weakness.' + model.selectedFilterWeakness, model.filteredToValues))),
															$elm$html$Html$Events$onInput(
															$author$project$NethysSearch$FilteredToValueChanged('weakness.' + model.selectedFilterWeakness))
														]),
													_List_Nil)
												]))
										]))
								]))
						])
					])))
		]);
};
var $author$project$NethysSearch$RemoveAllWeaponCategoryFiltersPressed = {$: 'RemoveAllWeaponCategoryFiltersPressed'};
var $author$project$NethysSearch$RemoveAllWeaponGroupFiltersPressed = {$: 'RemoveAllWeaponGroupFiltersPressed'};
var $author$project$NethysSearch$RemoveAllWeaponTypeFiltersPressed = {$: 'RemoveAllWeaponTypeFiltersPressed'};
var $author$project$NethysSearch$WeaponCategoryFilterAdded = function (a) {
	return {$: 'WeaponCategoryFilterAdded', a: a};
};
var $author$project$NethysSearch$WeaponGroupFilterAdded = function (a) {
	return {$: 'WeaponGroupFilterAdded', a: a};
};
var $author$project$NethysSearch$WeaponTypeFilterAdded = function (a) {
	return {$: 'WeaponTypeFilterAdded', a: a};
};
var $author$project$Data$weaponCategories = _List_fromArray(
	['simple', 'martial', 'advanced', 'ammunition', 'unarmed']);
var $author$project$Data$weaponTypes = _List_fromArray(
	['melee', 'ranged']);
var $author$project$NethysSearch$viewFilterWeapons = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter weapon categories')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					A2($elm$html$Html$Attributes$style, 'justify-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllWeaponCategoryFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (category) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$WeaponCategoryFilterAdded(category))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(category)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, category, model.filteredWeaponCategories))
							]));
				},
				$author$project$Data$weaponCategories)),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter weapon groups')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					A2($elm$html$Html$Attributes$style, 'justify-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllWeaponGroupFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			function () {
				var _v0 = model.aggregations;
				if (_v0.$ === 'Just') {
					if (_v0.a.$ === 'Ok') {
						var weaponGroups = _v0.a.a.weaponGroups;
						return A2(
							$elm$core$List$map,
							function (group) {
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$WeaponGroupFilterAdded(group))
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											$elm_community$string_extra$String$Extra$toTitleCase(group)),
											$author$project$NethysSearch$viewFilterIcon(
											A2($elm$core$Dict$get, group, model.filteredWeaponGroups))
										]));
							},
							$elm$core$List$sort(weaponGroups));
					} else {
						return _List_Nil;
					}
				} else {
					return _List_fromArray(
						[$author$project$NethysSearch$viewScrollboxLoader]);
				}
			}()),
			A2(
			$elm$html$Html$h4,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Filter weapon types')
				])),
			A2(
			$elm$html$Html$button,
			_List_fromArray(
				[
					A2($elm$html$Html$Attributes$style, 'align-self', 'flex-start'),
					A2($elm$html$Html$Attributes$style, 'justify-self', 'flex-start'),
					$elm$html$Html$Events$onClick($author$project$NethysSearch$RemoveAllWeaponTypeFiltersPressed)
				]),
			_List_fromArray(
				[
					$elm$html$Html$text('Reset selection')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-tiny'),
					$elm$html$Html$Attributes$class('scrollbox')
				]),
			A2(
				$elm$core$List$map,
				function (type_) {
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('row'),
								$elm$html$Html$Attributes$class('gap-tiny'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$WeaponTypeFilterAdded(type_))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$toTitleCase(type_)),
								$author$project$NethysSearch$viewFilterIcon(
								A2($elm$core$Dict$get, type_, model.filteredWeaponTypes))
							]));
				},
				$author$project$Data$weaponTypes))
		]);
};
var $author$project$NethysSearch$ShowFoldableOptionBoxPressed = F2(
	function (a, b) {
		return {$: 'ShowFoldableOptionBoxPressed', a: a, b: b};
	});
var $lattyware$elm_fontawesome$FontAwesome$Icon$styled = F2(
	function (attributes, _v0) {
		var presentation = _v0.a;
		return $lattyware$elm_fontawesome$FontAwesome$Icon$Presentation(
			_Utils_update(
				presentation,
				{
					attributes: _Utils_ap(presentation.attributes, attributes)
				}));
	});
var $lattyware$elm_fontawesome$FontAwesome$Icon$viewStyled = function (styles) {
	return A2(
		$elm$core$Basics$composeR,
		$lattyware$elm_fontawesome$FontAwesome$Icon$present,
		A2(
			$elm$core$Basics$composeR,
			$lattyware$elm_fontawesome$FontAwesome$Icon$styled(styles),
			$lattyware$elm_fontawesome$FontAwesome$Icon$view));
};
var $author$project$NethysSearch$viewFoldableOptionBox = F4(
	function (model, label, wrapperId, content) {
		var height = A2(
			$elm$core$Maybe$withDefault,
			0,
			A2($elm$core$Dict$get, wrapperId, model.elementHeights));
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('option-container'),
					$elm$html$Html$Attributes$class('column')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							A2($elm$html$Html$Attributes$style, 'border', '0'),
							A2($elm$html$Html$Attributes$style, 'padding', '0'),
							$elm$html$Html$Events$onClick(
							A2($author$project$NethysSearch$ShowFoldableOptionBoxPressed, wrapperId, !height))
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$h3,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('row'),
									$elm$html$Html$Attributes$class('gap-tiny')
								]),
							_List_fromArray(
								[
									$elm$html$Html$text(label),
									A2(
									$lattyware$elm_fontawesome$FontAwesome$Icon$viewStyled,
									_List_fromArray(
										[
											$elm$svg$Svg$Attributes$class('rotatable'),
											(!height) ? $elm$svg$Svg$Attributes$class('') : $elm$svg$Svg$Attributes$class('rotate180')
										]),
									$lattyware$elm_fontawesome$FontAwesome$Solid$chevronDown)
								]))
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('foldable-container'),
							A2(
							$elm$html$Html$Attributes$style,
							'height',
							$elm$core$String$fromInt(height) + 'px')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$id(wrapperId),
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-small'),
									A2($elm$html$Html$Attributes$style, 'padding-top', 'var(--gap-small)')
								]),
							content)
						]))
				]));
	});
var $author$project$Data$fields = _List_fromArray(
	[
		_Utils_Tuple2('ability', 'Ability related to a deity or skill'),
		_Utils_Tuple2('ability_boost', 'Ancestry ability boost'),
		_Utils_Tuple2('ability_flaw', 'Ancestry ability flaw'),
		_Utils_Tuple2('ability_type', 'Familiar ability type (Familiar / Master)'),
		_Utils_Tuple2('ac', '[n] Armor class of an armor, creature, or shield'),
		_Utils_Tuple2('actions', 'Actions or time required to use an action or activity'),
		_Utils_Tuple2('activate', 'Activation requirements of an item'),
		_Utils_Tuple2('advanced_domain_spell', 'Advanced domain spell'),
		_Utils_Tuple2('alignment', 'Alignment'),
		_Utils_Tuple2('ammunition', 'Ammunition type used by a weapon'),
		_Utils_Tuple2('archetype', 'Archetypes associated with a feat'),
		_Utils_Tuple2('area', 'Area of a spell'),
		_Utils_Tuple2('armor_group', 'Armor group'),
		_Utils_Tuple2('aspect', 'Relic gift aspect type'),
		_Utils_Tuple2('attack_proficiency', 'A class\'s attack proficiencies'),
		_Utils_Tuple2('bloodline', 'Sorcerer bloodlines associated with a spell'),
		_Utils_Tuple2('bloodline_spell', 'Sorcerer bloodline\'s spells'),
		_Utils_Tuple2('bulk', 'Item bulk (\'L\' is 0.1)'),
		_Utils_Tuple2('cast', 'Alias for \'actions\''),
		_Utils_Tuple2('cha', '[n] Alias for \'charisma\''),
		_Utils_Tuple2('charisma', '[n] Charisma'),
		_Utils_Tuple2('check_penalty', '[n] Armor check penalty'),
		_Utils_Tuple2('cleric_spell', 'Cleric spells granted by a deity'),
		_Utils_Tuple2('complexity', 'Hazard complexity'),
		_Utils_Tuple2('component', 'Spell casting components (Material / Somatic / Verbal)'),
		_Utils_Tuple2('con', '[n] Alias for \'constitution\''),
		_Utils_Tuple2('constitution', '[n] Constitution'),
		_Utils_Tuple2('cost', 'Cost to use an action or cast a ritual'),
		_Utils_Tuple2('creature_family', 'Creature family'),
		_Utils_Tuple2('damage', 'Weapon damage'),
		_Utils_Tuple2('deed', 'Gunslinger way deeds'),
		_Utils_Tuple2('defense_proficiency', 'A class\'s defense proficiencies'),
		_Utils_Tuple2('deity', 'Deities associated with a domain, spell, or weapon'),
		_Utils_Tuple2('dex', '[n] Alias for \'dexterity\''),
		_Utils_Tuple2('dex_cap', '[n] Armor dex cap'),
		_Utils_Tuple2('dexterity', 'Dexterity'),
		_Utils_Tuple2('disable', 'Hazard disable requirements'),
		_Utils_Tuple2('divine_font', 'Deity\'s divine font'),
		_Utils_Tuple2('divinity', 'Plane divinities'),
		_Utils_Tuple2('domain_spell', 'Domain spell'),
		_Utils_Tuple2('domain', 'Domains related to deity or spell'),
		_Utils_Tuple2('duration', '[n] Duration of spell, ritual, or poison, in seconds'),
		_Utils_Tuple2('duration_raw', 'Duration exactly as written'),
		_Utils_Tuple2('familiar_ability', 'Abilities granted by specific familiars'),
		_Utils_Tuple2('favored_weapon', 'Deity\'s favored weapon'),
		_Utils_Tuple2('feat', 'Related feat'),
		_Utils_Tuple2('follower_alignment', 'Deity\'s follower alignments'),
		_Utils_Tuple2('fort', '[n] Alias for \'fortitude_save\''),
		_Utils_Tuple2('fortitude', '[n] Alias for \'fortitude_save\''),
		_Utils_Tuple2('fortitude_save', '[n] Fortitude save'),
		_Utils_Tuple2('frequency', 'Frequency of which something can be used'),
		_Utils_Tuple2('granted_spell', 'Spells granted by a sorcerer bloodline or witch patron theme'),
		_Utils_Tuple2('hands', 'Hands required to use item'),
		_Utils_Tuple2('hardness', '[n] Hazard or shield hardness'),
		_Utils_Tuple2('heighten', 'Spell heightens available'),
		_Utils_Tuple2('hex_cantrip', 'Witch patron theme hex cantrip'),
		_Utils_Tuple2('home_plane', 'Summoner eidolon home plane'),
		_Utils_Tuple2('hp', '[n] Hit points'),
		_Utils_Tuple2('immunity', 'Immunities'),
		_Utils_Tuple2('int', '[n] Alias for \'intelligence\''),
		_Utils_Tuple2('intelligence', '[n] Intelligence'),
		_Utils_Tuple2('item', 'Items carried by a creature'),
		_Utils_Tuple2('item_category', 'Category of an item'),
		_Utils_Tuple2('item_subcategory', 'Subcategory of an item'),
		_Utils_Tuple2('language', 'Languages spoken'),
		_Utils_Tuple2('lesson_type', 'Witch lesson type'),
		_Utils_Tuple2('level', '[n] Level'),
		_Utils_Tuple2('mystery', 'Oracle mysteries associated with a spell'),
		_Utils_Tuple2('name', 'Name'),
		_Utils_Tuple2('onset', '[n] Onset of a disease or poison in seconds'),
		_Utils_Tuple2('onset_raw', 'Onset exactly as written'),
		_Utils_Tuple2('patron_theme', 'Witch patron themes associated with a spell'),
		_Utils_Tuple2('per', '[n] Alias for \'perception\''),
		_Utils_Tuple2('perception', '[n] Perception'),
		_Utils_Tuple2('perception_proficiency', 'A class\'s perception proficiency'),
		_Utils_Tuple2('pfs', 'Pathfinder Society status (Standard / Limited / Restricted)'),
		_Utils_Tuple2('plane_category', 'Plane category'),
		_Utils_Tuple2('prerequisite', 'Prerequisites'),
		_Utils_Tuple2('price', '[n] Item price in copper coins'),
		_Utils_Tuple2('primary_check', 'Primary check of a ritual'),
		_Utils_Tuple2('range', '[n] Range of spell or weapon in feet'),
		_Utils_Tuple2('rarity', 'Rarity'),
		_Utils_Tuple2('ref', '[n] Alias for \'reflex_save\''),
		_Utils_Tuple2('reflex', '[n] Alias for \'reflex_save\''),
		_Utils_Tuple2('reflex_save', '[n] Reflex save'),
		_Utils_Tuple2('region', 'Background region'),
		_Utils_Tuple2('reload', '[n] Weapon reload'),
		_Utils_Tuple2('required_abilities', '[n] Number of required familiar abilities for a specific familiar'),
		_Utils_Tuple2('requirement', 'Requirements'),
		_Utils_Tuple2('resistance.<type>', '[n] Resistance to <type>. See list of valid types below. Use resistance.\\* to match any type.'),
		_Utils_Tuple2('resistance_raw', 'Resistances exactly as written'),
		_Utils_Tuple2('saving_throw', 'Saving throw for a disease, poison, or spell (Fortitude / Reflex / Will)'),
		_Utils_Tuple2('saving_throw_proficiency', 'A class\'s saving throw proficiencies'),
		_Utils_Tuple2('school', 'Magical school'),
		_Utils_Tuple2('secondary_casters', '[n] Secondary casters for a ritual'),
		_Utils_Tuple2('secondary_check', 'Secondary checks for a ritual'),
		_Utils_Tuple2('sense', 'Senses'),
		_Utils_Tuple2('size', 'Size'),
		_Utils_Tuple2('skill', 'Related skills'),
		_Utils_Tuple2('skill_proficiency', 'A class\'s skill proficiencies'),
		_Utils_Tuple2('slingers_reload', 'Gunslinger way\'s slinger\'s reload'),
		_Utils_Tuple2('source', 'Source book name'),
		_Utils_Tuple2('source_raw', 'Source book exactly as written incl. page'),
		_Utils_Tuple2('source_category', 'Source book category'),
		_Utils_Tuple2('speed.<type>', '[n] Speed of <type>. Valid types are burrow, climb, fly, land, and swim. Use speed.\\* to match any type.'),
		_Utils_Tuple2('speed_raw', 'Speed exactly as written'),
		_Utils_Tuple2('speed_penalty', 'Speed penalty of armor or shield'),
		_Utils_Tuple2('spell_list', 'Spell list of a Sorcerer bloodline or witch patron theme'),
		_Utils_Tuple2('spoilers', 'Adventure path name if there is a spoiler warning on the page'),
		_Utils_Tuple2('stage', 'Stages of a disease or poison'),
		_Utils_Tuple2('stealth', 'Hazard stealth'),
		_Utils_Tuple2('str', '[n] Alias for \'strength\''),
		_Utils_Tuple2('strength', '[n] Creature strength or armor strength requirement'),
		_Utils_Tuple2('strongest_save', 'The strongest save(s) of a creature ( Fortitude / Reflex / Will )'),
		_Utils_Tuple2('target', 'Spell targets'),
		_Utils_Tuple2('text', 'All text on a page'),
		_Utils_Tuple2('tradition', 'Traditions of spell or summoner eidolon'),
		_Utils_Tuple2('trait', 'Traits with values removed, e.g. \'Deadly d6\' is normalized as \'Deadly\''),
		_Utils_Tuple2('trait_raw', 'Traits exactly as written'),
		_Utils_Tuple2('trigger', 'Trigger'),
		_Utils_Tuple2('type', 'Type'),
		_Utils_Tuple2('usage', 'Usage of curse or item'),
		_Utils_Tuple2('weakest_save', 'The weakest save(s) of a creature (Fortitude / Reflex / Will)'),
		_Utils_Tuple2('weakness.<type>', '[n] Weakness to <type>. See list of valid types below. Use weakness.\\* to match any type.'),
		_Utils_Tuple2('weakness_raw', 'Weaknesses exactly as written'),
		_Utils_Tuple2('weapon_category', 'Weapon category (Simple / Martial / Advanced / Ammunition)'),
		_Utils_Tuple2('weapon_group', 'Weapon group'),
		_Utils_Tuple2('will', '[n] Alias for \'will_save\''),
		_Utils_Tuple2('will_save', '[n] Will save'),
		_Utils_Tuple2('wis', '[n] Alias for \'wisdom\''),
		_Utils_Tuple2('wisdom', '[n] Wisdom')
	]);
var $elm$core$List$intersperse = F2(
	function (sep, xs) {
		if (!xs.b) {
			return _List_Nil;
		} else {
			var hd = xs.a;
			var tl = xs.b;
			var step = F2(
				function (x, rest) {
					return A2(
						$elm$core$List$cons,
						sep,
						A2($elm$core$List$cons, x, rest));
				});
			var spersed = A3($elm$core$List$foldr, step, _List_Nil, tl);
			return A2($elm$core$List$cons, hd, spersed);
		}
	});
var $author$project$NethysSearch$viewQueryType = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: _Utils_eq(model.queryType, $author$project$NethysSearch$Standard),
						name: 'query-type',
						onInput: $author$project$NethysSearch$QueryTypeSelected($author$project$NethysSearch$Standard),
						text: 'Standard'
					}),
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: _Utils_eq(model.queryType, $author$project$NethysSearch$ElasticsearchQueryString),
						name: 'query-type',
						onInput: $author$project$NethysSearch$QueryTypeSelected($author$project$NethysSearch$ElasticsearchQueryString),
						text: 'Complex'
					})
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('With the complex query type you can write queries using Elasticsearch Query String syntax. The general idea is that you can search in specific fields by searching '),
					A2(
					$elm$html$Html$span,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monospace')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('field:value')
						])),
					$elm$html$Html$text('. For full documentation on how the query syntax works see '),
					A2(
					$elm$html$Html$a,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$href('https://www.elastic.co/guide/en/elasticsearch/reference/7.15/query-dsl-query-string-query.html#query-string-syntax'),
							$elm$html$Html$Attributes$target('_blank')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Elasticsearch\'s documentation')
						])),
					$elm$html$Html$text('. See below for a list of available fields. [n] means the field is numeric and supports range queries.')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('scrollbox'),
					$elm$html$Html$Attributes$class('column'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('column'),
							$elm$html$Html$Attributes$class('gap-tiny')
						]),
					A2(
						$elm$core$List$append,
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								_List_fromArray(
									[
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('bold'),
												A2($elm$html$Html$Attributes$style, 'width', '35%'),
												A2($elm$html$Html$Attributes$style, 'max-width', '200px')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Field')
											])),
										A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('bold'),
												A2($elm$html$Html$Attributes$style, 'max-width', '60%')
											]),
										_List_fromArray(
											[
												$elm$html$Html$text('Description')
											]))
									]))
							]),
						A2(
							$elm$core$List$map,
							function (_v0) {
								var field = _v0.a;
								var desc = _v0.b;
								return A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-medium')
										]),
									_List_fromArray(
										[
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													A2($elm$html$Html$Attributes$style, 'width', '35%'),
													A2($elm$html$Html$Attributes$style, 'max-width', '200px'),
													A2($elm$html$Html$Attributes$style, 'word-break', 'break-all'),
													$elm$html$Html$Attributes$class('monospace')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(field)
												])),
											A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													A2($elm$html$Html$Attributes$style, 'max-width', '60%')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(desc)
												]))
										]));
							},
							$author$project$Data$fields))),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('column')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('Valid types for resistance and weakness:'),
							A2(
							$elm$html$Html$div,
							_List_Nil,
							A2(
								$elm$core$List$intersperse,
								$elm$html$Html$text(', '),
								A2(
									$elm$core$List$map,
									function (type_) {
										return A2(
											$elm$html$Html$span,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('monospace')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(type_)
												]));
									},
									$author$project$Data$damageTypes)))
						]))
				])),
			A2(
			$elm$html$Html$h3,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Example queries')
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Spells or cantrips unique to the arcane tradition:')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monospace')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('tradition:(arcane -divine -occult -primal) type:(spell OR cantrip)')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Evil deities with dagger as their favored weapon:')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monospace')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('alignment:?E favored_weapon:dagger')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Non-consumable items between 500 and 1000 gp:')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monospace')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('price:[50000 TO 100000] NOT trait:consumable')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Spells up to level 5 with a range of at least 100 feet that are granted by any sorcerer bloodline:')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monospace')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('type:spell level:<=5 range:>=100 bloodline:*')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Rules pages that mention \'mental damage\':')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monospace')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('\"mental damage\" type:rules')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Weapons with finesse and either disarm or trip:')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monospace')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('type:weapon trait:finesse trait:(disarm OR trip)')
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Creatures resistant to fire but not all damage:')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('monospace')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text('resistance.fire:* NOT resistance.all:*')
						]))
				]))
		]);
};
var $author$project$NethysSearch$LimitTableWidthChanged = function (a) {
	return {$: 'LimitTableWidthChanged', a: a};
};
var $author$project$NethysSearch$ResultDisplayChanged = function (a) {
	return {$: 'ResultDisplayChanged', a: a};
};
var $author$project$NethysSearch$ShowAdditionalInfoChanged = function (a) {
	return {$: 'ShowAdditionalInfoChanged', a: a};
};
var $author$project$NethysSearch$ShowSpoilersChanged = function (a) {
	return {$: 'ShowSpoilersChanged', a: a};
};
var $author$project$NethysSearch$ShowTraitsChanged = function (a) {
	return {$: 'ShowTraitsChanged', a: a};
};
var $author$project$NethysSearch$TableColumnMoved = F2(
	function (a, b) {
		return {$: 'TableColumnMoved', a: a, b: b};
	});
var $author$project$NethysSearch$TableColumnRemoved = function (a) {
	return {$: 'TableColumnRemoved', a: a};
};
var $author$project$NethysSearch$TableColumnSetChosen = function (a) {
	return {$: 'TableColumnSetChosen', a: a};
};
var $elm$core$List$concatMap = F2(
	function (f, list) {
		return $elm$core$List$concat(
			A2($elm$core$List$map, f, list));
	});
var $author$project$Data$predefinedColumnConfigurations = _List_fromArray(
	[
		{
		columns: _List_fromArray(
			['hp', 'size', 'speed', 'ability_boost', 'ability_flaw', 'language', 'vision', 'rarity', 'pfs']),
		label: 'Ancestries'
	},
		{
		columns: _List_fromArray(
			['armor_category', 'ac', 'dex_cap', 'check_penalty', 'speed_penalty', 'strength', 'bulk', 'armor_group', 'trait']),
		label: 'Armor'
	},
		{
		columns: _List_fromArray(
			['ability_boost', 'skill', 'feat', 'rarity', 'pfs', 'region']),
		label: 'Backgrounds'
	},
		{
		columns: _List_fromArray(
			['ability', 'hp', 'attack_proficiency', 'defense_proficiency', 'saving_throw_proficiency', 'perception_proficiency', 'skill_proficiency', 'rarity', 'pfs']),
		label: 'Classes'
	},
		{
		columns: _List_fromArray(
			['level', 'hp', 'ac', 'fortitude', 'reflex', 'will', 'strongest_save', 'weakest_save', 'perception', 'sense', 'size', 'alignment', 'rarity', 'speed', 'immunity', 'resistance', 'weakness', 'trait', 'creature_family', 'language']),
		label: 'Creatures'
	},
		{
		columns: _List_fromArray(
			['alignment', 'ability', 'divine_font', 'skill', 'favored_weapon', 'domain', 'cleric_spell', 'deity_category', 'edict', 'anathema', 'area_of_concern', 'follower_alignment', 'pfs']),
		label: 'Deities'
	},
		{
		columns: _List_fromArray(
			['level', 'saving_throw', 'onset', 'stage', 'trait', 'rarity']),
		label: 'Diseases'
	},
		{
		columns: _List_fromArray(
			['level', 'trait', 'prerequisite', 'actions', 'trigger', 'requirement', 'frequency', 'archetype', 'rarity', 'pfs']),
		label: 'Feats'
	},
		{
		columns: _List_fromArray(
			['item_category', 'item_subcategory', 'level', 'price', 'bulk', 'trait', 'rarity', 'pfs']),
		label: 'Items'
	},
		{
		columns: _List_fromArray(
			['level', 'price', 'saving_throw', 'onset', 'duration', 'stage', 'trait', 'rarity', 'pfs']),
		label: 'Poisons'
	},
		{
		columns: _List_fromArray(
			['type', 'aspect', 'prerequisite', 'trait']),
		label: 'Relic gifts'
	},
		{
		columns: _List_fromArray(
			['level', 'heighten', 'school', 'trait', 'primary_check', 'secondary_casters', 'secondary_check', 'cost', 'actions', 'target', 'range', 'area', 'duration', 'rarity', 'pfs']),
		label: 'Rituals'
	},
		{
		columns: _List_fromArray(
			['type', 'level', 'heighten', 'tradition', 'school', 'trait', 'actions', 'component', 'trigger', 'target', 'range', 'area', 'duration', 'saving_throw', 'rarity', 'pfs']),
		label: 'Spells'
	},
		{
		columns: _List_fromArray(
			['weapon_type', 'weapon_category', 'weapon_group', 'trait', 'damage', 'hands', 'range', 'reload', 'bulk', 'price']),
		label: 'Weapons'
	}
	]);
var $author$project$Data$tableColumns = _List_fromArray(
	['ability', 'ability_boost', 'ability_flaw', 'ability_type', 'ac', 'actions', 'alignment', 'anathema', 'archetype', 'area', 'area_of_concern', 'armor_category', 'armor_group', 'aspect', 'attack_proficiency', 'bloodline', 'bulk', 'charisma', 'check_penalty', 'cleric_spell', 'component', 'constitution', 'cost', 'creature_family', 'damage', 'defense_proficiency', 'deity', 'deity_category', 'dex_cap', 'dexterity', 'divine_font', 'domain', 'duration', 'edict', 'favored_weapon', 'feat', 'follower_alignment', 'fortitude', 'frequency', 'hands', 'hardness', 'heighten', 'hp', 'immunity', 'intelligence', 'item_category', 'item_subcategory', 'language', 'level', 'mystery', 'onset', 'patron_theme', 'perception', 'perception_proficiency', 'pfs', 'plane_category', 'prerequisite', 'price', 'primary_check', 'range', 'rarity', 'reflex', 'region', 'requirement', 'resistance', 'saving_throw', 'saving_throw_proficiency', 'school', 'secondary_casters', 'secondary_check', 'sense', 'size', 'skill', 'skill_proficiency', 'source', 'speed', 'speed_penalty', 'spoilers', 'stage', 'strength', 'strongest_save', 'target', 'tradition', 'trait', 'trigger', 'type', 'vision', 'weakest_save', 'weakness', 'weapon_category', 'weapon_group', 'weapon_type', 'will', 'wisdom']);
var $author$project$NethysSearch$ColumnResistanceChanged = function (a) {
	return {$: 'ColumnResistanceChanged', a: a};
};
var $author$project$NethysSearch$ColumnSpeedChanged = function (a) {
	return {$: 'ColumnSpeedChanged', a: a};
};
var $author$project$NethysSearch$ColumnWeaknessChanged = function (a) {
	return {$: 'ColumnWeaknessChanged', a: a};
};
var $author$project$NethysSearch$TableColumnAdded = function (a) {
	return {$: 'TableColumnAdded', a: a};
};
var $lattyware$elm_fontawesome$FontAwesome$Solid$plus = A5(
	$lattyware$elm_fontawesome$FontAwesome$Icon$Icon,
	'fas',
	'plus',
	448,
	512,
	_List_fromArray(
		['M416 208H272V64c0-17.67-14.33-32-32-32h-32c-17.67 0-32 14.33-32 32v144H32c-17.67 0-32 14.33-32 32v32c0 17.67 14.33 32 32 32h144v144c0 17.67 14.33 32 32 32h32c17.67 0 32-14.33 32-32V304h144c17.67 0 32-14.33 32-32v-32c0-17.67-14.33-32-32-32z']));
var $author$project$NethysSearch$viewResultDisplayColumnWithSelect = F2(
	function (model, _v0) {
		var column = _v0.column;
		var onInput = _v0.onInput;
		var selected = _v0.selected;
		var types = _v0.types;
		var columnWithType = column + ('.' + selected);
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-small'),
					$elm$html$Html$Attributes$class('align-center')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$button,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$disabled(
							A2($elm$core$List$member, columnWithType, model.tableColumns)),
							$elm$html$Html$Events$onClick(
							$author$project$NethysSearch$TableColumnAdded(columnWithType))
						]),
					_List_fromArray(
						[
							$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$plus)
						])),
					A2(
					$elm$html$Html$select,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('input-container'),
							$elm$html$Html$Attributes$value(selected),
							$elm$html$Html$Events$onInput(onInput)
						]),
					A2(
						$elm$core$List$map,
						function (type_) {
							return A2(
								$elm$html$Html$option,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$value(type_)
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(
										$elm_community$string_extra$String$Extra$humanize(type_))
									]));
						},
						types)),
					$elm$html$Html$text(column)
				]));
	});
var $author$project$NethysSearch$viewResultDisplayColumn = F2(
	function (model, column) {
		return _List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('gap-small'),
						$elm$html$Html$Attributes$class('align-center')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								A2(
								$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
								A2($elm$core$List$member, column, model.tableColumns),
								$elm$html$Html$Attributes$class('active')),
								A2($elm$core$List$member, column, model.tableColumns) ? $elm$html$Html$Events$onClick(
								$author$project$NethysSearch$TableColumnRemoved(column)) : $elm$html$Html$Events$onClick(
								$author$project$NethysSearch$TableColumnAdded(column))
							]),
						_List_fromArray(
							[
								$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$plus)
							])),
						$elm$html$Html$text(
						$elm_community$string_extra$String$Extra$humanize(column))
					])),
				function () {
				switch (column) {
					case 'resistance':
						return A2(
							$author$project$NethysSearch$viewResultDisplayColumnWithSelect,
							model,
							{column: column, onInput: $author$project$NethysSearch$ColumnResistanceChanged, selected: model.selectedColumnResistance, types: $author$project$Data$damageTypes});
					case 'speed':
						return A2(
							$author$project$NethysSearch$viewResultDisplayColumnWithSelect,
							model,
							{column: column, onInput: $author$project$NethysSearch$ColumnSpeedChanged, selected: model.selectedColumnSpeed, types: $author$project$Data$speedTypes});
					case 'weakness':
						return A2(
							$author$project$NethysSearch$viewResultDisplayColumnWithSelect,
							model,
							{column: column, onInput: $author$project$NethysSearch$ColumnWeaknessChanged, selected: model.selectedColumnWeakness, types: $author$project$Data$damageTypes});
					default:
						return $elm$html$Html$text('');
				}
			}()
			]);
	});
var $author$project$NethysSearch$viewResultDisplay = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('align-baseline'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			_List_fromArray(
				[
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: _Utils_eq(model.resultDisplay, $author$project$NethysSearch$List),
						name: 'result-display',
						onInput: $author$project$NethysSearch$ResultDisplayChanged($author$project$NethysSearch$List),
						text: 'List'
					}),
					$author$project$NethysSearch$viewRadioButton(
					{
						checked: _Utils_eq(model.resultDisplay, $author$project$NethysSearch$Table),
						name: 'result-display',
						onInput: $author$project$NethysSearch$ResultDisplayChanged($author$project$NethysSearch$Table),
						text: 'Table'
					})
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('column'),
					$elm$html$Html$Attributes$class('gap-small')
				]),
			_Utils_eq(model.resultDisplay, $author$project$NethysSearch$Table) ? _List_fromArray(
				[
					A2(
					$elm$html$Html$h4,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Table configuration')
						])),
					$author$project$NethysSearch$viewCheckbox(
					{checked: model.limitTableWidth, onCheck: $author$project$NethysSearch$LimitTableWidthChanged, text: 'Limit table width'}),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('row'),
							$elm$html$Html$Attributes$class('gap-small')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-tiny'),
									$elm$html$Html$Attributes$class('grow'),
									A2($elm$html$Html$Attributes$style, 'flex-basis', '300px')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_Nil,
									_List_fromArray(
										[
											$elm$html$Html$text('Selected columns')
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('scrollbox'),
											$elm$html$Html$Attributes$class('column'),
											$elm$html$Html$Attributes$class('gap-small')
										]),
									A2(
										$elm$core$List$indexedMap,
										F2(
											function (index, column) {
												return A2(
													$elm$html$Html$div,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$class('row'),
															$elm$html$Html$Attributes$class('gap-small'),
															$elm$html$Html$Attributes$class('align-center')
														]),
													_List_fromArray(
														[
															A2(
															$elm$html$Html$button,
															_List_fromArray(
																[
																	$elm$html$Html$Events$onClick(
																	$author$project$NethysSearch$TableColumnRemoved(column))
																]),
															_List_fromArray(
																[
																	$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
																])),
															A2(
															$elm$html$Html$button,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$disabled(!index),
																	$elm$html$Html$Events$onClick(
																	A2($author$project$NethysSearch$TableColumnMoved, index, index - 1))
																]),
															_List_fromArray(
																[
																	$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$chevronUp)
																])),
															A2(
															$elm$html$Html$button,
															_List_fromArray(
																[
																	$elm$html$Html$Attributes$disabled(
																	_Utils_eq(
																		index + 1,
																		$elm$core$List$length(model.tableColumns))),
																	$elm$html$Html$Events$onClick(
																	A2($author$project$NethysSearch$TableColumnMoved, index, index + 1))
																]),
															_List_fromArray(
																[
																	$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$chevronDown)
																])),
															$elm$html$Html$text(
															$author$project$NethysSearch$sortFieldToLabel(column))
														]));
											}),
										model.tableColumns))
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-tiny'),
									$elm$html$Html$Attributes$class('grow'),
									A2($elm$html$Html$Attributes$style, 'flex-basis', '300px')
								]),
							_List_fromArray(
								[
									A2(
									$elm$html$Html$div,
									_List_Nil,
									_List_fromArray(
										[
											$elm$html$Html$text('Available columns')
										])),
									A2(
									$elm$html$Html$div,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('scrollbox'),
											$elm$html$Html$Attributes$class('column'),
											$elm$html$Html$Attributes$class('gap-small')
										]),
									A2(
										$elm$core$List$concatMap,
										$author$project$NethysSearch$viewResultDisplayColumn(model),
										$author$project$Data$tableColumns))
								]))
						])),
					A2(
					$elm$html$Html$div,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('Predefined column configurations')
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('row'),
							$elm$html$Html$Attributes$class('gap-medium')
						]),
					A2(
						$elm$core$List$map,
						function (_v0) {
							var columns = _v0.columns;
							var label = _v0.label;
							return A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick(
										$author$project$NethysSearch$TableColumnSetChosen(columns))
									]),
								_List_fromArray(
									[
										$elm$html$Html$text(label)
									]));
						},
						$author$project$Data$predefinedColumnConfigurations))
				]) : _List_fromArray(
				[
					A2(
					$elm$html$Html$h4,
					_List_Nil,
					_List_fromArray(
						[
							$elm$html$Html$text('List configuration')
						])),
					$author$project$NethysSearch$viewCheckbox(
					{checked: model.showResultSpoilers, onCheck: $author$project$NethysSearch$ShowSpoilersChanged, text: 'Show spoiler warning'}),
					$author$project$NethysSearch$viewCheckbox(
					{checked: model.showResultTraits, onCheck: $author$project$NethysSearch$ShowTraitsChanged, text: 'Show traits'}),
					$author$project$NethysSearch$viewCheckbox(
					{checked: model.showResultAdditionalInfo, onCheck: $author$project$NethysSearch$ShowAdditionalInfoChanged, text: 'Show additional info'})
				]))
		]);
};
var $author$project$NethysSearch$SortAdded = F2(
	function (a, b) {
		return {$: 'SortAdded', a: a, b: b};
	});
var $author$project$NethysSearch$SortOrderChanged = F2(
	function (a, b) {
		return {$: 'SortOrderChanged', a: a, b: b};
	});
var $author$project$NethysSearch$SortSetChosen = function (a) {
	return {$: 'SortSetChosen', a: a};
};
var $elm$core$Basics$composeL = F3(
	function (g, f, x) {
		return g(
			f(x));
	});
var $author$project$NethysSearch$SortResistanceChanged = function (a) {
	return {$: 'SortResistanceChanged', a: a};
};
var $author$project$NethysSearch$SortSpeedChanged = function (a) {
	return {$: 'SortSpeedChanged', a: a};
};
var $author$project$NethysSearch$SortWeaknessChanged = function (a) {
	return {$: 'SortWeaknessChanged', a: a};
};
var $author$project$NethysSearch$viewSortButtons = F2(
	function (model, field) {
		return _List_fromArray(
			[
				A2(
				$elm$html$Html$button,
				_List_fromArray(
					[
						$elm$html$Html$Events$onClick(
						A2(
							$elm$core$List$member,
							_Utils_Tuple2(field, $author$project$NethysSearch$Asc),
							model.sort) ? $author$project$NethysSearch$SortRemoved(field) : A2($author$project$NethysSearch$SortAdded, field, $author$project$NethysSearch$Asc)),
						A2(
						$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
						A2(
							$elm$core$List$member,
							_Utils_Tuple2(field, $author$project$NethysSearch$Asc),
							model.sort),
						$elm$html$Html$Attributes$class('active')),
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('gap-tiny')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text('Asc'),
						A2(
						$author$project$NethysSearch$getSortIcon,
						field,
						$elm$core$Maybe$Just($author$project$NethysSearch$Asc))
					])),
				A2(
				$elm$html$Html$button,
				_List_fromArray(
					[
						$elm$html$Html$Events$onClick(
						A2(
							$elm$core$List$member,
							_Utils_Tuple2(field, $author$project$NethysSearch$Desc),
							model.sort) ? $author$project$NethysSearch$SortRemoved(field) : A2($author$project$NethysSearch$SortAdded, field, $author$project$NethysSearch$Desc)),
						A2(
						$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
						A2(
							$elm$core$List$member,
							_Utils_Tuple2(field, $author$project$NethysSearch$Desc),
							model.sort),
						$elm$html$Html$Attributes$class('active')),
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('gap-tiny')
					]),
				_List_fromArray(
					[
						$elm$html$Html$text('Desc'),
						A2(
						$author$project$NethysSearch$getSortIcon,
						field,
						$elm$core$Maybe$Just($author$project$NethysSearch$Desc))
					]))
			]);
	});
var $author$project$NethysSearch$viewSortResultsFieldWithSelect = F2(
	function (model, _v0) {
		var field = _v0.field;
		var onInput = _v0.onInput;
		var selected = _v0.selected;
		var types = _v0.types;
		var fieldWithType = field + ('.' + selected);
		return A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-small'),
					$elm$html$Html$Attributes$class('align-center')
				]),
			A2(
				$elm$core$List$append,
				A2($author$project$NethysSearch$viewSortButtons, model, fieldWithType),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$select,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('input-container'),
								$elm$html$Html$Attributes$value(selected),
								$elm$html$Html$Events$onInput(onInput)
							]),
						A2(
							$elm$core$List$map,
							function (type_) {
								return A2(
									$elm$html$Html$option,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$value(type_)
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											$elm_community$string_extra$String$Extra$humanize(type_))
										]));
							},
							types)),
						$elm$html$Html$text(field)
					])));
	});
var $author$project$NethysSearch$viewSortResultsField = F2(
	function (model, field) {
		switch (field) {
			case 'resistance':
				return A2(
					$author$project$NethysSearch$viewSortResultsFieldWithSelect,
					model,
					{field: field, onInput: $author$project$NethysSearch$SortResistanceChanged, selected: model.selectedSortResistance, types: $author$project$Data$damageTypes});
			case 'speed':
				return A2(
					$author$project$NethysSearch$viewSortResultsFieldWithSelect,
					model,
					{field: field, onInput: $author$project$NethysSearch$SortSpeedChanged, selected: model.selectedSortSpeed, types: $author$project$Data$speedTypes});
			case 'weakness':
				return A2(
					$author$project$NethysSearch$viewSortResultsFieldWithSelect,
					model,
					{field: field, onInput: $author$project$NethysSearch$SortWeaknessChanged, selected: model.selectedSortWeakness, types: $author$project$Data$damageTypes});
			default:
				return A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('row'),
							$elm$html$Html$Attributes$class('gap-small'),
							$elm$html$Html$Attributes$class('align-center')
						]),
					A2(
						$elm$core$List$append,
						A2($author$project$NethysSearch$viewSortButtons, model, field),
						_List_fromArray(
							[
								$elm$html$Html$text(
								$elm_community$string_extra$String$Extra$humanize(field))
							])));
		}
	});
var $author$project$NethysSearch$viewSortResults = function (model) {
	return _List_fromArray(
		[
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-small')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('column'),
							$elm$html$Html$Attributes$class('gap-tiny'),
							$elm$html$Html$Attributes$class('grow'),
							A2($elm$html$Html$Attributes$style, 'flex-basis', '400px')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_Nil,
							_List_fromArray(
								[
									$elm$html$Html$text('Selected fields')
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('scrollbox'),
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-small')
								]),
							A2(
								$elm$core$List$indexedMap,
								F2(
									function (index, _v0) {
										var field = _v0.a;
										var dir = _v0.b;
										return A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('gap-small'),
													$elm$html$Html$Attributes$class('align-center')
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$button,
													_List_fromArray(
														[
															$elm$html$Html$Events$onClick(
															$author$project$NethysSearch$SortRemoved(field))
														]),
													_List_fromArray(
														[
															$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
														])),
													A2(
													$elm$html$Html$button,
													_List_fromArray(
														[
															$elm$html$Html$Events$onClick(
															A2(
																$author$project$NethysSearch$SortAdded,
																field,
																_Utils_eq(dir, $author$project$NethysSearch$Asc) ? $author$project$NethysSearch$Desc : $author$project$NethysSearch$Asc))
														]),
													_List_fromArray(
														[
															A2(
															$author$project$NethysSearch$getSortIcon,
															field,
															$elm$core$Maybe$Just(dir))
														])),
													A2(
													$elm$html$Html$button,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$disabled(!index),
															$elm$html$Html$Events$onClick(
															A2($author$project$NethysSearch$SortOrderChanged, index, index - 1))
														]),
													_List_fromArray(
														[
															$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$chevronUp)
														])),
													A2(
													$elm$html$Html$button,
													_List_fromArray(
														[
															$elm$html$Html$Attributes$disabled(
															_Utils_eq(
																index + 1,
																$elm$core$List$length(model.sort))),
															$elm$html$Html$Events$onClick(
															A2($author$project$NethysSearch$SortOrderChanged, index, index + 1))
														]),
													_List_fromArray(
														[
															$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$chevronDown)
														])),
													$elm$html$Html$text(
													$author$project$NethysSearch$sortFieldToLabel(field))
												]));
									}),
								model.sort))
						])),
					A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('column'),
							$elm$html$Html$Attributes$class('gap-tiny'),
							$elm$html$Html$Attributes$class('grow'),
							A2($elm$html$Html$Attributes$style, 'flex-basis', '400px')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_Nil,
							_List_fromArray(
								[
									$elm$html$Html$text('Available fields')
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('scrollbox'),
									$elm$html$Html$Attributes$class('column'),
									$elm$html$Html$Attributes$class('gap-small')
								]),
							A2(
								$elm$core$List$map,
								$author$project$NethysSearch$viewSortResultsField(model),
								$elm$core$List$sort(
									A2(
										$elm$core$List$append,
										_List_fromArray(
											['resistance', 'speed', 'weakness']),
										A2(
											$elm$core$List$filter,
											A2(
												$elm$core$Basics$composeL,
												$elm$core$Basics$not,
												$elm$core$String$contains('.')),
											A2($elm$core$List$map, $TSFoster$elm_tuple_extra$Tuple3$first, $author$project$Data$sortFields))))))
						]))
				])),
			A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					$elm$html$Html$text('Predefined sort configurations')
				])),
			A2(
			$elm$html$Html$div,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('row'),
					$elm$html$Html$Attributes$class('gap-medium')
				]),
			A2(
				$elm$core$List$map,
				function (_v1) {
					var fields = _v1.fields;
					var label = _v1.label;
					return A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$SortSetChosen(fields))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(label)
							]));
				},
				_List_fromArray(
					[
						{
						fields: _List_fromArray(
							[
								_Utils_Tuple2('level', $author$project$NethysSearch$Asc),
								_Utils_Tuple2('name', $author$project$NethysSearch$Asc)
							]),
						label: 'Level + Name'
					},
						{
						fields: _List_fromArray(
							[
								_Utils_Tuple2('type', $author$project$NethysSearch$Asc),
								_Utils_Tuple2('name', $author$project$NethysSearch$Asc)
							]),
						label: 'Type + Name'
					}
					])))
		]);
};
var $author$project$NethysSearch$viewQueryOptions = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('column'),
				$elm$html$Html$Attributes$class('gap-small')
			]),
		_List_fromArray(
			[
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Query type',
				$author$project$NethysSearch$queryTypeMeasureWrapperId,
				$author$project$NethysSearch$viewQueryType(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter alignments',
				$author$project$NethysSearch$filterAlignmentsMeasureWrapperId,
				$author$project$NethysSearch$viewFilterAlignments(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter creatures',
				$author$project$NethysSearch$filterCreaturesMeasureWrapperId,
				$author$project$NethysSearch$viewFilterCreatures(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter item categories',
				$author$project$NethysSearch$filterItemCategoriesMeasureWrapperId,
				$author$project$NethysSearch$viewFilterItemCategories(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter PFS status',
				$author$project$NethysSearch$filterPfsMeasureWrapperId,
				$author$project$NethysSearch$viewFilterPfs(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter sizes',
				$author$project$NethysSearch$filterSizesMeasureWrapperId,
				$author$project$NethysSearch$viewFilterSizes(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter sources & spoilers',
				$author$project$NethysSearch$filterSourcesMeasureWrapperId,
				$author$project$NethysSearch$viewFilterSources(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter spells',
				$author$project$NethysSearch$filterSpellsMeasureWrapperId,
				$author$project$NethysSearch$viewFilterSpells(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter traits',
				$author$project$NethysSearch$filterTraitsMeasureWrapperId,
				$author$project$NethysSearch$viewFilterTraits(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter types',
				$author$project$NethysSearch$filterTypesMeasureWrapperId,
				$author$project$NethysSearch$viewFilterTypes(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter weapons',
				$author$project$NethysSearch$filterWeaponsMeasureWrapperId,
				$author$project$NethysSearch$viewFilterWeapons(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Filter numeric values',
				$author$project$NethysSearch$filterValuesMeasureWrapperId,
				$author$project$NethysSearch$viewFilterValues(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Result display',
				$author$project$NethysSearch$resultDisplayMeasureWrapperId,
				$author$project$NethysSearch$viewResultDisplay(model)),
				A4(
				$author$project$NethysSearch$viewFoldableOptionBox,
				model,
				'Sort results',
				$author$project$NethysSearch$sortResultsMeasureWrapperId,
				$author$project$NethysSearch$viewSortResults(model))
			]));
};
var $author$project$NethysSearch$viewQuery = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('column'),
				$elm$html$Html$Attributes$class('align-stretch'),
				$elm$html$Html$Attributes$class('limit-width'),
				$elm$html$Html$Attributes$class('gap-tiny'),
				$elm$html$Html$Attributes$class('fill-width-with-padding')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('input-container')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$input,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$autofocus(true),
								$elm$html$Html$Attributes$class('query-input'),
								$elm$html$Html$Attributes$placeholder('Enter search query'),
								$elm$html$Html$Attributes$type_('text'),
								$elm$html$Html$Attributes$value(model.query),
								$elm$html$Html$Events$onInput($author$project$NethysSearch$QueryChanged)
							]),
						_List_fromArray(
							[
								$elm$html$Html$text(model.query)
							])),
						$elm$core$String$isEmpty(model.query) ? $elm$html$Html$text('') : A2(
						$elm$html$Html$button,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('input-button'),
								A2($elm$html$Html$Attributes$style, 'font-size', '24px'),
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$QueryChanged(''))
							]),
						_List_fromArray(
							[
								$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$times)
							]))
					])),
				A2(
				$elm$html$Html$button,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('gap-tiny'),
						$elm$html$Html$Events$onClick(
						$author$project$NethysSearch$ShowQueryOptionsPressed(!model.queryOptionsOpen)),
						A2($elm$html$Html$Attributes$style, 'align-self', 'center')
					]),
				model.queryOptionsOpen ? _List_fromArray(
					[
						$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$chevronUp),
						$elm$html$Html$text('Hide filters and options'),
						$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$chevronUp)
					]) : _List_fromArray(
					[
						$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$chevronDown),
						$elm$html$Html$text(' Show filters and options'),
						$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$chevronDown)
					])),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('foldable-container'),
						A2(
						$elm$html$Html$Attributes$style,
						'height',
						model.queryOptionsOpen ? ($elm$core$String$fromInt(
							$author$project$NethysSearch$getQueryOptionsHeight(model)) + 'px') : '0')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$id($author$project$NethysSearch$queryOptionsMeasureWrapperId)
							]),
						_List_fromArray(
							[
								$author$project$NethysSearch$viewQueryOptions(model)
							]))
					])),
				_Utils_eq(model.queryType, $author$project$NethysSearch$ElasticsearchQueryString) ? A2(
				$elm$html$Html$div,
				_List_Nil,
				_List_fromArray(
					[
						$elm$html$Html$text('Query type: Complex')
					])) : (A2($author$project$NethysSearch$stringContainsChar, model.query, ':()\"') ? A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('option-container'),
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('align-center'),
						$elm$html$Html$Attributes$class('nowrap'),
						$elm$html$Html$Attributes$class('gap-small')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								A2($elm$html$Html$Attributes$style, 'font-size', '24px'),
								A2($elm$html$Html$Attributes$style, 'padding', '4px')
							]),
						_List_fromArray(
							[
								$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$exclamation)
							])),
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Events$onClick(
								$author$project$NethysSearch$QueryTypeSelected($author$project$NethysSearch$ElasticsearchQueryString))
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Your query contains characters that can be used with the complex query type, but you are currently using the standard query type. Would you like to '),
								A2(
								$elm$html$Html$button,
								_List_Nil,
								_List_fromArray(
									[
										$elm$html$Html$text('switch to complex query type')
									])),
								$elm$html$Html$text('?')
							]))
					])) : $elm$html$Html$text('')),
				$author$project$NethysSearch$viewFilters(model),
				$elm$core$List$isEmpty(model.sort) ? $elm$html$Html$text('') : A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('row'),
						$elm$html$Html$Attributes$class('gap-tiny'),
						$elm$html$Html$Attributes$class('align-baseline')
					]),
				$elm$core$List$concat(
					_List_fromArray(
						[
							_List_fromArray(
							[
								$elm$html$Html$text('Sort by:')
							]),
							A2(
							$elm$core$List$map,
							function (_v0) {
								var field = _v0.a;
								var dir = _v0.b;
								return A2(
									$elm$html$Html$button,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$class('row'),
											$elm$html$Html$Attributes$class('gap-tiny'),
											$elm$html$Html$Events$onClick(
											$author$project$NethysSearch$SortRemoved(field))
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(
											$elm_community$string_extra$String$Extra$humanize(
												A2(
													$elm$core$String$join,
													' ',
													$elm$core$List$reverse(
														A2(
															$elm$core$List$cons,
															$author$project$NethysSearch$sortDirToString(dir),
															A2($elm$core$String$split, '.', field)))))),
											A2(
											$author$project$NethysSearch$getSortIcon,
											field,
											$elm$core$Maybe$Just(dir))
										]));
							},
							model.sort)
						])))
			]));
};
var $author$project$NethysSearch$LoadMorePressed = {$: 'LoadMorePressed'};
var $author$project$NethysSearch$ScrollToTopPressed = {$: 'ScrollToTopPressed'};
var $elm$core$List$head = function (list) {
	if (list.b) {
		var x = list.a;
		var xs = list.b;
		return $elm$core$Maybe$Just(x);
	} else {
		return $elm$core$Maybe$Nothing;
	}
};
var $author$project$NethysSearch$SortToggled = function (a) {
	return {$: 'SortToggled', a: a};
};
var $elm$html$Html$table = _VirtualDom_node('table');
var $elm$html$Html$tbody = _VirtualDom_node('tbody');
var $elm$html$Html$th = _VirtualDom_node('th');
var $elm$html$Html$thead = _VirtualDom_node('thead');
var $elm$html$Html$tr = _VirtualDom_node('tr');
var $author$project$NethysSearch$getDamageTypeValue = F2(
	function (type_, values) {
		switch (type_) {
			case 'acid':
				return values.acid;
			case 'all':
				return values.all;
			case 'area':
				return values.area;
			case 'bleed':
				return values.bleed;
			case 'bludgeoning':
				return values.bludgeoning;
			case 'chaotic':
				return values.chaotic;
			case 'cold':
				return values.cold;
			case 'cold_iron':
				return values.coldIron;
			case 'electricity':
				return values.electricity;
			case 'evil':
				return values.evil;
			case 'fire':
				return values.fire;
			case 'force':
				return values.force;
			case 'good':
				return values.good;
			case 'lawful':
				return values.lawful;
			case 'mental':
				return values.mental;
			case 'negative':
				return values.negative;
			case 'orichalcum':
				return values.orichalcum;
			case 'physical':
				return values.physical;
			case 'piercing':
				return values.piercing;
			case 'poison':
				return values.poison;
			case 'positive':
				return values.positive;
			case 'precision':
				return values.precision;
			case 'silver':
				return values.silver;
			case 'slashing':
				return values.slashing;
			case 'sonic':
				return values.sonic;
			case 'splash':
				return values.splash;
			default:
				return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$NethysSearch$getSpeedTypeValue = F2(
	function (type_, values) {
		switch (type_) {
			case 'burrow':
				return values.burrow;
			case 'climb':
				return values.climb;
			case 'fly':
				return values.fly;
			case 'land':
				return values.land;
			case 'swim':
				return values.swim;
			default:
				return $elm$core$Maybe$Nothing;
		}
	});
var $author$project$NethysSearch$getUrl = function (doc) {
	return 'https://2e.aonprd.com/' + doc.url;
};
var $elm$core$Basics$ge = _Utils_ge;
var $author$project$NethysSearch$numberWithSign = function (_int) {
	return (_int >= 0) ? ('+' + $elm$core$String$fromInt(_int)) : $elm$core$String$fromInt(_int);
};
var $elm$html$Html$td = _VirtualDom_node('td');
var $author$project$NethysSearch$viewSearchResultGridCell = F3(
	function (model, hit, column) {
		return A2(
			$elm$html$Html$td,
			_List_fromArray(
				[
					A2(
					$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
					column === 'name',
					$elm$html$Html$Attributes$class('sticky-left'))
				]),
			_List_fromArray(
				[
					function () {
					var _v0 = A2($elm$core$String$split, '.', column);
					_v0$99:
					while (true) {
						if (_v0.b) {
							if (_v0.b.b) {
								if (!_v0.b.b.b) {
									switch (_v0.a) {
										case 'resistance':
											var _v1 = _v0.b;
											var type_ = _v1.a;
											return $elm$html$Html$text(
												A2(
													$elm$core$Maybe$withDefault,
													'',
													A2(
														$elm$core$Maybe$map,
														$elm$core$String$fromInt,
														A2(
															$elm$core$Maybe$andThen,
															$author$project$NethysSearch$getDamageTypeValue(type_),
															hit.source.resistanceValues))));
										case 'speed':
											var _v2 = _v0.b;
											var type_ = _v2.a;
											return $elm$html$Html$text(
												A2(
													$elm$core$Maybe$withDefault,
													'',
													A2(
														$elm$core$Maybe$map,
														$elm$core$String$fromInt,
														A2(
															$elm$core$Maybe$andThen,
															$author$project$NethysSearch$getSpeedTypeValue(type_),
															hit.source.speedValues))));
										case 'weakness':
											var _v3 = _v0.b;
											var type_ = _v3.a;
											return $elm$html$Html$text(
												A2(
													$elm$core$Maybe$withDefault,
													'',
													A2(
														$elm$core$Maybe$map,
														$elm$core$String$fromInt,
														A2(
															$elm$core$Maybe$andThen,
															$author$project$NethysSearch$getDamageTypeValue(type_),
															hit.source.weaknessValues))));
										default:
											break _v0$99;
									}
								} else {
									break _v0$99;
								}
							} else {
								switch (_v0.a) {
									case 'ability':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.abilities));
									case 'ability_boost':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.abilityBoosts));
									case 'ability_flaw':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.abilityFlaws));
									case 'ability_type':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.abilityType));
									case 'ac':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $elm$core$String$fromInt, hit.source.ac)));
									case 'actions':
										return $author$project$NethysSearch$viewTextWithActionIcons(
											A2($elm$core$Maybe$withDefault, '', hit.source.actions));
									case 'alignment':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.alignment));
									case 'anathema':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.anathema));
									case 'archetype':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.archetype));
									case 'area':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.area));
									case 'area_of_concern':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.areasOfConcern));
									case 'armor_category':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.armorCategory));
									case 'armor_group':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.armorGroup));
									case 'aspect':
										return $elm$html$Html$text(
											$elm_community$string_extra$String$Extra$toTitleCase(
												A2($elm$core$Maybe$withDefault, '', hit.source.aspect)));
									case 'attack_proficiency':
										return A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('column'),
													$elm$html$Html$Attributes$class('gap-small')
												]),
											A2(
												$elm$core$List$map,
												function (prof) {
													return A2(
														$elm$html$Html$div,
														_List_Nil,
														_List_fromArray(
															[
																$elm$html$Html$text(prof)
															]));
												},
												hit.source.attackProficiencies));
									case 'bloodline':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.bloodlines)));
									case 'bulk':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.bulk));
									case 'charisma':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.charisma)));
									case 'check_penalty':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.checkPenalty)));
									case 'cleric_spell':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.clericSpells));
									case 'creature_family':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.creatureFamily));
									case 'component':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.components)));
									case 'constitution':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.constitution)));
									case 'cost':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.cost));
									case 'deity':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.deities)));
									case 'deity_category':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.deityCategory));
									case 'damage':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.damage));
									case 'defense_proficiency':
										return A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('column'),
													$elm$html$Html$Attributes$class('gap-small')
												]),
											A2(
												$elm$core$List$map,
												function (prof) {
													return A2(
														$elm$html$Html$div,
														_List_Nil,
														_List_fromArray(
															[
																$elm$html$Html$text(prof)
															]));
												},
												hit.source.defenseProficiencies));
									case 'dexterity':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.dexterity)));
									case 'dex_cap':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.dexCap)));
									case 'divine_font':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												' or ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.divineFonts)));
									case 'domain':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.domains)));
									case 'duration':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.duration));
									case 'edict':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.edict));
									case 'favored_weapon':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												' or ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.favoredWeapons)));
									case 'feat':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.feats));
									case 'follower_alignment':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.followerAlignments));
									case 'fortitude':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.fort)));
									case 'frequency':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.frequency));
									case 'hands':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.hands));
									case 'hardness':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.hardness));
									case 'heighten':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.heighten));
									case 'hp':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.hp));
									case 'immunity':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.immunities));
									case 'intelligence':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.intelligence)));
									case 'item_category':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.itemCategory));
									case 'item_subcategory':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.itemSubcategory));
									case 'language':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.languages));
									case 'level':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $elm$core$String$fromInt, hit.source.level)));
									case 'mystery':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.mysteries)));
									case 'name':
										return A2(
											$elm$html$Html$a,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$href(
													$author$project$NethysSearch$getUrl(hit.source)),
													$elm$html$Html$Attributes$target('_blank')
												]),
											_List_fromArray(
												[
													$elm$html$Html$text(hit.source.name)
												]));
									case 'onset':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.onset));
									case 'patron_theme':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.patronThemes)));
									case 'perception':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.perception)));
									case 'perception_proficiency':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.perceptionProficiency));
									case 'pfs':
										return $author$project$NethysSearch$viewPfsIcon(
											A2($elm$core$Maybe$withDefault, '', hit.source.pfs));
									case 'plane_category':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.planeCategory));
									case 'prerequisite':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.prerequisites));
									case 'price':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.price));
									case 'primary_check':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.primaryCheck));
									case 'range':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.range));
									case 'rarity':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.rarity)));
									case 'reflex':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.ref)));
									case 'region':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.region));
									case 'reload':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.reload));
									case 'requirement':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.requirements));
									case 'resistance':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.resistances));
									case 'saving_throw':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.savingThrow));
									case 'saving_throw_proficiency':
										return A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('column'),
													$elm$html$Html$Attributes$class('gap-small')
												]),
											A2(
												$elm$core$List$map,
												function (prof) {
													return A2(
														$elm$html$Html$div,
														_List_Nil,
														_List_fromArray(
															[
																$elm$html$Html$text(prof)
															]));
												},
												hit.source.savingThrowProficiencies));
									case 'school':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.school)));
									case 'secondary_casters':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.secondaryCasters));
									case 'secondary_check':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.secondaryChecks));
									case 'sense':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toSentenceCase, hit.source.senses)));
									case 'size':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.sizes));
									case 'skill':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.skills));
									case 'skill_proficiency':
										return A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('column'),
													$elm$html$Html$Attributes$class('gap-small')
												]),
											A2(
												$elm$core$List$map,
												function (prof) {
													return A2(
														$elm$html$Html$div,
														_List_Nil,
														_List_fromArray(
															[
																$elm$html$Html$text(prof)
															]));
												},
												hit.source.skillProficiencies));
									case 'source':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.sources));
									case 'speed':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.speed));
									case 'speed_penalty':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.speedPenalty));
									case 'spoilers':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.spoilers));
									case 'stage':
										return A2(
											$elm$html$Html$div,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('column'),
													$elm$html$Html$Attributes$class('gap-small')
												]),
											A2(
												$elm$core$List$indexedMap,
												F2(
													function (idx, stage) {
														return A2(
															$elm$html$Html$div,
															_List_Nil,
															_List_fromArray(
																[
																	$elm$html$Html$text(
																	'Stage ' + ($elm$core$String$fromInt(idx + 1) + (': ' + stage)))
																]));
													}),
												hit.source.stages));
									case 'strength':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.strength)));
									case 'strongest_save':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2(
													$elm$core$List$map,
													$elm_community$string_extra$String$Extra$toTitleCase,
													A2(
														$elm$core$List$filter,
														function (s) {
															return !A2(
																$elm$core$List$member,
																s,
																_List_fromArray(
																	['fort', 'ref']));
														},
														hit.source.strongestSaves))));
									case 'target':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.targets));
									case 'tradition':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2($elm$core$List$map, $elm_community$string_extra$String$Extra$toTitleCase, hit.source.traditions)));
									case 'trait':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.traits));
									case 'trigger':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.trigger));
									case 'type':
										return $elm$html$Html$text(hit.source.type_);
									case 'vision':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.vision));
									case 'weapon_category':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.weaponCategory));
									case 'weapon_group':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.weaponGroup));
									case 'weapon_type':
										return $elm$html$Html$text(
											A2($elm$core$Maybe$withDefault, '', hit.source.weaponType));
									case 'weakest_save':
										return $elm$html$Html$text(
											A2(
												$elm$core$String$join,
												', ',
												A2(
													$elm$core$List$map,
													$elm_community$string_extra$String$Extra$toTitleCase,
													A2(
														$elm$core$List$filter,
														function (s) {
															return !A2(
																$elm$core$List$member,
																s,
																_List_fromArray(
																	['fort', 'ref']));
														},
														hit.source.weakestSaves))));
									case 'weakness':
										return $elm$html$Html$text(
											A2($elm$core$String$join, ', ', hit.source.weaknesses));
									case 'will':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.will)));
									case 'wisdom':
										return $elm$html$Html$text(
											A2(
												$elm$core$Maybe$withDefault,
												'',
												A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.wisdom)));
									default:
										break _v0$99;
								}
							}
						} else {
							break _v0$99;
						}
					}
					return $elm$html$Html$text('');
				}()
				]));
	});
var $author$project$NethysSearch$viewSearchResultGrid = function (model) {
	return A2(
		$elm$html$Html$table,
		_List_Nil,
		_List_fromArray(
			[
				A2(
				$elm$html$Html$thead,
				_List_Nil,
				_List_fromArray(
					[
						A2(
						$elm$html$Html$tr,
						_List_Nil,
						A2(
							$elm$core$List$map,
							function (column) {
								return A2(
									$elm$html$Html$th,
									(column === 'name') ? _List_fromArray(
										[
											$elm$html$Html$Attributes$class('sticky-left'),
											A2($elm$html$Html$Attributes$style, 'z-index', '1')
										]) : _List_Nil,
									_List_fromArray(
										[
											A2(
											$elm$core$List$any,
											A2(
												$elm$core$Basics$composeR,
												$TSFoster$elm_tuple_extra$Tuple3$first,
												$elm$core$Basics$eq(column)),
											$author$project$Data$sortFields) ? A2(
											$elm$html$Html$button,
											_List_fromArray(
												[
													$elm$html$Html$Attributes$class('row'),
													$elm$html$Html$Attributes$class('gap-small'),
													$elm$html$Html$Attributes$class('nowrap'),
													$elm$html$Html$Attributes$class('align-center'),
													A2($elm$html$Html$Attributes$style, 'justify-content', 'space-between'),
													$elm$html$Html$Events$onClick(
													$author$project$NethysSearch$SortToggled(column))
												]),
											_List_fromArray(
												[
													A2(
													$elm$html$Html$div,
													_List_Nil,
													_List_fromArray(
														[
															$elm$html$Html$text(
															$author$project$NethysSearch$sortFieldToLabel(column))
														])),
													A2(
													$author$project$NethysSearch$getSortIcon,
													column,
													A2(
														$elm$core$Maybe$map,
														$elm$core$Tuple$second,
														A2(
															$elm_community$list_extra$List$Extra$find,
															A2(
																$elm$core$Basics$composeR,
																$elm$core$Tuple$first,
																$elm$core$Basics$eq(column)),
															model.sort)))
												])) : $elm$html$Html$text(
											$author$project$NethysSearch$sortFieldToLabel(column))
										]));
							},
							A2($elm$core$List$cons, 'name', model.tableColumns)))
					])),
				A2(
				$elm$html$Html$tbody,
				_List_Nil,
				$elm$core$List$concat(
					A2(
						$elm$core$List$map,
						function (result) {
							if (result.$ === 'Ok') {
								var r = result.a;
								return A2(
									$elm$core$List$map,
									function (hit) {
										return A2(
											$elm$html$Html$tr,
											_List_Nil,
											A2(
												$elm$core$List$map,
												A2($author$project$NethysSearch$viewSearchResultGridCell, model, hit),
												A2($elm$core$List$cons, 'name', model.tableColumns)));
									},
									r.hits);
							} else {
								return _List_Nil;
							}
						},
						model.searchResults)))
			]));
};
var $author$project$NethysSearch$nonEmptyList = function (list) {
	return $elm$core$List$isEmpty(list) ? $elm$core$Maybe$Nothing : $elm$core$Maybe$Just(list);
};
var $author$project$NethysSearch$viewLabel = function (text) {
	return A2(
		$elm$html$Html$span,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('bold')
			]),
		_List_fromArray(
			[
				$elm$html$Html$text(text)
			]));
};
var $author$project$NethysSearch$viewLabelAndText = F2(
	function (label, text) {
		return A2(
			$elm$html$Html$div,
			_List_Nil,
			_List_fromArray(
				[
					$author$project$NethysSearch$viewLabel(label),
					$elm$html$Html$text(' '),
					$author$project$NethysSearch$viewTextWithActionIcons(text)
				]));
	});
var $author$project$NethysSearch$viewLabelAndPluralizedText = F3(
	function (singular, plural, strings) {
		return A2(
			$author$project$NethysSearch$viewLabelAndText,
			($elm$core$List$length(strings) > 1) ? plural : singular,
			A2($elm$core$String$join, ', ', strings));
	});
var $author$project$NethysSearch$viewSearchResultAdditionalInfo = function (hit) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('column'),
				$elm$html$Html$Attributes$class('gap-tiny')
			]),
		A2(
			$elm$core$List$append,
			A2(
				$elm$core$Maybe$withDefault,
				_List_Nil,
				A2(
					$elm$core$Maybe$map,
					$elm$core$List$singleton,
					A2(
						$elm$core$Maybe$map,
						A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Source', 'Sources'),
						$author$project$NethysSearch$nonEmptyList(hit.source.sources)))),
			function () {
				var _v0 = hit.source.category;
				switch (_v0) {
					case 'action':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Frequency'),
									hit.source.frequency),
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Trigger'),
									hit.source.trigger),
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Requirements'),
									hit.source.requirements)
								]));
					case 'ancestry':
						return _List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('HP'),
											hit.source.hp),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Size'),
											A2(
												$elm$core$Maybe$map,
												$elm$core$String$join(' or '),
												$author$project$NethysSearch$nonEmptyList(hit.source.sizes))),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Speed'),
											hit.source.speed)
										]))),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Ability Bost', 'Ability Boosts'),
											$author$project$NethysSearch$nonEmptyList(hit.source.abilityBoosts)),
											A2(
											$elm$core$Maybe$map,
											A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Ability Flaw', 'Ability Flaws'),
											$author$project$NethysSearch$nonEmptyList(hit.source.abilityFlaws))
										])))
							]);
					case 'armor':
						return _List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Price'),
											hit.source.price),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('AC Bonus'),
											A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.ac)),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Dex Cap'),
											A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.dexCap)),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Check Penalty'),
											A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.checkPenalty)),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Speed Penalty'),
											hit.source.speedPenalty)
										]))),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Strength'),
											A2($elm$core$Maybe$map, $elm$core$String$fromInt, hit.source.strength)),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Bulk'),
											hit.source.bulk),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Armor Group'),
											hit.source.armorGroup)
										])))
							]);
					case 'background':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Ability', 'Abilities'),
									$author$project$NethysSearch$nonEmptyList(hit.source.abilities)),
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Feat', 'Feats'),
									$author$project$NethysSearch$nonEmptyList(hit.source.feats)),
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Skill', 'Skills'),
									$author$project$NethysSearch$nonEmptyList(hit.source.skills))
								]));
					case 'bloodline':
						return A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							A2(
								$elm$core$Maybe$map,
								$elm$core$List$singleton,
								A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Spell List'),
									hit.source.spellList)));
					case 'creature':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Creature Family'),
									hit.source.creatureFamily),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('HP'),
													hit.source.hp),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('AC'),
													A2($elm$core$Maybe$map, $elm$core$String$fromInt, hit.source.ac)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Fort'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.fort)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Ref'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.ref)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Will'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.will)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Perception'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.perception))
												])))),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Str'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.strength)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Dex'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.dexterity)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Con'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.constitution)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Int'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.intelligence)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Wis'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.wisdom)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Cha'),
													A2($elm$core$Maybe$map, $author$project$NethysSearch$numberWithSign, hit.source.charisma))
												])))),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Immunity', 'Immunities'),
													$author$project$NethysSearch$nonEmptyList(hit.source.immunities)),
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Resistance', 'Resistances'),
													$author$project$NethysSearch$nonEmptyList(hit.source.resistances)),
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Weakness', 'Weaknesses'),
													$author$project$NethysSearch$nonEmptyList(hit.source.weaknesses))
												])))),
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Speed'),
									hit.source.speed)
								]));
					case 'deity':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Divine Font'),
									$elm_community$string_extra$String$Extra$nonEmpty(
										A2($elm$core$String$join, ' or ', hit.source.divineFonts))),
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Divine Skill', 'Divine Skills'),
									$author$project$NethysSearch$nonEmptyList(hit.source.skills)),
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Favored Weapon', 'Favored Weapons'),
									$author$project$NethysSearch$nonEmptyList(hit.source.favoredWeapons)),
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Domain', 'Domains'),
									$author$project$NethysSearch$nonEmptyList(hit.source.domains))
								]));
					case 'domain':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Deity', 'Deities'),
									$author$project$NethysSearch$nonEmptyList(hit.source.deities)),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Domain Spell'),
													hit.source.domainSpell),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Advanced Domain Spell'),
													hit.source.advancedDomainSpell)
												]))))
								]));
					case 'eidolon':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Tradition', 'Traditions'),
									$author$project$NethysSearch$nonEmptyList(hit.source.traditions))
								]));
					case 'equipment':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Price'),
									hit.source.price),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Hands'),
													hit.source.hands),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Usage'),
													hit.source.usage),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Bulk'),
													hit.source.bulk)
												])))),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Activate'),
													hit.source.activate),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Frequency'),
													hit.source.frequency),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Trigger'),
													hit.source.trigger)
												]))))
								]));
					case 'familiar':
						return A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							A2(
								$elm$core$Maybe$map,
								$elm$core$List$singleton,
								A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Ability Type'),
									hit.source.abilityType)));
					case 'familiar-specific':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Required Number of Abilities'),
									hit.source.requiredAbilities),
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Granted Ability', 'Granted Abilities'),
									$author$project$NethysSearch$nonEmptyList(hit.source.familiarAbilities))
								]));
					case 'feat':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Frequency'),
									hit.source.frequency),
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Prerequisites'),
									hit.source.prerequisites),
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Trigger'),
									hit.source.trigger),
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Requirements'),
									hit.source.requirements)
								]));
					case 'lesson':
						return A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							A2(
								$elm$core$Maybe$map,
								$elm$core$List$singleton,
								A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Lesson Type'),
									hit.source.lessonType)));
					case 'patron':
						return A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							A2(
								$elm$core$Maybe$map,
								$elm$core$List$singleton,
								A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Spell List'),
									hit.source.spellList)));
					case 'relic':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Aspect'),
									hit.source.aspect),
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Prerequisite'),
									hit.source.prerequisites)
								]));
					case 'ritual':
						return _List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Cast'),
											hit.source.actions),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Cost'),
											hit.source.cost),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Secondary Casters'),
											hit.source.secondaryCasters)
										]))),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Primary Check'),
											hit.source.primaryCheck),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Secondary Checks'),
											hit.source.secondaryChecks)
										]))),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Requirements'),
											hit.source.requirements)
										]))),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Range'),
											hit.source.range),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Targets'),
											hit.source.targets)
										]))),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Duration'),
											hit.source.duration)
										]))),
								A2(
								$elm$core$Maybe$withDefault,
								$elm$html$Html$text(''),
								A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Heightened'),
									$elm_community$string_extra$String$Extra$nonEmpty(
										A2($elm$core$String$join, ', ', hit.source.heighten))))
							]);
					case 'rules':
						return A2(
							$elm$core$Maybe$withDefault,
							_List_Nil,
							A2(
								$elm$core$Maybe$map,
								$elm$core$List$singleton,
								A2($elm$core$Maybe$map, $elm$html$Html$text, hit.source.breadcrumbs)));
					case 'spell':
						return $elm_community$maybe_extra$Maybe$Extra$values(
							_List_fromArray(
								[
									A2(
									$elm$core$Maybe$map,
									A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Tradition', 'Traditions'),
									$author$project$NethysSearch$nonEmptyList(hit.source.traditions)),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Bloodline', 'Bloodlines'),
													$author$project$NethysSearch$nonEmptyList(hit.source.bloodlines)),
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Domain', 'Domains'),
													$author$project$NethysSearch$nonEmptyList(hit.source.domains)),
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Mystery', 'Mysteries'),
													$author$project$NethysSearch$nonEmptyList(hit.source.mysteries)),
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Patron Theme', 'Patron Themes'),
													$author$project$NethysSearch$nonEmptyList(hit.source.patronThemes)),
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Deity', 'Deities'),
													$author$project$NethysSearch$nonEmptyList(hit.source.deities))
												])))),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Cast'),
													hit.source.actions),
													A2(
													$elm$core$Maybe$map,
													A2($author$project$NethysSearch$viewLabelAndPluralizedText, 'Component', 'Components'),
													$author$project$NethysSearch$nonEmptyList(hit.source.components)),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Trigger'),
													hit.source.trigger),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Requirements'),
													hit.source.requirements)
												])))),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Range'),
													hit.source.range),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Targets'),
													hit.source.targets),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Area'),
													hit.source.area)
												])))),
									$elm$core$Maybe$Just(
									A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('row'),
												$elm$html$Html$Attributes$class('gap-medium')
											]),
										$elm_community$maybe_extra$Maybe$Extra$values(
											_List_fromArray(
												[
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Duration'),
													hit.source.duration),
													A2(
													$elm$core$Maybe$map,
													$author$project$NethysSearch$viewLabelAndText('Saving Throw'),
													hit.source.savingThrow)
												])))),
									A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Heightened'),
									$elm_community$string_extra$String$Extra$nonEmpty(
										A2($elm$core$String$join, ', ', hit.source.heighten)))
								]));
					case 'weapon':
						return _List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Price'),
											hit.source.price),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Damage'),
											hit.source.damage),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Bulk'),
											hit.source.bulk)
										]))),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Hands'),
											hit.source.hands),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Range'),
											hit.source.range),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Reload'),
											hit.source.reload)
										]))),
								A2(
								$elm$core$Maybe$withDefault,
								$elm$html$Html$text(''),
								A2(
									$elm$core$Maybe$map,
									$author$project$NethysSearch$viewLabelAndText('Ammunition'),
									hit.source.ammunition)),
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('row'),
										$elm$html$Html$Attributes$class('gap-medium')
									]),
								$elm_community$maybe_extra$Maybe$Extra$values(
									_List_fromArray(
										[
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Category'),
											hit.source.weaponCategory),
											A2(
											$elm$core$Maybe$map,
											$author$project$NethysSearch$viewLabelAndText('Group'),
											hit.source.weaponGroup)
										])))
							]);
					default:
						return _List_Nil;
				}
			}()));
};
var $author$project$NethysSearch$viewTrait = function (trait) {
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('trait'),
				$author$project$NethysSearch$getTraitClass(trait)
			]),
		_List_fromArray(
			[
				$elm$html$Html$text(trait)
			]));
};
var $author$project$NethysSearch$viewSingleSearchResult = F2(
	function (model, hit) {
		var hasActionsInTitle = A2(
			$elm$core$List$member,
			hit.source.category,
			_List_fromArray(
				['action', 'creature-ability', 'feat']));
		return A2(
			$elm$html$Html$section,
			_List_fromArray(
				[
					$elm$html$Html$Attributes$class('column'),
					$elm$html$Html$Attributes$class('gap-small'),
					$elm$html$Html$Attributes$class('limit-width'),
					$elm$html$Html$Attributes$class('fill-width-with-padding')
				]),
			_List_fromArray(
				[
					A2(
					$elm$html$Html$h2,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('title')
						]),
					_List_fromArray(
						[
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('row'),
									$elm$html$Html$Attributes$class('gap-small'),
									$elm$html$Html$Attributes$class('align-center')
								]),
							_List_fromArray(
								[
									$author$project$NethysSearch$viewPfsIcon(
									A2($elm$core$Maybe$withDefault, '', hit.source.pfs)),
									A2(
									$elm$html$Html$a,
									_List_fromArray(
										[
											$elm$html$Html$Attributes$href(
											$author$project$NethysSearch$getUrl(hit.source)),
											$elm$html$Html$Attributes$target('_blank')
										]),
									_List_fromArray(
										[
											$elm$html$Html$text(hit.source.name)
										])),
									function () {
									var _v0 = _Utils_Tuple2(hit.source.actions, hasActionsInTitle);
									if ((_v0.a.$ === 'Just') && _v0.b) {
										var actions = _v0.a.a;
										return $author$project$NethysSearch$viewTextWithActionIcons(' ' + actions);
									} else {
										return $elm$html$Html$text('');
									}
								}()
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('title-type')
								]),
							_List_fromArray(
								[
									$elm$html$Html$text(hit.source.type_),
									function () {
									var _v1 = hit.source.level;
									if (_v1.$ === 'Just') {
										var level = _v1.a;
										return $elm$html$Html$text(
											' ' + $elm$core$String$fromInt(level));
									} else {
										return $elm$html$Html$text('');
									}
								}()
								]))
						])),
					model.showResultSpoilers ? A2(
					$elm$html$Html$h3,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('subtitle')
						]),
					_List_fromArray(
						[
							$elm$html$Html$text(
							A2(
								$elm$core$Maybe$withDefault,
								'',
								A2(
									$elm$core$Maybe$map,
									function (spoiler) {
										return 'May contain spoilers from ' + spoiler;
									},
									hit.source.spoilers)))
						])) : $elm$html$Html$text(''),
					model.showResultTraits ? A2(
					$elm$html$Html$div,
					_List_fromArray(
						[
							$elm$html$Html$Attributes$class('row')
						]),
					A2($elm$core$List$map, $author$project$NethysSearch$viewTrait, hit.source.traits)) : $elm$html$Html$text(''),
					model.showResultAdditionalInfo ? $author$project$NethysSearch$viewSearchResultAdditionalInfo(hit) : $elm$html$Html$text('')
				]));
	});
var $author$project$NethysSearch$viewSearchResults = function (model) {
	var total = A2(
		$elm$core$Maybe$map,
		function ($) {
			return $.total;
		},
		A2(
			$elm$core$Maybe$andThen,
			$elm$core$Result$toMaybe,
			$elm$core$List$head(model.searchResults)));
	var resultCount = $elm$core$List$sum(
		A2(
			$elm$core$List$map,
			$elm$core$Maybe$withDefault(0),
			A2(
				$elm$core$List$map,
				$elm$core$Maybe$map($elm$core$List$length),
				A2(
					$elm$core$List$map,
					$elm$core$Maybe$map(
						function ($) {
							return $.hits;
						}),
					A2($elm$core$List$map, $elm$core$Result$toMaybe, model.searchResults)))));
	return A2(
		$elm$html$Html$div,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('column'),
				$elm$html$Html$Attributes$class('gap-large'),
				$elm$html$Html$Attributes$class('align-center'),
				A2($elm$html$Html$Attributes$style, 'align-self', 'stretch'),
				A2($elm$html$Html$Attributes$style, 'min-height', '90vh'),
				A2($elm$html$Html$Attributes$style, 'padding-bottom', '8px')
			]),
		$elm$core$List$concat(
			_List_fromArray(
				[
					_List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('limit-width'),
								$elm$html$Html$Attributes$class('fill-width-with-padding')
							]),
						_List_fromArray(
							[
								function () {
								if (total.$ === 'Just') {
									if (total.a === 10000) {
										return $elm$html$Html$text(
											'Showing ' + ($elm$core$String$fromInt(resultCount) + ' of 10000+ results'));
									} else {
										var count = total.a;
										return $elm$html$Html$text(
											'Showing ' + ($elm$core$String$fromInt(resultCount) + (' of ' + ($elm$core$String$fromInt(count) + ' results'))));
									}
								} else {
									return $elm$html$Html$text('');
								}
							}()
							]))
					]),
					_Utils_eq(model.resultDisplay, $author$project$NethysSearch$Table) ? _List_fromArray(
					[
						A2(
						$elm$html$Html$div,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$class('fill-width-with-padding'),
								A2($elm$html$Html$Attributes$style, 'transition', 'max-width ease-in-out 0.2s'),
								model.limitTableWidth ? $elm$html$Html$Attributes$class('limit-width') : A2($elm$html$Html$Attributes$style, 'max-width', '100%')
							]),
						_List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('column'),
										$elm$html$Html$Attributes$class('gap-medium'),
										A2($elm$html$Html$Attributes$style, 'max-height', '95vh'),
										A2($elm$html$Html$Attributes$style, 'overflow', 'auto')
									]),
								_List_fromArray(
									[
										$author$project$NethysSearch$viewSearchResultGrid(model),
										function () {
										var _v1 = $elm_community$list_extra$List$Extra$last(model.searchResults);
										if ((_v1.$ === 'Just') && (_v1.a.$ === 'Err')) {
											if ((_v1.a.a.$ === 'BadStatus') && (_v1.a.a.a === 400)) {
												return A2(
													$elm$html$Html$h2,
													_List_Nil,
													_List_fromArray(
														[
															$elm$html$Html$text('Error: Failed to parse query')
														]));
											} else {
												return A2(
													$elm$html$Html$h2,
													_List_Nil,
													_List_fromArray(
														[
															$elm$html$Html$text('Error: Search failed')
														]));
											}
										} else {
											return $elm$html$Html$text('');
										}
									}(),
										$elm_community$maybe_extra$Maybe$Extra$isJust(model.tracker) ? A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('column'),
												$elm$html$Html$Attributes$class('align-center'),
												A2($elm$html$Html$Attributes$style, 'position', 'sticky'),
												A2($elm$html$Html$Attributes$style, 'left', '0'),
												A2($elm$html$Html$Attributes$style, 'padding-bottom', 'var(--gap-medium)')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$div,
												_List_fromArray(
													[
														$elm$html$Html$Attributes$class('loader')
													]),
												_List_Nil)
											])) : ((_Utils_cmp(
										resultCount,
										A2($elm$core$Maybe$withDefault, 0, total)) < 0) ? A2(
										$elm$html$Html$div,
										_List_fromArray(
											[
												$elm$html$Html$Attributes$class('column'),
												$elm$html$Html$Attributes$class('align-center'),
												A2($elm$html$Html$Attributes$style, 'position', 'sticky'),
												A2($elm$html$Html$Attributes$style, 'left', '0'),
												A2($elm$html$Html$Attributes$style, 'padding-bottom', 'var(--gap-medium)')
											]),
										_List_fromArray(
											[
												A2(
												$elm$html$Html$button,
												_List_fromArray(
													[
														$elm$html$Html$Events$onClick($author$project$NethysSearch$LoadMorePressed)
													]),
												_List_fromArray(
													[
														$elm$html$Html$text('Load more')
													]))
											])) : $elm$html$Html$text(''))
									]))
							]))
					]) : $elm$core$List$concat(
					_List_fromArray(
						[
							$elm$core$List$concat(
							A2(
								$elm$core$List$map,
								function (result) {
									if (result.$ === 'Ok') {
										var r = result.a;
										return A2(
											$elm$core$List$map,
											$author$project$NethysSearch$viewSingleSearchResult(model),
											r.hits);
									} else {
										if ((result.a.$ === 'BadStatus') && (result.a.a === 400)) {
											return _List_fromArray(
												[
													A2(
													$elm$html$Html$h2,
													_List_Nil,
													_List_fromArray(
														[
															$elm$html$Html$text('Error: Failed to parse query')
														]))
												]);
										} else {
											return _List_fromArray(
												[
													A2(
													$elm$html$Html$h2,
													_List_Nil,
													_List_fromArray(
														[
															$elm$html$Html$text('Error: Search failed')
														]))
												]);
										}
									}
								},
								model.searchResults)),
							$elm_community$maybe_extra$Maybe$Extra$isJust(model.tracker) ? _List_fromArray(
							[
								A2(
								$elm$html$Html$div,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$class('loader')
									]),
								_List_Nil)
							]) : ((_Utils_cmp(
							resultCount,
							A2($elm$core$Maybe$withDefault, 0, total)) < 0) ? _List_fromArray(
							[
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$NethysSearch$LoadMorePressed),
										A2($elm$html$Html$Attributes$style, 'align-self', 'center')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Load more')
									]))
							]) : _List_Nil),
							(resultCount > 0) ? _List_fromArray(
							[
								A2(
								$elm$html$Html$button,
								_List_fromArray(
									[
										$elm$html$Html$Events$onClick($author$project$NethysSearch$ScrollToTopPressed),
										A2($elm$html$Html$Attributes$style, 'align-self', 'center')
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('Scroll to top')
									]))
							]) : _List_Nil
						]))
				])));
};
var $elm$html$Html$h1 = _VirtualDom_node('h1');
var $elm$html$Html$header = _VirtualDom_node('header');
var $author$project$NethysSearch$viewTitle = function (model) {
	return A2(
		$elm$html$Html$header,
		_List_fromArray(
			[
				$elm$html$Html$Attributes$class('column'),
				$elm$html$Html$Attributes$class('align-center'),
				$elm$html$Html$Attributes$class('limit-width')
			]),
		_List_fromArray(
			[
				A2(
				$elm$html$Html$h1,
				_List_Nil,
				_List_fromArray(
					[
						A2(
						$elm$html$Html$a,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$href('?')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Nethys Search')
							]))
					])),
				A2(
				$elm$html$Html$div,
				_List_Nil,
				_List_fromArray(
					[
						$elm$html$Html$text('Search engine for '),
						A2(
						$elm$html$Html$a,
						_List_fromArray(
							[
								$elm$html$Html$Attributes$href('https://2e.aonprd.com/'),
								$elm$html$Html$Attributes$target('_blank')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('2e.aonprd.com')
							]))
					])),
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('option-container'),
						A2($elm$html$Html$Attributes$style, 'margin-top', '16px'),
						$elm$html$Html$Attributes$class('column'),
						$elm$html$Html$Attributes$class('gap-small')
					]),
				_List_fromArray(
					[
						A2(
						$elm$html$Html$h2,
						_List_fromArray(
							[
								A2($elm$html$Html$Attributes$style, 'align-self', 'center')
							]),
						_List_fromArray(
							[
								$elm$html$Html$text('Nethys Search has now been integrated to the Archives of Nethys')
							])),
						A2(
						$elm$html$Html$div,
						_List_Nil,
						_List_fromArray(
							[
								$elm$html$Html$text('This page will not receive updates in the future, use the '),
								A2(
								$elm$html$Html$a,
								_List_fromArray(
									[
										$elm$html$Html$Attributes$href(
										'https://2e.aonprd.com/Search.aspx?' + A2($elm$core$Maybe$withDefault, '', model.url.query))
									]),
								_List_fromArray(
									[
										$elm$html$Html$text('search page on AoN')
									])),
								$elm$html$Html$text(' instead. Thank you for your continued support!')
							]))
					]))
			]));
};
var $author$project$NethysSearch$view = function (model) {
	return A2(
		$elm$html$Html$div,
		_List_Nil,
		_List_fromArray(
			[
				A3(
				$elm$html$Html$node,
				'style',
				_List_Nil,
				_List_fromArray(
					[
						$elm$html$Html$text($author$project$NethysSearch$css),
						function () {
						var _v0 = model.theme;
						switch (_v0.$) {
							case 'Dark':
								return $elm$html$Html$text($author$project$NethysSearch$cssDark);
							case 'Light':
								return $elm$html$Html$text($author$project$NethysSearch$cssLight);
							case 'Paper':
								return $elm$html$Html$text($author$project$NethysSearch$cssPaper);
							case 'ExtraContrast':
								return $elm$html$Html$text($author$project$NethysSearch$cssExtraContrast);
							default:
								return $elm$html$Html$text($author$project$NethysSearch$cssLavender);
						}
					}()
					])),
				$lattyware$elm_fontawesome$FontAwesome$Styles$css,
				A2(
				$elm$html$Html$div,
				_List_fromArray(
					[
						$elm$html$Html$Attributes$class('body-container'),
						$elm$html$Html$Attributes$class('column'),
						$elm$html$Html$Attributes$class('align-center'),
						$elm$html$Html$Attributes$class('gap-large')
					]),
				A2(
					$elm$core$List$append,
					model.showHeader ? _List_fromArray(
						[
							A2(
							$elm$html$Html$button,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('menu-open-button'),
									$elm$html$Html$Events$onClick(
									$author$project$NethysSearch$ShowMenuPressed(true)),
									$elm$html$Html$Events$onMouseOver(
									$author$project$NethysSearch$ShowMenuPressed(true))
								]),
							_List_fromArray(
								[
									$lattyware$elm_fontawesome$FontAwesome$Icon$viewIcon($lattyware$elm_fontawesome$FontAwesome$Solid$bars)
								])),
							A2(
							$elm$html$Html$div,
							_List_fromArray(
								[
									$elm$html$Html$Attributes$class('menu-overlay'),
									A2(
									$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
									!model.menuOpen,
									$elm$html$Html$Attributes$class('menu-overlay-hidden')),
									$elm$html$Html$Events$onClick(
									$author$project$NethysSearch$ShowMenuPressed(false)),
									A2(
									$elm_community$html_extra$Html$Attributes$Extra$attributeIf,
									model.overlayActive,
									$elm$html$Html$Events$onMouseOver(
										$author$project$NethysSearch$ShowMenuPressed(false)))
								]),
							_List_Nil),
							$author$project$NethysSearch$viewMenu(model)
						]) : _List_Nil,
					_List_fromArray(
						[
							model.showHeader ? $author$project$NethysSearch$viewTitle(model) : $elm$html$Html$text(''),
							$author$project$NethysSearch$viewQuery(model),
							$author$project$NethysSearch$viewSearchResults(model)
						])))
			]));
};
var $author$project$NethysSearch$main = $elm$browser$Browser$element(
	{init: $author$project$NethysSearch$init, subscriptions: $author$project$NethysSearch$subscriptions, update: $author$project$NethysSearch$update, view: $author$project$NethysSearch$view});
_Platform_export({'NethysSearch':{'init':$author$project$NethysSearch$main($elm$json$Json$Decode$value)(0)}});}(this));