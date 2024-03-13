
##### [MAIN REPOSITORY](https://github.com/wintersys-projects/adt-build-machine-scripts)

##### This repository is the code which implements the autoscaling functions of the Agile Deployment Toolkit

The autoscaler scripts will spawn a (configurable) number of webservers in order to sevice client requests. 
This isn't strictly autoscaling because how many websevers to scale out to is statically defined, so, this toolkit might not be the best solution for use cases that need to service sudden spikes in traffic.

**NOTE** 
If you are deploying in "Development" mode, then remember that auto-scaling or scaling is switched off. 
In production mode scaling is possible and is the full fledged "Production" solution. 

If there are providers which have options for dynamic scaling it might be possible to build this solution out so that the provider's dynamic scaling is actionable this would make this solution more suitable for applications that experience sudden spikes. For now, this is a solution which is best suited, to, for example, social networks which have predictable usage profiles in a day in day out basis so that you can, for example, set your system to scale up its number of webservers in the early morning and scale them back down at night. Or if you have a predictable usage spike at midday, scale up at 11:30 by a few webservers and then scale back down at 1:30 and so on. 


