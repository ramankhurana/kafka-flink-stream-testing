from pyflink.table import EnvironmentSettings, StreamTableEnvironment

env_settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
t_env = StreamTableEnvironment.create(environment_settings=env_settings)

t_env.get_config().get_configuration().set_string("pipeline.jars",
                                                   "file:///opt/flink_job/libs/flink-connector-kafka_2.12-1.14.3.jar;file:///opt/flink_job/libs/kafka-clients-2.8.1.jar")

t_env.get_config().get_configuration().set_string("pipeline.classpaths",
                                                   "file:///opt/flink_job/libs/flink-connector-kafka_2.12-1.14.3.jar;file:///opt/flink_job/libs/kafka-clients-2.8.1.jar")


with open('source.sql', 'r') as file:
    create_table_sql = file.read()

# Check if the table 'sensor_data' already exists
if 'sensor_data' in t_env.list_tables():
    # If it does, drop it
    t_env.execute_sql("DROP TABLE sensor_data")

# Then, you can create your table
t_env.execute_sql(create_table_sql)


result = t_env.execute_sql("SELECT * FROM sensor_data").print()
