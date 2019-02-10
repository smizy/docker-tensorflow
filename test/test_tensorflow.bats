@test "tensorflow is the correct version" {
  run docker run smizy/tensorflow:${TAG} python -c "import tensorflow as tf; print(tf.__version__)"
  echo "${output}" 

  [ $status -eq 0 ]
  [ "${output}" = "${VERSION}" ]
}