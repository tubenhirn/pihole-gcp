package ci

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"

	"universe.dagger.io/docker"
	"universe.dagger.io/x/ezequiel@foncubierta.com/terraform"
)

dagger.#Plan & {
	client: filesystem: ".": read: contents: dagger.#FS
	client: env: {
		PROJECT:                 string
		TF_CREDENTIALS:          dagger.#Secret
		PKR_ACCESS_TOKEN:        dagger.#Secret
		PKR_USER_NAME:           dagger.#Secret
		PKR_USER_PASSWORD:       dagger.#Secret
		PKR_PIHOLE_WEB_PASSWORD: dagger.#Secret
	}

	actions: {
		"deploy": {
			_tfenv: {
				TF_VAR_credentials: client.env.TF_CREDENTIALS
				TF_VAR_project:     client.env.PROJECT
			}
			_tfSource: core.#Source & {
				path: "./terraform"
			}

			_packerVersion: *"latest" | string

			_packerSource: client.filesystem["."].read.contents

			_packerImage: docker.#Pull & {
				source:      "hashicorp/packer:\(_packerVersion)"
				resolveMode: "preferLocal"
			}

			init: terraform.#Init & {
				source: _tfSource.output
			}

			validate: terraform.#Validate & {
				source: init.output
			}

			planNetwork: terraform.#Plan & {
				source: validate.output
				cmdArgs: ["--var-file=prod.tfvars", "--target=google_compute_address.ip_address", "--target=local_file.ip_address_output"]
				env: _tfenv
			}

			applyNetwork: terraform.#Apply & {
				source: planNetwork.output
				env:    _tfenv
			}

			packerInit: docker.#Run & {
				input: _packerImage.output
				mounts: code: {
					dest:     "/src"
					contents: _packerSource
				}
				workdir: "/src"
				command: {
					name: "init"
					args: ["pihole.pkr.hcl"]
				}
				env: {
					LOG_LEVEL: "debug"
				}
			}

			packerBuild: docker.#Run & {
				input:         packerInit.output
				_ipv4_address: core.#ReadFile & {
					input: applyNetwork.output
					path:  "./ip_address.txt"
				}
				mounts: code: {
					dest:     "/src"
					contents: _packerSource
				}
				workdir: "/src"
				command: {
					name: "build"
					args: ["pihole.pkr.hcl"]
				}
				env: {
					PKR_VAR_user_name:           client.env.PKR_USER_NAME
					PKR_VAR_user_password:       client.env.PKR_USER_PASSWORD
					PKR_VAR_pihole_web_password: client.env.PKR_PIHOLE_WEB_PASSWORD
					PKR_VAR_project:             client.env.PROJECT
					PKR_VAR_pkr_access_token:    client.env.PKR_ACCESS_TOKEN
					PKR_VAR_image_version:       "draft"
					PKR_VAR_ipv4_address:        _ipv4_address.contents
				}
			}

			planInstance: terraform.#Plan & {
				source:        validate.output
				_ipv4_address: core.#ReadFile & {
					input: applyNetwork.output
					path:  "./ip_address.txt"
				}
				_imageName: core.#ReadFile & {
					input: packerBuild.output.rootfs
					path: "./image.txt"
				}
				cmdArgs: ["--var-file=prod.tfvars", "--target=google_compute_instance.pihole"]
				env: {
					TF_VAR_credentials:  client.env.TF_CREDENTIALS
					TF_VAR_project:      client.env.PROJECT
					TF_VAR_image:        _imageName.contents
					TF_VAR_ipv4_address: _ipv4_address.contents
				}
			}

			applyInstance: terraform.#Apply & {
				source: planInstance.output
			}

		}
	}
}
