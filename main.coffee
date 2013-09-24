if Meteor.isClient
    
    Deps.autorun () ->
        Meteor.subscribe 'userData'
        Meteor.subscribe 'transactions'
        Meteor.subscribe 'meta'
    
    moment.lang 'de'
    
    Accounts.ui.config
        passwordSignupFields: 'USERNAME_ONLY'
    
    Meta = new Meteor.Collection 'meta'
    Transactions = new Meteor.Collection 'transactions'
    TransientTransactions = new Meteor.Collection null
    
    currentCoffeePrice = () ->
        cp = Meta.findOne {currentCoffeePrice: {$exists: true}}
        cp?.currentCoffeePrice
    
    parseAmountString = (str) ->
        transformed = str.replace /,/, '.'
        number = Number transformed.replace /[^0-9\.]+/g, ''
        rounded = (Math.round(number * 100)) / 100
        if rounded?
            rounded
        else
            null
        
    Template.newInvestments.transactions = () ->
        TransientTransactions.find {finType: 'investment'}, {sort: {addDate: -1}}
    
    Template.newWithdrawels.transactions = () ->
        TransientTransactions.find {finType: 'withdrawel'}, {sort: {addDate: -1}}
    
    Template.newTransaction.user = () ->
        Meteor.users.findOne({_id: @user})?.username

    Template.newTransaction.dateAdded = () ->
        moment(@addDate).fromNow()

    Template.newTransaction.types = (i) ->
        if i.finType is 'investment'
            [{name: 'Einzahlung', selected: () -> i.type is @name}
            {name: 'Bohnen', selected: () -> i.type is @name}
            {name: 'Anschaffung', selected: () -> i.type is @name}
            {name: 'Wartung', selected: () -> i.type is @name}
            {name: 'Sonstiges', selected: () -> i.type is @name}]
        else if i.finType is 'withdrawel'
            [{name: 'Entnahme', selected: () -> i.type is @name}]

    Template.newTransaction.events = 
        'submit form': (e) -> 
            e.preventDefault()
            
            type = $(e.target).find('select').val()
            amountStr = $(e.target).find('input').val() 
            amount = parseAmountString(amountStr)
            
            if @finType is 'withdrawel'
                if amount > 0
                    amount = amount * -1
            else if @finType is 'investment'
                if amount < 0
                    amount = amount * -1
                
            if amount?
                Transactions.insert 
                    user: @user
                    amount: amount
                    type: type
                    addDate: @addDate
                    
                TransientTransactions.remove {_id: @_id}
            
            
    Template.history.transactions = () ->
        Transactions.find {}, {sort: {addDate: -1}}
        
    Template.transaction.amount = () ->
        @amount.toFixed 2
        
    Template.transaction.finType = () ->
        if @amount > 0
            'investment'
        else
            'withdrawel'
    
    Template.transaction.dateAdded = () ->
        moment(@addDate).fromNow()
    
    Template.transaction.user = () ->
        Meteor.users.findOne({_id: @user})?.username
    
    Template.header.costPerCoffee = () ->
        currentCoffeePrice()
        
    Template.header.userSaldo = () ->
        user = Meteor.userId()
        sum = 0
        if user?
            Transactions.find({user: user}).forEach (e) ->
                sum = sum + parseFloat(e.amount)
        sum.toFixed 2

    Template.header.totalSaldo = () ->
        sum = 0
        Transactions.find({}).forEach (e) ->
            sum = sum - parseFloat(e.amount)
        sum.toFixed 2

    Template.header.events
        'click button.add-coffee': () ->
            Transactions.insert
                user: Meteor.userId()
                amount: -1 * currentCoffeePrice()
                type: 'Kaffee'
                addDate: new Date
        'click button.add-investment': () ->
            TransientTransactions.insert
                user: Meteor.userId()
                amount: 0
                type: 'Bohnen'
                finType: 'investment'
                addDate: new Date
        'click button.add-withdrawel': () ->
            TransientTransactions.insert
                user: Meteor.userId()
                amount: 0
                type: 'Entnahme'
                finType: 'withdrawel'
                addDate: new Date
        