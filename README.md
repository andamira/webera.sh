# webera [![language: bash](https://img.shields.io/badge/language-bash-blue.svg?style=flat-square)]() [![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/andamira/webera/blob/master/LICENSE.md) [![Build Status](https://img.shields.io/travis/andamira/webera/master.svg?style=flat-square)](https://travis-ci.org/andamira/webera) [![Code Climate](https://img.shields.io/codeclimate/github/andamira/webera.svg?style=flat-square)](https://codeclimate.com/github/andamira/webera)

Is a handy shellscript to help you create static websites.

Its purpose is to be like a swiss knife: a versatile tool in a small package.

It depends on Bash 4 alongside common unix commands (grep, sed, awk) to do its job.

It's originally Inspired by [Statix](https://gist.github.com/plugnburn/c2f7cc3807e8934b179e).

**Index**

- [Features](#features)
- [Quick Start](#quick-start)
- [Examples](#examples)
  - [Usage](#usage)
  - [Config](#config)
- [Stability](#here-be-dragons)

---

## Features

- Custom commands and workflows for processing templates and static resources
- Template directives for:
  - outputting commands
  - nesting templates
  - setting variables
- Flexible configuration
- Decent logging system
- Browser preview


## Quick Start

The simplest way to start is to download the [script](https://raw.githubusercontent.com/andamira/webera/master/webera) and make it executable.

```sh
wget raw.githubusercontent.com/andamira/webera/master/webera && chmod +x webera
```

You can generate a new config file (`webera -n`) or [download](https://raw.githubusercontent.com/andamira/webera/master/.weberarc) the one in the repo.

Place your templates in the `tem/` directory, and configure the corresponding routes in the `.weberarc` config file, like this:

```
template : route : my-index.html   : /
template : route : other-page.html : /other-url/
```

Then generate the website, to the `out/` directory by default:

```sh
./webera -tr
```

## Examples

You can find several [rendered examples here](https://andamira.github.io/webera/examples/)
and their original source in the [examples/](https://github.com/andamira/webera/tree/master/examples) directory.


### Usage

<table>
<thead>

<tr>
  <th>example</th>
  <th>what it does</th>
</tr>

</thead>
<tbody>

<tr>
  <td><code>./webera -t -cL2</code></td>

  <td>Process <strong>t</strong>emplates and write a level 2
  <strong>L</strong>ogfile, clearing any previous logfile first</td>
</tr>

<tr>
  <td><code>./webera -trw -W vivaldi</code></td>

  <td>Process templates and resources; and preview using
  another bro<strong>W</strong>ser</td>
</tr>

<tr>
  <td><code>./webera -r -R resB/ -O outB/</code></td>

  <td>Process resources from a custom <strong>R</strong>esources
  directory, and also to a custom <strong>O</strong>utput directory</td>
</tr>

<tr>
  <td><code>./webera -nC conf/webera.conf</code></td>

  <td>Generate a <strong>n</strong>ew configuration, to a custom
    <strong>C</strong>onfig file</td>
</tr>

</tbody></table>

Run `./webera -h` for more usage flags.

### Config

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

See [`.weberarc`](https://github.com/andamira/webera/blob/master/.weberarc) for more config options.


## Here Be Dragons

This project is not stable yet. Anything can change at any moment.
