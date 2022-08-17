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
		CREDENTIALS: dagger.#Secret
		PROJECT:     string
	}

	actions: {
		"build": {
			version: *"latest" | string
			_source: client.filesystem["."].read.contents

			_image: docker.#Pull & {
				source:      "hashicorp/packer:\(version)"
				resolveMode: "preferLocal"
			}

			init: docker.#Run & {
				input: _image.output
				mounts: code: {
					dest:     "/src"
					contents: _source
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

			build: docker.#Run & {
				input: init.output
				mounts: code: {
					dest:     "/src"
					contents: _source
				}
				workdir: "/src"
				command: {
					name: "build"
					args: ["pihole.pkr.hcl"]
				}
				env: {
					LOG_LEVEL: "debug"
				}
			}
		}
		"deploy": {
			_tfenv: {
				TF_VAR_credentials: client.env.CREDENTIALS
				TF_VAR_project:     client.env.PROJECT
			}
			_tfSource: core.#Source & {
				path: "./terraform"
			}
			init: terraform.#Init & {
				source: _tfSource.output
			}
			validate: terraform.#Validate & {
				source: init.output
			}
			plan: terraform.#Plan & {
				source: validate.output
				cmdArgs: ["--var-file=prod.tfvars"]
				env: _tfenv
			}
			apply: terraform.#Apply & {
				source: plan.output
				env:    _tfenv
			}
			output: terraform.#Run & {
				source: apply.output
				cmd:    "output"
				cmdArgs: ["-json"]
			}
		}
	}
}
