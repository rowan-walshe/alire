[![Run Status](https://api.shippable.com/projects/5ac50b3494f2af07000852d9/badge?branch=master)](https://app.shippable.com/github/alire-project/alr)

# ALR #

ALIRE: Ada LIbrary REpository.

A catalog of ready-to-use Ada libraries plus a command-line tool (`alr`) to obtain, compile, and incorporate them into your own projects. It aims to fulfill a similar role to Rust's `cargo` or OCaml's `opam`.

### Caveat emptor ###

Documentation at this time is minimal. Expect further efforts in this direction until this warning is removed.

## Design principles ##

alr is tailored to userspace. It is not nor wants to be a package manager; it stores information in the user's configuration and cache folders within its home. Target projects are created/downloaded wherever the user wants them; any dependencies will be stored in a caching folder where they are reused by any dependent projects, thus saving space and compilation times.

The only exception is when a native package is needed by a project, in which case the user will be requested to authorize it with the plaform package manager (`apt` is the only one supported at this time) by granting sudo privileges. Thus, `alr` cannot damage your installation (unless you have conflicting repositories already, of course). 

Every project is independent from the rest, so broken configurations should not happen, or at most be confined to the project requesting an impossible combination; 

Dependencies of a project are managed through an Ada specification file that must be compiled with `alr`. `alr` generates an initial file for the user that can be modified to reflect the project dependencies. More information on this point coming soon.

The complete build environment is set up with another file generated by `alr` for every project: a GNAT aggregate project that specifies the paths of necessary dependencies, thus freeing the user from concerns about installation paths. The user simply adds the used projects to its own project GPR file with their simple name.

## Supported platforms ##
Alire has been tested on the stock GNAT compiler of Debian testing and Ubuntu 17.10, as well as with GNAT GPL 2017 edition.

Alire is known _not_ to work in current Debian 9 stable or any earlier versions of Ubuntu stock compilers.

Note that, for projects that require platform-provided Ada libraries (such as Debian's GtkAda), the compiler in use must be the platform-provided one too (at the time of writing, GNAT 7.2 from Debian Testing or Ubuntu 17.10). This is a consequence of GNAT/ali/object file consistency checks.

## Installation ##
Copy, paste and execute in a terminal as a regular user the following command:

    curl https://raw.githubusercontent.com/alire-project/alr/master/install/alr-bootstrap.sh -o ./alr-bootstrap.sh && bash ./alr-bootstrap.sh && rm -f ./alr-bootstrap.sh || echo Installation failed

Or, alternatively, clone the repository and launch the installation script:

1. `git clone --recursive https://github.com/alire-project/alr.git`
2. `cd alr`
3. `bash install/alr-bootstrap.sh`
    
## First steps ##
The following miniguide shows how to obtain and compile already packaged projects, and create your own. First, create or enter into some folder where you don't mind that new project folders are created by the `alr` tool

Run `alr` without arguments to get a summary of available commands.

Run `alr --help` for global options about verbosity.

Run `alr help <command>` for more details about a command.

### Downloading, compiling and running an executable project ###
Obtaining an executable project already cataloged in Alire is straightforward. We'll demonstrate it with the `hello` project which is a plain "Hello, world!" application (or you can use the `hangman` project as a funnier alternative).

Follow these steps:

1. Issue `alr get hello`
2. Enter the new folder you'll find under your current directory: `cd hello*`
3. Build and run the project with `alr run`. This will compile and then launch the resulting executable.

As a shorthand, you can use `alr get --compile hello` to get and compile the program in one step.

### Creating a new project ###
Alire allows you to initialize an empty GNAT binary or library project with ease:

1. Issue `alr init --bin myproj` (you can use --lib for a library project).
2. Enter the folder: `cd myproj`
3. Check that it builds: `alr compile`
4. Run it: `alr run`

## Dependencies and upgrading ##
Alire keeps track of a project dependencies by compiling the file `myproj_alr.ads` file in the root folder of your project. You may check the one just created in the previous example.

If you need to add dependencies you must edit the file (example in the works) and then issue one of:

* `alr update`, which will fetch any additional dependencies in your project; or
* `alr update --online`, which will previously update the Alire catalog to obtain newly available releases.

As a shorthand, you can also use `alr build` to both update and compile in a single command.

## Finding available projects ##
For quick listing of projects and its description you can use the `list` command:

* `alr list [substring]`

There's also a search command which provides more details:

* `alr search <substring>` will look for `substring` in project names.
* `alr search --list` will list the whole catalog.

Even more details are obtained with:

* `alr get --info <project>`

This last command will show generic information. To see the one that specifically applies to your platform:

* `alr get --info --native <project>`

Also, adding `--private` will show further details irrelevant to users of the library, but important to `alr` packaging, if any.

## Troubleshooting ##

By default `alr` is quite terse and will hide the output of subprocesses, mostly reporting only success or failure. If you hit any problem, increasing verbosity (-v or even -d) is usually enough to get an idea of the root of the problem.

## Further reading ##

More comprehensive documentation is forthcoming, so stay tuned! Meanwhile, you can check the [draft paper](https://github.com/alire-project/alr/blob/master/doc/2018-03.alr-draft.pdf) in the `doc` folder for more details about `alr` internals, or inspect [index files](https://github.com/alire-project/alire/tree/master/index) to get an idea of how projects are included into the catalog.
