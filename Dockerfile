FROM jupyter/base-notebook:lab-2.2.5

USER root
# python3 setup
RUN apt-get update && apt-get install -y graphviz git

USER jovyan

COPY env env

RUN conda env update -n base -f env/environment.yml --prune && . env/postBuild

CMD ["jupyter", "lab"]