# X-Road Management utilities and health checks

## Check X-Road Security Server health
The following script checks X-Road Security servers health by running it locally on the security server.
check_xroad_health script will check the following
- Connection to central servers using netcat
-

This will run the script and test against connectivity to the central development servers
```shell
curl -s https://raw.githubusercontent.com/opinkerfi/xroad-management/main/scripts/check_xroad_health.sh | bash
```

You can also download the script and run it manually and test connectivity to central development servers
```shell
curl -s -o check_xroad_health.sh https://raw.githubusercontent.com/opinkerfi/xroad-management/main/scripts/check_xroad_health.sh
bash check_xroad_health.sh dev

```


