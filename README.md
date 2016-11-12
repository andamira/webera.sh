# webera

A versatile shellscript for static website generation

## Features

- process static resources
- define custom commands
- optional logging
- web browser preview
- template tags for:
  - template nesting
  - setting variables
  - commands outputting

## Quick Start

At a minimum you need to associate the templates with the routes in the `.weberarc` file *(there are some examples)* and create the corresponding html template files in the `html/` directory.

You can also define some resources (e.g. css, javascript) to be processed and/or copied from the `res/` directory to the `html/res` directory

All the important default settings, files and directories can be overriden by using arguments when calling the script.

## Examples using arguments

| example           | what it does  |
| ----------------- | ------------- |
| `./webera.sh`     | Usage         |
| `./webera.sh -tr` | Process `t`emplates and `r`esources |
| `./webera.sh -r -L2` | Process resources and output a level 2 `L`ogfile |
| `./webera.sh -tw -T tpl -O out` | Process templates using custom directories, and previe`w` using the default browser ([Firefox](https://www.mozilla.org/firefox/products/)) |
| `./webera.sh -trw -W chromium-browser` | Process templates and resources, and preview using Chromium `W`eb browser |

