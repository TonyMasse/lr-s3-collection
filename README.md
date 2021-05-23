# lr-s3-collection
 Collection of logs dropped in an AWS S3 Bucket

## Steps

### Install NodeJS

```
sudo dnf -y module install nodejs:14
```
### Install scripts

```
sudo mkdir --parent /usr/local/lr-aws-s3/crontab.scripts
sudo mkdir --parent /usr/local/lr-aws-s3/js
cd /usr/local/lr-aws-s3/
# wget https:// xxxxxxx /lr-aws-s3.tar.gz
tar xvfz lr-aws-s3.tar.gz
sudo chmod +x /usr/local/lr-aws-s3/crontab.scripts/*.sh
```

### Deploy Crontab script

```
sudo ln -s /usr/local/lr-aws-s3/crontab.scripts/aws-s3-cloudtrail.sh /etc/cron.hourly/5-aws-s3-cloudtrail.sh
sudo ln -s /usr/local/lr-aws-s3/crontab.scripts/aws-s3-jumpcloud.sh /etc/cron.hourly/5-aws-s3-jumpcloud.sh
```
