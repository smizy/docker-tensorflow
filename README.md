# docker-tensorflow

Python3 Tensorflow(CPU) with Jupyter docker image based on alpine 

* numpy, scipy, pandas, scikit-learn, seaborn, tensorflow installed via pip. See `pip list --format=columns` for detail.
* CPU only

## Usage

```
# Run jupyter notebook container (see token in log)

docker run -it --rm -v $PWD:/code -w /code -p 8888:8888 smizy/tensorflow:1.12.0-cpu-alpine
```

## Local build

```
docker build --build-arg "VERSION=1.12.0" -t local/tensorflow .
```
