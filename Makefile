build_dask_and_jupyter: # takes a loong time
	docker build -t dask-recipes . 

run_dask_and_jupyter:
	docker run --rm -p 8888:8888 -p 8787:8787 -v "${PWD}/notebooks":/home/jovyan/notebooks dask-recipes 