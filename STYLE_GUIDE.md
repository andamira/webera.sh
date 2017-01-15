# webera style guide


## Format and Indentation

 * Tabs for indendation, spaces for alignment. (See FAQ: why tabs?)
 * A tab size of 4 characters.
 * Unix line endings.

NOTE: An `.editorconfig` file is provided to aid with the whitespace.


## Naming


### Files

In lower case `lisp-case`: words separated with dashes.


### Variables

* In `snake_case`, words separated with underscores.
* Different casing is used to convey different meanings,
as well as the number of prefixing underscores:

* `snake_case`      : local variables
* `_snake_case`     : parent's local variable, explicitly re-declared as such
* `__snake_case`    : readonly local variables

* `Cobra_case`      : pseudo-global variables (declared in ::main)
* `__Cobra_case`    : readonly pseudo-global variables

* `ANACONDA_CASE`   : environment variables
* `__ANACONDA_CASE` : environment readonly variables

Special case with prefixes `Opt_` & `_Opt`:

* `Opt_cobra_case`  : a configuration option, modifiable from the config file,
                      From which it can be referenced using insensitive
                      SNAKE_CASE, and removing the `Opt_` prefix.
* `_Opt_cobra_case` : a private configuration option, unmodifiable from the
                      config file, but only using script arguments.

NOTE: The only global variable is `__WEBERA_VERSION`.


### Functions

* In lower case `lisp-case`: words separated with dashes,
  and prefixed with the `webera::` namespace.

* Function are preferably named starting with the verb,
  then the object and the modifiers.

* All code must be inside functions


## Comments

Comments can be placed in its own line or at the end of the line.
But they must be concise and clear.


### Functions

All functions have an outer margin of one newline at the top
and another one at the bottom.

All multi-line functions have an inner padding of one newline at the top
and another one at the bottom, too.

All multi-line functions have a comment after the closing bracket,
showing the short function name (without the namespace prefix):

```
} # ::function-name
```

All functions start with a doc string block formatted as described below.

- First line is a dashed line as long as the line length limit
- Second line is the short name of the function (without the namespace prefix):
- Then comes the function description, surrounded by empty comment lines,
  and padded left with 2 spaces.

```
#------------------------------------------------------------------------------
# ::function-name
#
#   The description of the function...
#   ... can be multiline
#
```

After that, a block that describes the arguments, the return and exit values,
and the parents functions, if possible.

```
>  $1 : first argument description
>  $2 : second argument description
<  22 : return value description
x 119 : exit value description
^ ::parent-function ::other-parent-function
```

At the beginning of the function code, the local declarations, described.
Although descriptions can be

```
  local arg_one="$1" arg_two="$2" # no need to repeat the description

  local    bar  # the purpose of bar
  local -i foo  # the purpose of foo
```


NOTE: Very short functions can also be written in one line:

```
webera::one-line-function() { echo "a-very-short-function"; }
```


## Brackets

Each opening bracket goes in the same line as the statement, and
ending braces lines up with the statement they belong to.

This is called "the one true brace style"
[(1TBS)](https://en.wikipedia.org/wiki/Indent_style#Variant:_1TBS_.28OTBS.29)

