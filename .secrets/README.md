# .Secrets
Folder for storing secrets used in docker build or runtime.

**ENSURE ALL FILES IN HERE ARE 600 ACCESS ONLY**
`chmod 600 ./*`

## SSH
Copy private key as `id_rsa` this will be the key used to connect to the jump container, as well as any containers in network. 

## GPG and GPG-Agent
GPG can be used to to sign commits so that they are verified. Create a GPG key by following the steps outlined from Github: https://docs.github.com/en/authentication/managing-commit-signature-verification/generating-a-new-gpg-key

Note: This setup automates passphrase input by configuring GPG-Agent. Both `gpg_private_key` and `gpg_passphrase` are required, otherwise docker containers will hang waiting for input.

* After you've exported your public key and saved it to Github. Export your private key to this folder via: `gpg --export-secret-keys --armor -o gpg_private_key`

* Add your private keys passphrase via vim or `echo "$MY_PASSPHRASE" > gpg_passphrase`