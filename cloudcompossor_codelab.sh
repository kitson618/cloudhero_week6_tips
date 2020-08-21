Project Name : Project_NAME 
Bucket in US : Project_NAME-us
Bucket in EU : Project_NAME-eu
BQ Dataset Name in EU : nyc_tlc_EU
DAGS task : composer_sample_bq_copy_across_locations 

# Task0 : Prepare Cloud Shell 
gcloud config set project Project_NAME

# Task1 : Create Composer Environment 
# Name: composer-advanced-lab
# Location: us-central1
# Zone: us-central1-a

gcloud composer environments create composer-advanced-lab \
--location us-central1 --zone us-central1-a

# Task2 : Create 2 buckets one for US, one for EU 
gsutil mb -p Project_NAME -c STANDARD -l US -b on gs://Project_NAME-us/
gsutil mb -p Project_NAME -c STANDARD -l EU -b on gs://Project_NAME-eu/

# Task 3 : Create Dataset nyc_tlc_EU in EU location
bq --location=EU mk --dataset nyc_tlc_EU
bq --location=EU ls

# Task 4 : Defining the workflow 
# Check out source code on https://github.com/GoogleCloudPlatform/python-docs-samples/blob/master/composer/workflows/bq_copy_across_locations.py

# Task 5 : Creating a virtual environment in CloudShell
sudo apt-get update
sudo apt-get install virtualenv
virtualenv -p python3 venv
source venv/bin/activate

#Get DAGSBUCKET NAME from Environment page, Need to wait until environment being created
gcloud composer environments describe composer-advanced-lab \
    --location us-central1 
DAGS_BUCKET=us-central1-composer-advanc-YOURDAGSBUCKET-bucket

gcloud composer environments run composer-advanced-lab \
--location us-central1 variables -- \
--set gcs_source_bucket Project_NAME-us

gcloud composer environments run composer-advanced-lab \
--location us-central1 variables -- \
--set gcs_dest_bucket Project_NAME-eu

gcloud composer environments run composer-advanced-lab \
--location us-central1 variables -- \
--set table_list_file_path "/home/airflow/gcs/dags/bq_copy_eu_to_us_sample.csv"

#gcloud composer environments run composer-advanced-lab \
#    --location us-central1 variables -- \
#    --get gcs_source_bucket

# Task 6 : Uploading the DAG and dependencies to Cloud Storage
cd ~
git clone https://github.com/GoogleCloudPlatform/python-docs-samples
gsutil cp -r python-docs-samples/third_party/apache-airflow/plugins/* gs://$DAGS_BUCKET/plugins
gsutil cp python-docs-samples/composer/workflows/bq_copy_across_locations.py gs://$DAGS_BUCKET/dags
gsutil cp python-docs-samples/composer/workflows/bq_copy_eu_to_us_sample.csv gs://$DAGS_BUCKET/dags

# Task 7 : Using the Airflow UI
### https://airflow.apache.org/docs/stable/cli-ref
# Airflow webserver >> new window icon >> Click on your lab credentials
# Admin > check Variables

# Task 8 : Trigger the DAG to run manually
# To trigger the DAG manually, click the play button
gcloud composer environments run composer-advanced-lab \
    --location us-central1 trigger_dag -- composer_sample_bq_copy_across_locations

# For example, to check for syntax errors in DAGs in a test/ directory:
gcloud composer environments run composer-advanced-lab \
     --location us-central1 list_dags -- -sd /home/airflow/gcs/data/test

# Task 9 : Exploring DAG runs
gcloud composer environments run composer-advanced-lab \
    --location us-central1 list_dag_runs

# Task 10 : Validate the results
# Check Airflow UI
# Check Cloud Storage UI
# Check BigQuery UI with Destination Dataset or not
