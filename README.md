# spark-glue-data-catalog

This project builds Apache Spark in way it is compatible with AWS Glue Data Catalog.

It was mostly inspired by awslabs' Github project [awslabs/aws-glue-data-catalog-client-for-apache-hive-metastore][1] and its various issues and user feedbacks.

⚠️ this is neither official, nor officially supported: use at your own risks!

## Usage prerequisites

### AWS credentials

You must provide AWS credentials via environment variables to the master/executor nodes 
for spark to be able to access AWS APIs: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_DEFAULT_REGION`. 

### IAM permissions

Here is an exemple of permission to allow Spark to access the Glue Catalog.

```json
{
  "Effect": "Allow",
  "Action": [
    "glue:*Database*",
    "glue:*Table*",
    "glue:*Partition*"
  ],
  "Resource": [
    "arn:aws:glue:us-west-2:123456789012:catalog",      
    "arn:aws:glue:us-west-2:123456789012:database/db1",
    "arn:aws:glue:us-west-2:123456789012:table/db1/table1"
  ]
}
```

Don't forget to also add S3 IAM permissions to be able to fetch data!

## Current release

The current release uses the following versions:
- Python 3.6
- Spark 2.4.5
- Hadoop 2.8.5
- Hive 1.2.1
- AWS SDK 1.11.682

## Miscellaneous

### Build spark-glue-data-catalog locally

Just run `make build`. Spark bundle artifact is produced in `dist/` directory.

### Use in Jupyter notebook

To use this version of pyspark in Jupyter, you need to declare a new dedicated kernel.

We suppose you installed Spark in `/opt` directory and symlinked it with `/opt/spark`.

Create a `kernel.json` file somewhere with following content:

```json
{
  "display_name": "PySpark",
  "language": "python",
  "argv": [
    "/opt/conda/bin/python",
    "-m",
    "ipykernel",
    "-f",
    "{connection_file}"
  ],
  "env": {
    "SPARK_HOME": "/opt/spark",
    "PYTHONPATH": "/opt/spark/python/:/opt/spark/python/lib/py4j-0.10.7-src.zip",
    "PYTHONSTARTUP": "/opt/spark/python/pyspark/shell.py",
    "PYSPARK_PYTHON": "/opt/conda/bin/python"
  }
}
```

Then, run `jupyter kernelspec install {path to kernel.json's directory}`.

## References

- [Source code for the AWS Glue Data Catalog client for Apache Hive Metastore is now available for download](https://aws.amazon.com/about-aws/whats-new/2019/02/source-code-for-the-aws-glue-data-catalog-client-for-apache-hive-metatore-is-now-available-for-download/) - Feb 4, 2019 announcement
- [Using the AWS Glue Data Catalog as the Metastore for Hive](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-hive-metastore-glue.html) documentation
- Github's [awslabs/aws-glue-data-catalog-client-for-apache-hive-metastore][1] project

[1]: https://github.com/awslabs/aws-glue-data-catalog-client-for-apache-hive-metastore