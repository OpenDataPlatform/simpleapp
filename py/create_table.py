import sys
import argparse
from pyspark.sql import SparkSession


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--src', required=True)
    parser.add_argument('--bucket', required=True)
    parser.add_argument('--database', required=True)
    parser.add_argument('--table', required=True)
    parser.add_argument('--datamartFolder', required=True)
    parser.add_argument('--select', required=True)
    p = parser.parse_args()
    spark = SparkSession.builder.enableHiveSupport().getOrCreate()
    df = spark.read.options(header='True', inferSchema='True', delimiter=",").csv(p.src)
    df.createOrReplaceTempView("_src_")
    df.show()
    spark.sql("CREATE DATABASE IF NOT EXISTS {database}".format(database=p.database))
    spark.sql("DROP TABLE IF EXISTS {database}.{table}".format(database=p.database, table=p.table))
    spark.sql("CREATE TABLE IF NOT EXISTS {database}.{table} USING PARQUET LOCATION 's3a://{bucket}/{datamartFolder}/{table}' AS {select}"
              .format(database=p.database, table=p.table, bucket=p.bucket, datamartFolder=p.datamartFolder, select=p.select))
    spark.sql("SHOW TABLES FROM {database}".format(database=p.database)).show()
    spark.sql("DESCRIBE TABLE {database}.{table}".format(database=p.database, table=p.table)).show()
    spark.sql("SELECT COUNT(*) FROM {database}.{table}".format(database=p.database, table=p.table)).show()
    spark.stop()
    return 0


if __name__ == '__main__':
    sys.exit(main())
