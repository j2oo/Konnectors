cozydb = require 'cozydb'
request = require 'request'
moment = require 'moment'
cheerio = require 'cheerio'
fs = require 'fs'

File = require '../models/file'
fetcher = require '../lib/fetcher'
#filterExisting = require '../lib/filter_existing'
#saveDataAndFile = require '../lib/save_data_and_file'

localization = require '../lib/localization_manager'

log = require('printit')
    prefix: "VeoliaEau"
    date: true


# Models

Consumption = cozydb.getModel 'Consumption',
    date: Date
    vendor: String
    target: String
    meter: Number
    unit: String
    period: String
    estimated: {type: Boolean, default: false}


Consumption.all = (callback) ->
    Consumption.request 'byDate', callback

# Konnector

module.exports =

    name: "VeoliaEau"
    slug: "veolia"
    description: 'konnector description VeoliaEau'
    vendorLink: "https://www.service-client.veoliaeau.fr/"

    fields:
        login: "text"
        password: "password"
        target: "text"
    models:
        consumption: Consumption

    # Define model requests.
    init: (callback) ->
        map = (doc) -> emit doc.date, doc
        Consumption.defineRequest 'byDate', map, (err) ->
            callback err

    fetch: (requiredFields, callback) ->

        log.info "Import started"

        fetcher.new()
            .use(logIn)
            .use(parsePage)
#            .use(filterExisting log, Consumption)
#            .use(saveDataAndFile log, Consumption, 'VeoliaEau', ['consumption'])
            .args(requiredFields, {}, {})
            .fetch (err, fields, entries) ->
                log.info "Import finished"

                notifContent = null
                if entries?.filtered?.length > 0
                    localizationKey = 'notification VeoliaEau'
                    options = smart_count: entries.filtered.length
                    notifContent = localization.t localizationKey, options

                callback err, notifContent

# Procedure to login to VeoliaEau website.
logIn = (requiredFields, consumptionInfos, data, next) ->

    loginUrl = "https://www.service-client.veoliaeau.fr/home/connexion-espace-client.loginAction.do"
    ConsumptionUrl = "https://www.service-client.veoliaeau.fr/home/espace-client/votre-consommation.updateReleveGraph.do"
    GetConsumptionUrl = "https://www.service-client.veoliaeau.fr/home/espace-client/votre-consommation.html?vueConso=releves"

    form =
        "veolia_password": requiredFields.password
        "veolia_username": requiredFields.login

    options =
        method: 'POST'
        form: form
        jar: true
        url: loginUrl

    log.info "Before logIn"

    request options, (err, res, body) ->

        isNoLocation = not res.headers.location?
        isNot302 = res.statusCode isnt 302
        isError = res.headers.location? and \
            res.headers.location.indexOf("error") isnt -1

        if err or isNoLocation or isNot302 or isError
            log.error "Authentification error"
            next 'bad credentials'
        else
            log.info "logIn OK"

            form =
              vueConso: "releves"
              periode_releve: "jour"
              dateDeb_releve: ""
              moisDeb_releve: "01/04/2015"
              dateFin_releve: ""
              moisFin_releve: "01/03/2016"
              donnee_releve: "données"
              mesure_releve: "m3" 
              btnAfficher_releve: "" 
              veoliaFormName: "formulaireConso_releve"
              veoliaFormValue: "null"

            options =
                method: 'POST'
                form: form
                jar: true
                url: ConsumptionUrl

            request options, (err, res, body) ->

                isNoLocation = not res.headers.location?
                isNot302 = res.statusCode isnt 302
                isError = res.headers.location? and \
                    res.headers.location.indexOf("error") isnt -1

            if err or isNoLocation or isNot302 or isError
                log.error "Authentification error"
                next 'bad credentials'

            else
                log.info "ConsumptionUrl OK"

                location = res.headers.location
                parameters = location.split('?')[1]
                url = "#{GetConsumptionUrl}?#{parameters}"
                request.get url, (err, res, body) ->
                    if err then next err
                    else
                        log.info "GetConsumption OK"
                        data.html = body
                        next()


# Parse the fetched page to extract bill data.
parsePage = (requiredFields, comsumption, data, next) ->

    consumption.fetched = []

    return next() if not data.html?

    $ = cheerio.load data.html
    $('table.table_box3 tbody tr').each ->

        log.info "Content $$(this).html()"

        consumption =
            date: moment '01/04/2016'
            vendor: 'VeoliaEau'
            target: 'Test'
            meter: 333.12
            unit: 'm3'
            estimated: true

    next()
