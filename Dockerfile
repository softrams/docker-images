FROM prefecthq/prefect:0.15.11-python3.8
RUN pip3 install --upgrade \
  snowflake-connector-python \
  mysql-connector-python \
  pandas \
  great_expectations \
  FixedWidth \
  sqlalchemy \
  snowflake-sqlalchemy \
  snowflake-snowpark-python \
  redshift_connector \
  teradatasql
