# influx2gpx
influxdb gps data to gpx

Example:
env RANGESTART=$(date --utc +'%s' --date "2022-07-02") RANGESTOP=$(date --utc +'%s' --date "2022-07-14") iflx2gpx.sh >/tmp/02to14Jul2022.gpx
