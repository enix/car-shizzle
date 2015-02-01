require! {
  'cheerio'
  'queue'
  'prelude-ls': {map, filter, each, first, last, flatten, concat, group-by}
  'q-io/http': {request}
  'q'
  'fs'
}

cars = ['bmw-3-serie','bmw-5-serie','skoda-octavia','audi-a4','audi-a6','volvo-v70','volvo-v50','volkswagen-passat']
#cars = ['volkswagen-passat']

autotrader_nl = "www.autotrader.nl"
car_db = []

#
# explode the pagination urls for the given car
#
explode_paginations = (car) ->

  console.log "processing #car"

  params =
    path: "/auto/#car/carrosserie--stationwagen/brandstof--benzine/?zoekopdracht=transmissie--automaat%2Fsoort-voertuig--alleen-occasions"
    host: autotrader_nl

  request params
    .then (response) ->
      response.body.read()
    .then (body) ->
      $ = cheerio.load body.toString('utf8')
      last_page = $('#pager li').last().text() |> parseInt
      concat [["#{params.path}"], [2 to last_page] |> map (it) -> "#{params.path}%2F#it"]

#
# create a scape task with the given URL
#
scrape_task = (url) ->

  console.log url

  # scrape car information
  _car_details = ($) ->

    _car_type = (url) ->
      url.split('/')[2]

    # euries
    _car_price = (elem) ->
      text = $(elem).find('.result-price-label').text()
      text.split ' ' |> last |> (.replace '.', '') |> parseInt

    # months
    _car_months = (elem) ->
      text = $($(elem).find('.result-main-attributes .col-left b').0).text()
      parts = text.split ' '

      month_names = ['jan','feb', 'mrt','apr', 'mei', 'jun', 'jul', 'aug', 'sep', 'okt', 'nov', 'dec']

      year = parts |> last |> parseInt
      months = parts |> first |> (.toLowerCase()) |> month_names.indexOf _

      ((2015 - year) * 12) + months + 1

    # date as text
    _car_date = (elem) ->
      $($(elem).find('.result-main-attributes .col-left b').0).text()

    # kms
    _car_milage = (elem) ->
      text = $($(elem).find('.result-main-attributes .col-left b').1).text()
      if (text == 'onbekend') then return -1
      text.split ' ' |> first |> (.replace '.', '') |> parseInt

    _car_picture = (elem) ->
      text = $(elem).find('img').attr('src')
      if text.indexOf("no-image-small.png") > 0 then
        "http://#autotrader_nl#text"
      else
        text

    result = $('.result').not('.result-top-container').map (i, elem) ->
      id      : $(elem).find('.ad-pos').attr('id')
      title   : $(elem).find('a').attr('title')
      type    : _car_type url
      price   : _car_price elem
      months  : _car_months elem
      date    : _car_date elem
      milage  : _car_milage elem
      picture : _car_picture elem
      url     : $(elem).find('a').attr('href')

    result.get()

  # scrape sequence
  (done) ->
    params =
      path: url
      host: autotrader_nl

    request params
      .then (response) ->
        response.body.read()
      .then (body) ->
        $ = cheerio.load body

        _car_details($)
          |> filter (.price)  # remove 'op aanvraag' & verkocht
          |> filter (it) -> it.title.toLowerCase().indexOf('verkocht') == -1
          |> car_db.push _

        done()
      .fail (error) ->
        console.log error

#
# entry point
#

scraper_queue = queue do
  concurrency:50
  timeout:20000

pagination_requests = cars |> map explode_paginations

q.allSettled(pagination_requests)
  .then (urls) ->

    urls
      |> map (.value)
      |> flatten
      |> map scrape_task, _
      |> each scraper_queue.push _

    scraper_queue.start (err) ->
      cars = flatten car_db
      console.log "total cars:#{cars.length}"
      result = JSON.stringify(group-by (.type), cars)
      fs.writeFile "../site/app/assets/data/cars.json", result, (err) ->
        if(err)
          console.log(err)
        else
          console.log("saving")

  .fail (error) ->
      console.log error
