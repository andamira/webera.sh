# webera

A handy, transparent and versatile shellscript for static website generation.

It follows the [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy) and uses common unix commands (grep, sed, awk) to do its job.

You can download the small script wherever there is Bash, and use it to create your website.

## Features

- Custom commands and workflows for processing templates and static resources
- Template directives for:
	- outputting commands
	- nesting templates
	- setting variables
- Flexible configuration
- Decent logging system
- Adaptable browser preview

## Quick Start

The simplest way to start is to download the [webera script](https://raw.githubusercontent.com/andamira/webera/master/webera) and make it executable.

```sh
wget raw.githubusercontent.com/andamira/webera/master/webera && chmod +x webera
```

You can generate (`webera -n`) or [download](https://raw.githubusercontent.com/andamira/webera/master/.weberarc) a new example configuration file for the project.

Just place the templates inside the `tem/` directory, and configure the corresponding routes in the `.weberarc` config file, like this:

```
template : route : index.html   : /
```

And generate the website. It will be created in the `out` directory by default.

```sh
./webera -tr
```

## Examples

You can find several [rendered examples here](https://andamira.github.io/webera/examples/)
and their original source in the [examples/](https://github.com/andamira/webera/tree/master/examples) directory.

### Usage

| example                         | what it does |
| ------------------------------- | ------------ |
| `./webera -t -cL2`              | Process **t**emplates and write a level 2 **L**ogfile, clearing any previous logfile first |
| `./webera -trw -W vivaldi`      | Process templates and resources; and preview using another bro**W**ser |
| `./webera -r -R resB/ -O outB/` | Process resources from a custom **R**esources directory, and also to a custom **O**utput directory |
| `./webera -nC conf/webera.conf` | Generate a **n**ew configuration, to a custom **C**onfig file |

### Configuration

```bash
# Customize Settings
config : WEB_BROWSER_BIN : google-chrome
config : DIR_OUTPUT      : /home/$USER/my-website

# Define Custom commands
command : sass2css : sass {ORIGIN} {TARGET}

# Process resources
resource : sass2css : scss/styles.scss : css/main.css

# Process templates to URL endpoints
template : route : index.html     : /
template : route : about.html     : /about/
template : route : about-me.html  : /about/me/
template : route : about-you.html : /about/you.html
```

See [`.weberarc`](https://github.com/andamira/webera/blob/master/.weberarc) for more options.

## Here Be Dragons

This project is not yet near stable. That means anything can change at any moment, including existing features, defaults and syntax.
