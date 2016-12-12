# webera [![version: 0.1.X](https://img.shields.io/badge/version-0.1.X-yellow.svg?style=flat-square)](#status) [![language: bash](https://img.shields.io/badge/language-bash-blue.svg?style=flat-square)]() [![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/andamira/webera/blob/master/LICENSE.md) [![Build Status](https://img.shields.io/travis/andamira/webera/master.svg?style=flat-square)](https://travis-ci.org/andamira/webera) [![Code Climate](https://img.shields.io/codeclimate/github/andamira/webera.svg?style=flat-square)](https://codeclimate.com/github/andamira/webera)

Is a handy, reliable and versatile script that generates static websites.

It relies on common utilities (grep, sed, awk, coreutils) to do its job.

---

**Index**

- [Features](#features)
- [Quick Start](#quick-start)
- [Examples](#examples)
  - [Usage](#usage)
  - [Config](#config)
- [Reason](#reason)
- [Status](#status)

---

## Features

- A flexible configurable system to process content templates and static resources, allowing for custom commands and workflows.
- Content template directives for: template nesting, variable setting, command output, among others.
- Logging system and browser preview.
- Unit testing and code quality control as an integral part of the development process.


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

Create a stylesheet into `res/css/style.css` for example, and process it like this:

```
resource : copy : css/ : css/
```

Generate the website, from the templates and the resources.

```sh
$ ./webera -tr

```

It gets saved into the `out/` directory by default:
```
$ find out/

  out/
  out/index.html
  out/other-url/index.html
  out/res/css/style.css
```

## Examples

You can find several example's source in the [examples/](https://github.com/andamira/webera/tree/master/examples) directory, rendered by webera in the [docs/](https://github.com/andamira/webera/tree/master/docs) directory and visible as a website in the [github page of the project](https://andamira.github.io/webera/examples/).

### Config

This is an example of a project's configuration file.

```bash
# Customize Settings
config : WEB_BROWSER_BIN : chromium-browser
config : DIR_OUTPUT      : /home/$USER/my-website

# Define Custom Commands
command : sass2css : sass {ORIGIN} {TARGET}

# Process Resources
resource : sass2css : scss/styles.scss : css/main.css

# Process Templates to URL Endpoints
template : route : index.html     : /
template : route : about.html     : /about/
template : route : about-me.html  : /about/me/
template : route : about-you.html : /about/you.html
```

See [`.weberarc`](https://github.com/andamira/webera/blob/master/.weberarc) for more configuration possibilities.


### Usage

These are several examples on running the script. The characters in bold indicate a mnemonic relationship between the name of the action triggered and the flag used.

<table><tbody>

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
  directory and to a custom <strong>O</strong>utput directory</td>
</tr>

<tr>
  <td><code>./webera -nC conf/webera.conf</code></td>

  <td>Generate a <strong>n</strong>ew configuration to a custom
    <strong>C</strong>onfig file</td>
</tr>

</tbody></table>

Run `./webera -h` for more usage flags.


## Reason

The script was originally inspired by [Statix](https://gist.github.com/plugnburn/c2f7cc3807e8934b179e), [suckless philosophy](http://suckless.org/philosophy) and [Unix philosophy](), 

The intention is to see how far the original idea can be taken, given the limits of a shell script, and to try to achive a good balance between features, reliability, simplicity and handiness.


## Status

This project is not stable yet. Anything can change at any moment.
