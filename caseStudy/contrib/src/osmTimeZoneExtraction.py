import pandas as pd

# Extraction of the data from OpenFlights
url = 'https://raw.githubusercontent.com/jpatokal/openflights/master/data/airports.dat'
airports = pd.read_csv(url,na_values=['\\N'])

airports.columns = ["AirportID","Name","City","Country","IATA","ICA","Latitude","Longitude",
                    "Altitude","Timezone","DST","Tz","Type","Source"]

# Extraction of Canadian airports
# print(airports.loc[(airports.Country == "Canada")])
airportsCanada = airports.loc[(airports.Country == "Canada")]
print(pd.DataFrame(airportsCanada,columns=["Latitude","Longitude"]))

from timezonefinder import TimezoneFinder
tf = TimezoneFinder()
mergedTz = list()
for i in pd.DataFrame(airportsCanada,columns=["Latitude","Longitude"]).iterrows():
    lng = i[1][1]
    lat = i[1][0]
    try:
        timezone_name = tf.timezone_at(lng=lng, lat=lat)
        if timezone_name is None:
            timezone_name = tf.closest_timezone_at(lng=lng, lat=lat)
        # maybe even increase the search radius when it is still None

    except ValueError:
    # the coordinates were out of bounds
        print("No timezone identified for " + lng + lat)
        timezone_name = None
    # ... do something with timezone_name ...
    print(timezone_name)
    mergedTz.append(timezone_name)

print(mergedTz)
print(len(mergedTz))
airportsCanada = airportsCanada.assign(MergedTz=mergedTz)
print(airportsCanada[1:10])

divergence = airportsCanada.loc[(airportsCanada.MergedTz != airportsCanada.Tz)]
path = "C:\\Users\\Samuel\\Desktop\\tz.txt"
fileTz = open(path,"w")
x = divergence.dropna(subset=["Tz", "MergedTz"])

print(x)
