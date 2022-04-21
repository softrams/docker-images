FROM prefecthq/prefect:0.15.11-python3.7
RUN pip3 install --upgrade \
  snowflake-connector-python \
  pandas \
  FixedWidth \
  sqlalchemy \
  snowflake-sqlalchemy

