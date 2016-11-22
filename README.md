# webera

is a versatile static website generator made in Bash

## Features

- process templates and static resources
- website preview in local web browser
- define custom commands and workflows
- template directives allowing you to
    - declare variables
    - nest templates
    - run commands

## Quick Start

In `.weberarc` you can route the HTML templates present under `tem/` and the final URL endpoints will be created in `out/`.

There you can also process and/or copy resources (e.g. css, javascript) from `res/` to the output `out/res/` directory

All the settings can be overriden either from the config file or by passing arguments to the script.

## Examples

You can find several complete examples in the [examples/](https://github.com/andamira/webera/tree/master/examples) directory, and their generated output in [andamira.github.io/webera/examples/](https://andamira.github.io/webera/examples/)

### Usage Examples

| example                           | what it does |
| --------------------------------- | ------------ |
| `./webera.sh -tr`                 | Process **t**emplates and **r**esources |
| `./webera.sh -r -R tmp-res/ -cL2` | Process resources from a custom **R**esources dir; while writing a level 2 **L**ogfile, after clearing the previous first |
| `./webera.sh -trw -W vivaldi`     | Process templates and resources; and preview using a custom bro**W**ser |

### Configuration Example

`.weberarc`:
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

## Planned Features

- define custom directives
- manage blog | custom post types
- generate navigation menus

## Here Be Dragons

This project is not considered stable yet, and anything can change at any moment, including but not limited to: features, syntax and filepaths.
