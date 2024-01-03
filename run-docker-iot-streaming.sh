docker network create my-network-1
docker run -d --network=my-network-1 --name zookeeper \
    -e ZOOKEEPER_CLIENT_PORT=2181 \
    -e ZOOKEEPER_TICK_TIME=2000 \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    bitnami/zookeeper:latest

docker run -d --network=my-network-1 --name kafka \
    -e KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181 \
    -e KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:9092 \
    -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1 \
    -e KAFKA_BROKER_ID=1 \
    -e KAFKA_CONFLUENT_SUPPORT_METRICS_ENABLE=false \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
    -e ALLOW_ANONYMOUS_LOGIN=yes \
    bitnami/kafka:latest


docker build -t data_ingestion ./data_ingestion

docker run -d \
  --name data_ingestion \
  --network my-network-1 \
  -e KAFKA_BOOTSTRAP_SERVERS=kafka:9092 \
  -e KAFKA_TOPIC=refit.raw.data \
  data_ingestion


docker build -t data_consumer ./data_consumer


# Run data_consumer
docker run -d \
  --name data_consumer \
  --network my-network-1 \
  -e KAFKA_BOOTSTRAP_SERVERS=kafka:9092 \
  -e KAFKA_TOPIC=refit.feature.data \
  data_consumer


# Run jobmanager
docker run -d \
  --name jobmanager \
  --network my-network-1 \
  -p 8081:8081 \
  -e JOB_MANAGER_RPC_ADDRESS=jobmanager \
  flink:1.14.3-scala_2.12 jobmanager

# Run taskmanager
docker run -d \
  --name taskmanager \
  --network my-network-1 \
  -e JOB_MANAGER_RPC_ADDRESS=jobmanager \
  flink:1.14.3-scala_2.12 taskmanager


## build flink image 
docker build -t feature_engineering ./flink_job

# Run feature_engineering
docker run -d \
  --name feature_engineering \
  --network my-network-1 \
  -e KAFKA_BOOTSTRAP_SERVERS=kafka:9092 \
  -e KAFKA_SOURCE_TOPIC=refit.raw.data \
  -e KAFKA_SINK_TOPIC=refit.feature.data \
  -e JOBMANAGER_ADDRESS=jobmanager \
  -e JOBMANAGER_PORT=6123 \
  feature_engineering


