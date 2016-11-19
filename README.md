# webera

A versatile static website generator made in Bash

## Features

- process static resources  <i id="css" title="CSS"></i><i id="js" title="Javascript"></i><i id="woff2" title="Fonts"></i>
- define custom commands <i id="sass" title ="Sass"></i><i id="markdown" title="Markdown"></i>
- define custom workflows
- define custom tags
- local web browser preview
- template tags for:
  - template nesting
  - setting variables
  - commands outputting

## Quick Start

At a minimum you need to associate the templates with the routes in the `.weberarc` configuration file, and create the corresponding HTML template files under the `tem/` directory.

You can also define some resources (e.g. css, javascript) to be processed and/or copied from the `res/` directory to the `out/res/` directory

All the important default settings, files and directories can be overriden either by passing arguments to the script, or by modifying the config file.

## Examples

### CLI Usage

<table><thead>

<tr>
<th>example</th>
<th>what it does</th>
</tr>

</thead><tbody>

<tr>
<td><code>./webera -tr</code></td>
<td>Process <b>t</b>emplates and <b>r</b>esources</td>
</tr>

<tr>
<td><code>./webera -r -O out2/ -L2</code></td>
<td>Process resources to a custom <b>O</b>utput directory, and output a level 2 <b>L</b>ogfile</td>
</tr>

<tr>
<td><code>./webera -trw -W vivaldi</code></td>
<td>Process templates and resources, and preview using custom bro<b>W</b>ser</td>
</tr>

</tbody></table>


## Here Be Dragons

This project is not considered stable, and anything can change at any moment.
