# pihole

a pihole running on gcp.\
setup with dagger, terraform and packer.

## setup

### prepare the environment

to run the dagger job we need a prepared environment.\
you'll find a `example.env` file inside the `env` directory.

fill all variables and save the file with a different name (e.g. `my-project.env`)

``` shell
# general
export PROJECT=

# terraform
export TF_CREDENTIALS=

# packer
export PKR_USER_NAME=
export PKR_USER_PASSWORD=
export PKR_ACCESS_TOKEN=
export PKR_PIHOLE_WEB_PASSWORD=
```

### run the deploy job

with the environment prepared we can run our `deploy` job.

``` shell
dagger do deploy
```
