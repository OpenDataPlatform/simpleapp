

# Initial setup

To create kubconfig for spark account
```
./tools/generate_kubeconfig.sh spark-sapp-work spark ./kubeconfigs/spark-sapp-work.spark
```


To upload sample data set: 
```
./tools/upload-data.sh minio1/spark-sapp/data
```

To upload java code (For spark operator)

```
./tools/upload-java-simpleapp.sh minio1/spark-sapp/jars
```

To upload python code (For spark operator)

```
./tools/upload-py-simpleapp.sh minio1/spark-sapp/py
```


# Intellij setup

```
git clone https://github.com/OpenDataPlatform/simpleapp.git
cd simpleapp/
cd java
./gradlew
cd ../py/
./setup/install.sh
```

## Projet init:

- Start intellij
- New project
- Empty project
- Don't care about 'not empty' warning

## Python module

- Project Structure/Platform Setting/SDK/+/Add Python SDK
- Existing environment, navigate to our venv
- Project structure / Modules
- `+`
- Import module
- Navigate to py folder
- Create module from existing source
- Select python SDK
- Uncheck django
- Set module SDK to our python env

## Java module

- Project structure / Modules
- `+`
- Import module
- Navigate to java folder
- Import module from external model / Gradle
