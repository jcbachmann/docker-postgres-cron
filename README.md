# PostgreSQL with Cron and Tini

This Docker image extends the official PostgreSQL image by adding `cron` and `tini`. It also includes a custom entrypoint script to facilitate the use of cron jobs via an environment variable.

## Purpose

This image is useful for taking backups of PostgreSQL databases at regular intervals using cron jobs. It can be used in development, testing, or production environments where automated backups are required.

## Table of Contents

- [Features](#features)
- [Usage](#usage)
  - [Building the Image](#building-the-image)
  - [Running the Container](#running-the-container)
  - [Using Cron](#using-cron)
- [Example with Docker Compose](#example-with-docker-compose)
  - [Accessing the Database](#accessing-the-database)
  - [Accessing the Backups](#accessing-the-backups)
- [Disclaimer](#disclaimer)
- [License](#license)

## Features

- Based on the latest PostgreSQL official image.
- Includes cron for scheduling tasks.
- Uses tini as the init system for proper process management.
- Custom entrypoint script to manage cron jobs via an environment variable.

## Usage

### Building the Image

To build the Docker image, run the following command in the directory containing the `Dockerfile` and `entrypoint.sh`:

```sh
docker build -t postgres-cron-tini .
```

### Running the Container

To run the container with default settings:

```sh
docker run -d --name my_postgresdb -e POSTGRES_PASSWORD=postgrespassword postgresdb-cron-tini
```

### Using Cron

You can set up cron jobs by passing the `CRONTAB` environment variable. For example:

```sh
docker run -d --name my_postgresdb \
 -e PGPASSWORD=postgrespassword \
 -e CRONTAB="\* \* \* \* \* /usr/bin/pg_dumpall --host=my_postgresdb --user=postgres > /backups/my_postgresdb-all_databases.sql" \
 postgresdb-cron-tini
```

In this example, the cron job will run every minute and dump all databases of `my_postgresdb` to `/backups/my_postgresdb-all_databases.sql`.

## Example with Docker Compose

Usually, you would want to backup the databases from an existing PostgreSQL container.

Here is an example of using this image with Docker Compose to create a PostgreSQL database and a PostgreSQL database with cron and tini to take backups of the database every minute using the `pg_dumpall` command:

```yaml
version: '3.8'

services:
  db:
    image: postgres:latest
    restart: always
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - default
      - adminer_default
    healthcheck:
      test:
        [
          'CMD-SHELL',
          'pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB} -h localhost',
        ]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

  db_backup:
    build:
      context: .
      dockerfile: Dockerfile
    restart: always
    depends_on:
      - db
    volumes:
      - /backups:/backups:rw
    environment:
      CRONTAB: |
        * * * * * bash -c "PGPASSWORD='${POSTGRES_PASSWORD}' pg_dumpall --host=db --user=${POSTGRES_USER} | gzip -9 > /backups/db-all_databases.sql.gz"
    networks:
      - default

volumes:
  db_data:

networks:
  default:
    driver: bridge
  adminer_default:
    external: true
```

This example assumes that you have a `.env` file in the same directory as the `docker-compose.yml` file with the following content:

```sh
POSTGRES_DB=mydatabase
POSTGRES_USER=myuser
POSTGRES_PASSWORD=mypassword
```

The example also assumes that you have the `Dockerfile` and `entrypoint.sh` files in the same directory as the `docker-compose.yml` file.

This Docker stack, when started with `docker-compose up -d`, will create two services: `db` and `db_backup`. The `db` service is a PostgreSQL database, and the `db_backup` service is a PostgreSQL database with cron and tini. The `db_backup` service will dump all databases of the `db` service every minute to `/backups/db-all_databases.sql.gz`.

### Accessing the Database

The database is included in the `adminer_default` network, so you can access it using [Adminer](https://www.adminer.org/). After installing Adminer on Docker, make sure the Adminer's default network has the correct name. To access the database, navigate to `http://localhost:8080` in your browser and use the following credentials:

- System: PostgreSQL
- Server: db
- Username: myuser
- Password: mypassword
- Database: mydatabase

Adjust the values based on the `.env` file and your container names, and you should be able to access the database with the provided credentials.

### Accessing the Backups

The backups are stored in the `/backups` directory on the host machine. You can access them by navigating to the `/backups` directory on your host machine.

You will need to unzip the `.gz` files to access the SQL files. You can do this by running the following command:

```sh
gunzip -d /backups/db-all_databases.sql.gz
```

Then, use tools like `cat` or `less` to view the contents of the SQL file.

## Disclaimer

This document should provide a good starting point for users to understand and utilize this Docker image. Adjust the examples and descriptions as needed to fit your specific use case and environment.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
