# PackMan
PackMan aims to bring dependency management, similar to what [npm](https://www.npmjs.com) does for [Node.js](https://nodejs.org), to [MATLAB](https://www.mathworks.com/products/matlab.html). It is a fork of and improves on [DepMat](https://github.com/tomdoel/depmat).

# Usage guide
Let's say you have a MATLAB project and you want to be able to use external packages in your code. An external package can be any git repository for which you have read access (e.g. any public repository on GitHub).

## One time setup
You will need to do the following once, to enable package management with PackMan for your project:
- Make sure there is no directory called 'external' at the root directory of your project
- Copy "[installDeps.m](https://github.com/OmidS/PackMan/blob/master/source/installDeps.m)" to the root directory of your project
- Copy "[getDepList.m](https://github.com/OmidS/PackMan/blob/master/source/getDepList.m)" to the root directory of your project

Done! Your project is now equipped with dependency management.

## Add/remove dependencies
You will need to do the following any time you want to add/remove a dependency
- Modify "getDepList.m" to make sure it lists the dependencies that you want. It is good to also have PackMan itself in the dependency list (uncomment line 10 of getDepList.m)

Note: when removing any repositories, it is best to delete the 'external' directory completely so that PackMan starts fresh.

## Install/update dependencies
You will need to do the following to install or update dependencies
- Run the following command (this will install/update all dependencies)
```
>> installDeps;
```


## Add dependencies to the path
You will need to run the following to add the dependencies to the MATALAB path before running your code
- Now before running you code, add dependencies to the path by calling:
```
>> pm = installDeps;
>> addpath(pm.genPath());
```

You can also gracefully remove all dependencies from the path by calling:
```
>> rmpath(pm.genPath());
```

## Complete example:
See the following sample repository for a complete usage example for PackMan:
https://github.com/OmidS/matlabPackManSample


# Credits
PackMan was forked from a great repository called [DepMat](https://github.com/tomdoel/depmat), by [Tom Doel](http://www.tomdoel.com).
