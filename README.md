# webera

is a simple, handy & versatile shellscript for static website generation 

It follows the [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) and depends on common tools like grep, sed, awk and coreutils to do its job.


## Features

- process templates and static resources
- preview the generated website locally
- define custom commands and workflows
- use HTML template directives:
	- declare variables
	- nest templates
	- run commands

## Quick Start

To start using webera you really only *need* to download the [webera script](https://raw.githubusercontent.com/andamira/webera/master/webera) and make it executable:

```sh
wget raw.githubusercontent.com/andamira/webera/master/webera && chmod +x webera
```

You can generate (`webera -n`), [download](https://raw.githubusercontent.com/andamira/webera/master/.weberarc) or write a new configuration file for your project.

Then put the templates in the `tem/` directory, and add the corresponding routes in the `.weberarc` config file:

```
template : route : index.html   : /
```

Finally generate the website in the `out` directory, and preview it in firefox:

```sh
./webera -tw
```

## Examples

You can find several [generated examples here](https://andamira.github.io/webera/examples/)
and their original source in the [examples/](https://github.com/andamira/webera/tree/master/examples) directory.

### Usage Examples

| example                         | what it does |
| ------------------------------- | ------------ |
| `./webera -t -cL2`              | Process **t**emplates and write a level 2 **L**ogfile, clearing any previous logfile first |
| `./webera -trw -W vivaldi`      | Process templates and resources; and preview using another bro**W**ser |
| `./webera -r -R resB/ -O outB/` | Process resources from a custom **R**esources directory, and also to a custom **O**utput directory |
| `./webera -nC conf/webera.conf` | Generate a **n**ew configuration, to a custom **C**onfig file |

### Configuration Example

```bash
# Customize Settings
config : WEB_BROWSER_BIN : google-chrome
config : DIR_OUTPUT      : /home/website/public_html

# Define Custom commands
define_cmd : sass:sass -t compact {ORIGIN} {TARGET}

# Process resources
resource : sass : scss/styles.scss : css/main.css

# Process templates to URL endpoints
template : route : index.html   : /
template : route : about.html   : /about-me/
```

See [`.weberarc`](https://github.com/andamira/webera/blob/master/.weberarc) for more options.

## Planned Features

- define custom directives
- manage blog | custom post types
- generate navigation menus

[See open features](https://github.com/andamira/webera/issues?q=is%3Aissue+is%3Aopen+label%3A%22type%3A+feature%22)

## Here Be Dragons

This project is not considered stable yet, and anything can change at any moment, including features, paths, and syntax.
