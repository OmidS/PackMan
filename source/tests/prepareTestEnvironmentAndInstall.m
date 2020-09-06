function pm = prepareTestEnvironmentAndInstall(depList)
%PREPARETESTENVIRONMENTANDINSTALL Summary of this function goes here
%   Detailed explanation goes here
toRemoveLater = prepareTestEnvironment();
pm = installDeps(depList);
pm.install();
rmpath(toRemoveLater{:});

