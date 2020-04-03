# PackMan

## Table of Contents

1. [Acknowledgements](#acknowledgements)
2. [Description](#description)
3. [Usage Guide](#usage-guide)
4. [Examples](#examples)
5. [Test](#test)
6. [ToDo](#todo)
7. [Limitations](#limitations)
8. [References](#references)

## Acknowledgements

- This PackMan was forked from [OmidS's Packman](https://github.com/OmidS/PackMan).
- OmidS's Packman was forked from a great repository called [DepMat](https://github.com/tomdoel/depmat), by [Tom Doel](http://www.tomdoel.com).

## Description

PackMan aims to bring dependency management, similar to what [npm](https://www.npmjs.com) does for [Node.js](https://nodejs.org), to [MATLAB](https://www.mathworks.com/products/matlab.html). It is a fork of and improves on [OmidS's Packman](https://github.com/OmidS/PackMan).

### Additional Features

- Adds the possibility to source from private repositories.
- Adds the possibility to write git native commands directly from matlab.

## Usage guide

Let's say you have a MATLAB project and you want to be able to use external packages in your code. An external package can be any git repository for which you have read access (e.g. any public repository on GitHub).

### One time setup

You will need to do the following once, to enable package management with PackMan for your project:

- Make sure there is no directory called 'external' at the root directory of your project
- Copy "[installDeps.m](https://raw.githubusercontent.com/DanielAtKrypton/PackMan/master/source/installDeps.m)" to the root directory of your project
- Copy "[getDepList.m](https://raw.githubusercontent.com/DanielAtKrypton/PackMan/master/source/getDepList.m)" to the root directory of your project.

Done! Your project is now equipped with dependency management.

### Add/remove dependencies

You will need to do the following any time you want to add/remove a dependency

- (Option 1) Update the list of dependencies in a file called package.json (for R2016b and later). PackMan will create a package.json file the first time you call "installDeps.m". Each dependency can have the fields listed in the following sample "package.json":

```json
{
 "dependencies":{
  "PackMan":{
   "Name":"PackMan",
   "Branch":"master",
   "Url":"https://github.com/DanielAtKrypton/PackMan.git",
   "FolderName":"PackMan",
   "Commit":"",
   "GetLatest":true
  }
 }
}
```

- (Option 2) Modify "getDepList.m" to make sure it lists the dependencies that you want. It is good to also have PackMan itself in the dependency list (uncomment line 10 of getDepList.m)

Note: when removing any repositories, it is best to delete the 'external' directory completely so that PackMan starts fresh.

### Install/update dependencies

You will need to do the following to install or update dependencies

- Run the following command (this will install/update all dependencies)

```matlab
>> installDeps;
```

### Add dependencies to the path

You will need to run the following to add the dependencies to the MATLAB path before running your code

- Now before running you code, add dependencies to the path by calling:

```matlab
>> pm = installDeps;
>> addpath(pm.genPath(:));
```

You can also gracefully remove all dependencies from the path by calling:

```matlab
>> rmpath(pm.genPath(:));
```

## Examples

- [PackManRecursiveSample](https://github.com/DanielAtKrypton/PackManRecursiveSample.git)

## Test

```matlab
testsResults = runtests('testPackMan')
```

## ToDo

- Add and successfully pass continuous integration.
- Make sure it works for Mac and Linux operating systems.

## Limitations

- It was tested for Windows only because git.m uses a batch file workaround (RunCommand.cmd) to allow private repositories to be used within Packman.

## References

- [matlab-continuous-integration](https://github.com/scottclowe/matlab-continuous-integration)