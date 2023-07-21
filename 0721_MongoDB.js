show collections
db.mycollection.drop()
db.createCollection("mycollection")
db.createCollection("cappedCollection", {capped:true, size:1000})
db.cappedCollection.insertOne({x:1})
db.cappedCollection.find()
for(i=0; i<1000; i++){db.cappedCollection.insertOne({x:1})}