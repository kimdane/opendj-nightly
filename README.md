# ForgeRock OpenDJ nightly build

Listens on 389/636/4444

Default bind credentials are CN=Directory Manager, password is 'password'

All writable directories (persisted data) are collected up under /opt/opendj/instances/instance1

If you choose not to mount a persistent volume OpenDJ will start OK - but you will lose your data when the container is removed.

Ready for fullStack example of ForgeRocks Identity Stack Dockerized