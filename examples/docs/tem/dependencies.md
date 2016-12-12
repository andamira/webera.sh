<!-- %set:TITLE=webera dependencies-->
<!-- %include:common/head.html-->

= Webera Dependencies

By leveraging the Unix Philosophy, webera depends on several unix programs:

* Bash
  - Version >= 4 ([v4 changes](http://wiki.bash-hackers.org/bash4), [+ changes](http://wiki.bash-hackers.org/scripting/bashchanges))
    - associative arrays: `declare -A`
    - `&>>` (equiv. to `>>FILE 2>&1`)
    - `;;&` case terminator
    - `[[ ]]` double squared brackets conditionals
    - `==` double equal test operators
* grep
  - At the moment, it must have support for PCRE (`--perl-regexp` argument).
  - It may be possible to substitute this requirement by using awk.
* coreutils
  - cat
  - cut
  - dirname
  - env
  - head
  - readlink
  - touch
  - tr
  - uniq
  - wc
* awk
  - Only old awk syntax is used [not verified exhaustly]
  - Verify compatibility.
* sed

  <ul class="examples-list">
    <!-- %cmd: for F in $(find ../[0-9]* -maxdepth 0 -type d | sed 's/^\.\.\///'); do echo "<li><a href=\"$F\">$F</a></li>"; done -->
  </ul>

<!--%include:common/footer.html-->
