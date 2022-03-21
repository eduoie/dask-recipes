# Local Dask cluster
Environment for [Dask Tutorial](https://github.com/dask/dask-tutorial). The name of the environment has been changed as the purpose is not only the tutorial, but having a useful guide to use it for the long term.


```
conda env create -f env/environment.yml
conda activate dask-recipes
jupyter labextension install dask-labextension
jupyter labextension install @jupyter-widgets/jupyterlab-manager
jupyter labextension install @bokeh/jupyter_bokeh

jupyter lab
```

I got errors when trying to run XGBoost on my Mac. Thus, I switched to a Docker image where to run the notebooks.


Sources:

https://github.com/programmylife/dask-ml-tutorial-summit-2021

Check `notebooks/aws-cmip6.ipynb` to run locally (on Docker) the analysis implemented on Trial 3. It requires around 12Gb of RAM to avoid the workers being fatally reset due to lack of memory.


# Dask clusters with ECS/EKS

## Trial 1
Tried this: [https://aws.amazon.com/blogs/machine-learning/machine-learning-on-distributed-dask-using-amazon-sagemaker-and-aws-fargate/](https://aws.amazon.com/blogs/machine-learning/machine-learning-on-distributed-dask-using-amazon-sagemaker-and-aws-fargate/). It fails building the CloudFormation

## Trial 2
Then, tried this [Distributed Data Pre-processing using Dask, Amazon ECS and Python (Part 1)](https://towardsdatascience.com/serverless-distributed-data-pre-processing-using-dask-amazon-ecs-and-python-part-1-a6108c728cc4)

* An Amazon ECR repository is created
* A dask image is pushed into the repository following the instructions
* Created a Dask cluster following the template
* Created a vpc named 'dask' with a public and private subnets and a gateway to access the ECR registry.
* Created a CloudFormation stack and pass the public and private subnet in the subnet parameters, and the vpc id.

Apparently, the cluster is created. **But** happiness doesn't last long. It is shut down because the next error happens in CloudFormation: `The security group 'dask-sg' does not exist in default VPC ` (Why it chooses default VPC?? Shouldn't it use the passed vpc?)
Anyway, I created the dask-sg and it failed because the resource already exists. I give up, don't have enough time to focus on DevOps

## Trial 3
Then, tried this: [Analyze terabyte-scale geospatial datasets with Dask and Jupyter on AWS](https://aws.amazon.com/blogs/publicsector/analyze-terabyte-scale-geospatial-datasets-with-dask-and-jupyter-on-aws/)

Adapt `cluster.yaml` to configure the created key and execute.

Error while creating CloudFormation, because I created the key for a different region than the cluster. So, recreate another one for the proper region.


Retry. Seems to proceed.

Ok, miraculously the cluster is created.

```
$ kubectl cluster-info
Kubernetes control plane is running at https://*****.gr7.us-west-2.eks.amazonaws.com
CoreDNS is running at https://*****.us-west-2.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

When editing `deployment.apps/cluster-autoscaler`, do not use tabs

Applied this command as is (i.e. didn't look for a newer version): `kubectl set image deployment cluster-autoscaler -n kube-system cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.1`

Requested a domain in Route53 in order to access the notebooks and Dask dashboard.

Once run `helm upgrade --install daskhub dask/daskhub --values=daskhub.yaml`, you can check the running pods with: `get pods -o wide -w`

The [provided notebook](https://github.com/awslabs/amazon-asdi/blob/main/examples/dask/notebooks/cmip6_zarr.ipynb) for the demo runs smoothly.

**Notes**:
This solution is overkill and expensive for a single person needs, as it not only keeps the cluster up, but also keeps up the Dask and worker instances all the time. Nonetheless, it provides a handy solution if you have a team that has to work with large datasets with bursts of workloads.
The cost for me was of $12 for registering the domain (actually, a pseudo-optional step –you will have to connect without SSL- if you just want to quickly try the service; just open the LoadBalancer URL that is provided) plus $2.65 for the instances, EKS et al.

Also, remarkably, the most complex solution I have tried has been the only one that worked.

As an alternative, you can try Saturn Cloud, who provides you with 3 hours of Dask workers per month for free.

## Trial 4

Using [Dask Cloud Provider library](https://cloudprovider.dask.org/en/latest/). 

Tried this example, [https://medium.com/rapids-ai/getting-started-with-rapids-on-aws-ecs-using-dask-cloud-provider-b1adfdbc9c6e](https://medium.com/rapids-ai/getting-started-with-rapids-on-aws-ecs-using-dask-cloud-provider-b1adfdbc9c6e). It uses:

* Fargate Cluster
* ECS Cluster
* RAPIDS with GPU

When running the Fargate cluster, it worked seamlessly. Note there is a 5 minute inactivity timeout that shut downs the cluster automatically. I tried updating the parameters when launching the cluster but the parameters are invalid.

Then I tried running it with an ECS cluster, but an error happened. Probably there is some misconfiguration or resource limit, even though I didn't use GPUs. See `dask-aws-cluster.ipynb` notebook for error details.



## Untested options


Example with EC2 and GPU with RAPIDS: [https://github.com/dask/dask-cloudprovider/blob/main/examples/EC2Cluster-randomforest.ipynb](https://github.com/dask/dask-cloudprovider/blob/main/examples/EC2Cluster-randomforest.ipynb)

An example that uses a different configuration for Fargate. It suggests using an image based on the same Docker image that is pushed onto aws to avoid issues with mismatched dependencies:
[https://mesowest.utah.edu/html/hrrr/zarr_documentation/html/dask_whole_grid_climo.html](https://mesowest.utah.edu/html/hrrr/zarr_documentation/html/dask_whole_grid_climo.html)

