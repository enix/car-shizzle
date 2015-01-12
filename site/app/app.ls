module.exports = class App

    ~>
        $('#price-slider').slider {
            range: true
            min: 500
            max: 20000
            step: 500
            values:[2000, 15000]
            change: ( event, ui ) ~>
                $( '#price-range' ).val( "€" + ui.values[ 0 ] + " - €" + ui.values[ 1 ] )
                this.update-chart()
        }

        $('#milage-slider').slider {
            range: true
            min: 5000
            max: 200000
            step: 10000
            values:[10000, 200000]
            change: ( event, ui ) ~>
                $( '#milage-range' ).val( ui.values[ 0 ] + " km - " + ui.values[ 1 ] + " km" )
                this.update-chart()

        }

        $('#x-axis').change ~> @update-chart()


    colors = {
        'bmw-3-serie'       : 'rgb(77, 77, 77)'
        'bmw-5-serie'       : 'rgb(241, 124, 176)'
        'skoda-octavia'     : 'rgb(93, 165, 218)'
        'audi-a4'           : 'rgb(250, 164, 58)'
        'audi-a6'           : 'rgb(178, 118, 178)'
        'volvo-v50'         : 'rgb(96, 189, 104)'
        'volvo-v70'         : 'rgb(178, 145, 47)'
        'volkswagen-passat' : 'rgb(96, 189, 104)'
    }

    # rgb(222, 207, 63) (yellow)
    # rgb(241, 88, 84) (red)


    drawChart: (series, xLabel) ->

        options =
            chart:
                renderTo: 'chart'
                type: 'scatter'
                zoomType: 'xy'

            series: series

            xAxis:
                title:
                    enabled: true,
                    text: xLabel
                allowDecimals: true,
                startOnTick: true,
                endOnTick: true,
                showLastLabel: true,
                #min:0,
                #max:50000

            yAxis:
                title:
                    text: 'prijs (€)'
                min:0
                labels:
                    formatter: -> Highcharts.numberFormat(this.value, 0, ',', '.')
            legend:
                layout: 'vertical'
                align: 'left'
                verticalAlign: 'bottom'
                x: 80
                y: -30
                floating: true
                backgroundColor: '#FFFFFF'
                borderWidth: 1

            plotOptions:
                series:
                    cursor: 'pointer'
                    point:
                        events:
                            click: -> window.open("http://www.autotrader.nl/#{this.options.url}", '_blank')

                scatter:
                    marker:
                        radius: 5
                        states:
                            hover:
                                enabled: true,
                                lineColor: 'rgb(100,100,100)'
                    states:
                        hover:
                            marker:
                                enabled: false

            title:
                text: 'car shizzle'

            subtitle:
                text: 'Source: autotrader.nl'

            tooltip:
                useHTML: true
                headerFormat: '<small>{point.title}</small><table>'
                pointFormat: '<tr><td style="color: {series.color}">{series.name}: </td><td style="text-align: right"><b>{point.y} EUR</b></td></tr>'
                footerFormat: '</table>'
                formatter: ->
                    '<table style="height:180px"><tr><td>' +
                    '<b>' + this.point.type + '</b>' +
                    '<br/><b>Milage:</b> '  + this.point.milage +
                    '<br/><b>Price:</b> '   + this.point.price +
                    '<br/><b>Date:</b> '    + this.point.date +
                    '<br/><b>Title:</b> '   + this.point.title +
                    '</td>' +
                    '<td>' +
                    '<br/><img style="width:175px;margin-top:-10px" src="' + this.point.picture + '">' +
                    '</td></tr></table>' ;
                valueDecimals: 2

        new Highcharts.Chart options

    update-chart: ~>

        xLabel = ''

        _car_x_value = (c) ~>
            switch $('#x-axis').val()
            case 'milage'
                xLabel := 'kilometers'
                c.milage
            case 'months'
                xLabel := 'maanden'
                c.months
            case 'milage-per-month'
                xLabel := 'kilometers per maand'
                c.milage / c.months
            case 'milage-per-price'
                xLabel := 'kilometer per prijs'
                c.milage / c.price

        series =
            _.chain (this.cars)
                .pairs()
                .map (pair) ~>
                    {
                        name : _.head(pair)
                        data : _.map (this.filter _.last(pair)), (c) ~> _.extend c, {x: _car_x_value(c), y: c.price}
                        color: colors[_.head(pair)]
                        marker:
                            symbol: 'circle'
                    }
                .value()

        this.drawChart series, xLabel


    filter: (cars) ->
        price-range = $('#price-slider').slider( "values" )
        milage-range = $('#milage-slider').slider( "values" )

        _.chain(cars)
            .filter (car) -> _.first(price-range) <= car.price && car.price <= _.last(price-range)
            .filter (car) -> _.first(milage-range) <= car.milage && car.milage <= _.last(milage-range)
            .value()


    init: ~>
        $.when $.getJSON('./data/cars.json')
        .then (cars) ~>
            this.cars = cars
            this.update-chart()
