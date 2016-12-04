# webera

is a simple, handy & versatile shellscript for static website generation 

It follows the [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) and depends on common tools like grep, sed, awk and coreutils to do its job.

You can download the small script wherever there is Bash, and start creating your website.

## Features

- Custom commands and workflows for templates and static resources
- Template directives for:
	- outputting commands
	- nesting templates
	- setting variables
- Configuration files
- Logging system
- Preview

## Quick Start

The simplest way to start is to download the [webera script](https://raw.githubusercontent.com/andamira/webera/master/webera) and make it executable.

```sh
wget raw.githubusercontent.com/andamira/webera/master/webera && chmod +x webera
```

Then you can generate (`webera -n`) or [download](https://raw.githubusercontent.com/andamira/webera/master/.weberarc) a new configuration file for your project.

Place the templates inside the `tem/` directory, and configure the corresponding routes in the `.weberarc` config file, like this:

```
template : route : index.html   : /
```

Finally generate the website in the `out` directory, by default.

```sh
./webera -tr
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
command : sass2css : sass {ORIGIN} {TARGET}

# Process resources
resource : sass2css : scss/styles.scss : css/main.css

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
