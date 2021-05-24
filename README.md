# lr-s3-collection
 Collection of logs dropped in an AWS S3 Bucket

## Steps

### Install NodeJS

```bash
sudo dnf -y module install nodejs:14
```
### Install scripts

```bash
sudo mkdir --parent /usr/local/lr-aws-s3/crontab.scripts
sudo mkdir --parent /usr/local/lr-aws-s3/js
cd /usr/local/lr-aws-s3/
wget https://github.com/TonyMasse/lr-s3-collection/releases/download/v3/lr-aws-s3.tar.gz
tar xvfz lr-aws-s3.tar.gz
sudo chmod +x /usr/local/lr-aws-s3/crontab.scripts/*.sh
```

### Configure script

- Edit script(s) in `/usr/local/lr-aws-s3/crontab.scripts/`
- update the following lines:
```bash
readonly JOB_NAME="jumpcloud"
readonly S3_BUCKET_NAME="PUT THE NAME OF THE BUCKET RECEIVING JUMPCLOUD LOGS HERE"
```
- to look like:
```bash
readonly JOB_NAME="jumpcloud"
readonly S3_BUCKET_NAME="my_jumpcloud_bucket-12abcdef123a"
```

### Deploy Crontab script

```
sudo ln -s /usr/local/lr-aws-s3/crontab.scripts/aws-s3-cloudtrail.sh /etc/cron.hourly/5-aws-s3-cloudtrail.sh
sudo ln -s /usr/local/lr-aws-s3/crontab.scripts/aws-s3-jumpcloud.sh /etc/cron.hourly/5-aws-s3-jumpcloud.sh
```

### Get Filebeat to read the export

- Template:
  - Replace:
    - `THE_SAME_UID_YOU_USE_IN_JQ_FILTER_OF_OPENCOLLECTOR_PIPELINE` with a UID. Make sure that you use the same in the OpenCollector Pipeline filter (`is_xxxxx.jq`, where `xxxxx` is the pipeline's name)
    - `A_NAME_FOR_YOUR_STREAM` with a name that makes sense ("`S3 - Log Source name`" is usually a good format)
    - `JOB_NAME` with a short name for the Log Source. It will be used as a Path, so make sure you do NOT use any unacceptable characters for the Operatng System. Good idea to avoid spaces too.

```yml
- type: log
  enabled: true
  fields:
    stream_id: THE_SAME_UID_YOU_USE_IN_JQ_FILTER_OF_OPENCOLLECTOR_PIPELINE
    stream_name: A_NAME_FOR_YOUR_STREAM
  paths:
    - /var/import/to_SIEM/JOB_NAME/*.log
  close_inactive: 3h
  ignore_older: 12h
  scan_frequency: 10s
```

- For example:

```yml
- type: log
  enabled: true
  fields:
    stream_id: a51a3976-7960-49bd-a80b-699f6fad5520
    stream_name: S3 - Jumpcloud
  paths:
    - /var/import/to_SIEM/jumpcloud/*.log
  close_inactive: 3h
  ignore_older: 12h
  scan_frequency: 10s
```
