Transactions = new Meteor.Collection 'transactions'
Meta = new Meteor.Collection 'meta'

Meteor.publish 'userData', () ->
    Meteor.users.find {}, {fields: {username: 1, _id: 1}}
        
Meteor.publish 'transactions', () ->
    Transactions.find {}, {sort: {addDate: -1}, limit: 100}

Meteor.publish 'meta', () ->
    Meta.find {}

Meteor.startup () ->
    cp = Meta.findOne {currentCoffeePrice: {$exists: true}}
    unless cp?
        Meta.insert {currentCoffeePrice: 0.25}
    
Meteor.methods
    'setCoffeePrice': (amount) ->
        user = Meteor.users.findOne {_id: @userId}
        if user.username is 'admin'
            Meta.update {currentCoffeePrice: {$exists: true}}, {currentCoffeePrice: amount}
        