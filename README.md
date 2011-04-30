Alpinist
========

### A minimalistic web server designed to simplify difficult web projects.

> Alpinism is a minimalistic approach to climbing difficult routes in high
mountain ranges. The focus is on climbing quickly, efficiently, and with little
trace of passing.

*Alpinist* is a web server toolkit created under the same philosophies. Alpinist
runs on Node.js, because event driven IO is the lightest and most efficient way
to move data over a network.

This is not a framework, but a toolkit of utilities which can be quickly and
easily configured into a web server or integrated into an existing project.

Instead of using straight JavaScript, Alpinist is implemented in
[CoffeeScript](http://jashkenas.github.com/coffee-script/), a lightweight
language which compiles to JavaScript. CoffeeScript provides a cleaner syntax
and promotes a more expressive style of coding which makes development and
maintenance easier.

Development Quick Start
------------------------

### Clone the repository

    git clone git://github.com/kixxauth/alpinist.git

It includes git submodules pointing to coffee-script, jasmine-node, and nave
(see below).

### Install Node.js
Node.js project source page: [github.com/joyent/node](https://github.com/joyent/node)

You'll need `version >= 0.4.7`

Using *nave* the virtual Node.js environment, is recommended for Node.js
installations. Nave allows you to keep many versions of Node.js installed on a
single machine for easy access to any version of Node.js at your fingertips.
This is a fantastic way to ease the pain of dealing with a fast moving platform
under heavy development.

For more about Nave, see the [project page](https://github.com/isaacs/nave).
Nave is included as a git submodule in this project and is available in
bin/nave after you initialize the repository.

### Easy breezy development commands
Initialize the project with:

    cd alpinist/
    bin/init

And run the tests with

    bin/cake test

### Update the repository
Your git repository may be periodically updated with

    bin/cake update

This will pull the latest remote changes from the git submodule repositories
and reconfigure this repository for them.

*Warning!* Updating your repository can cause things to break because it pulls
in the latest changes from all the dependency submodules. Dependency projects
like to change the way things work and when these changes are pulled into your
repo it will likely cause you pain. So...

__Don't do `bin/cake update` on your master branch.__

### .gitignore
! Note that JS files (`*.js`) are *not* tracked, since all JS source code is
written in CoffeeScript (`*.coffee`).

### README
Checkout the README files in
[bin/](bin/) and [spec/](spec/)


### FIN
__That's all so far... more soon__

Copyright and License
---------------------
copyright: (c) 2011 by Kris Walker (kris@kixx.name).

Unless otherwise indicated, all source code is licensed under the MIT license.
See MIT-LICENSE for details.
