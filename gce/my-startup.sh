set -e

# Talk to the metadata server to get the project id
PROJECTID=$(curl -s "http://metadata.google.internal/computeMetadata/v1/project/project-id" -H "Metadata-Flavor: Google")
REPO_NAME="bookswap"

# Get the source code
export HOME=/root
git config --global credential.helper gcloud.sh
# Change branch from master if not using master
git clone https://source.developers.google.com/p/$PROJECTID/r/$REPO_NAME /opt/app -b master

pushd /opt/app/

pushd config

cp database.example.yml database.yml
chmod go-rwx database.yml
cp settings.example.yml settings.yml
chmod go-rwx settings.yml
cp config.example.yml config.yml
chmod go-rwx config.yml



# Add your GCP project ID here
sed -i -e 's/@@PROJECT_ID@@/udacity-project-219417/' settings.yml
sed -i -e 's/@@PROJECT_ID@@/udacity-project-219417/' database.yml

# Add you oath here
sed -i -e 's/@@CLIENT_ID@@/523813851585-3nbej53c0oga2b3sp69ekcren8pvuo6o.apps.googleusercontent.com/' settings.yml
sed -i -e 's/@@CLIENT_SECRET@@/o6pe7cIfQk3AslLsTqmG2dNP/' settings.yml

popd # config

./gce/configure.sh

popd # /opt/app
