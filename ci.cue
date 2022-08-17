package ci

import (
	"dagger.io/dagger"
)

dagger.#Plan & {
	client: env: {}

	actions: {
		"build": packer.#Build & {
			version: ""
		}
	}
}
