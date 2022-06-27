#! /bin/bash

usage () {
    echo "USAGE: $0"
    echo "mandatory environment variables:"
    echo "INFLUXURL: influxdb url, eg: https://influxb.local"
    echo "INFLUXORG, INFLUXBUCKET: organization and bucket"
    echo "INFLUXTOKEN: access token, need read permission on bucket"
    echo "DEVICE: which device"
    exit 1
}

[[ -r secret.sh ]] && source secret.sh

if [[ -z "${INFLUXURL}" ]] || [[ -z "${INFLUXORG}" ]] || [[ -z "${INFLUXBUCKET}" ]] || [[ -z "${INFLUXTOKEN}" ]] || [[ -z "${DEVICE}" ]]; then
    usage
fi

RANGESTART=${RANGESTART:-0}
RANGESTOP=${RANGESTOP:-$(date --utc +'%s')}

curl --silent \
     --request POST ${INFLUXURL}/api/v2/query?org="${INFLUXORG}" \
     --header "Authorization: Token ${INFLUXTOKEN}" \
     --header 'Accept: application/csv' \
     --header 'Content-type: application/vnd.flux' \
     --data "import \"experimental/geo\"

from(bucket: \"${INFLUXBUCKET}\")
  |> range(start: ${RANGESTART}, stop: ${RANGESTOP})
  |> filter(fn: (r) => r[\"device\"] == \"${DEVICE}\")
  |> geo.shapeData(latField: \"lat\",lonField: \"lon\",level: 21)
  |> keep(columns: [\"_time\",\"accuracy\",\"elevation\",\"lat\",\"lon\",\"sat_count\",\"speed\"])
  |> filter(fn: (r) => r[\"elevation\"] >= 0 and r[\"accuracy\"] < 2.0)
  |> group(columns: [\"_time\"])" \
    | cut -d, -f 3- \
    | sed -e 's/table/No/' -e 's/_time/utc_d,utc_t/' -e 's/accuracy/depth/' -e 's/elevation/alt/' -e 's/sat_count/sat/' \
    | sed -e 's/\([0-9\-]*\)T\([0-9:]*\)Z,/\1,\2,/' \
    | docker run -i --rm giacinti/gpsbabel -i unicsv -f - -x transform,trk=wpt,del -o gpx -F - 

