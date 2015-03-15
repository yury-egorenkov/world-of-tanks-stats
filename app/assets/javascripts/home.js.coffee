# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

splitDomain = (domain) ->
  [domain[0], (domain[1] - domain[0]) / 2, domain[1]]

ready = ->
  margin = 
    top: 10
    right: 50
    bottom: 30
    left: 40

  width = 1170 - margin.left - margin.right
  height = 500 - margin.top - margin.bottom

  svg = d3
      .select('.chart')
      .append('svg')
      .attr('width', width + margin.left + margin.right)
      .attr('height', height + margin.top + margin.bottom)
      .append('g')
      .attr('transform', 
            'translate(' + margin.left + ',' + margin.top + ')')

  x = d3.scale.linear().range([0, width])

  y = d3.scale.linear().range([height, 0])

  r = d3.scale.linear()
        .range([3, 10])

  armor = d3.scale.linear()
            .range(['#5cb85c', '#f0ad4e', '#d9534f'])


  d3.json 'http://localhost:3000/data.json', (tanksData) ->

    x.domain d3.extent(tanksData, (d) ->
      d["Скорость"]
    )

    y.domain d3.extent(tanksData, (d) ->
      d["Макс. урон за 10 сек"]
    )

    r.domain d3.extent(tanksData, (d) ->
      d["Прочность"]
    )

    armorDomain = d3.extent(tanksData, (d) -> d["Бронепр-ть базовая"])
    armor.domain(splitDomain(armorDomain))

    $('.armor-legend .step').each( (d) -> 
      $(this).css('background-color', armor($(this).text()))
    )

    svg.append('g')
      .attr('transform', 'translate(0,' + height + ')')
      .call d3.svg.axis().scale(x).orient('bottom')

    svg.append('g')
      .call d3.svg.axis().scale(y).orient('left')

    g = svg.selectAll('g.point')
           .data(tanksData)
           .enter()
           .append('g')
           .attr('class', 'point')
           .filter((d) -> d["country"] == "Ru" && d["tank_type"] == "Средние")

    # g.append('circle')
    #   .attr('r', (d) -> r(d["Прочность"]))
    #   .attr('fill', (d) -> armor(d["Бронепр-ть базовая"]))
    #   .attr('cx', (d) -> x(d["Скорость"]))
    #   .attr('cy', (d) -> y(d["Макс. урон за 10 сек"]))
    #   g.append('text')
    #     .attr('dx', 10)
    #     .attr('dy', 5)
    #     .text((d) -> d["name"])
    #     .attr('x', (d) -> x(d["Скорость"]))
    #     .attr('y', (d) -> y(d["Макс. урон за 10 сек"]))

    g.append("svg:image")
      .attr('x', (d) -> x(d["Скорость"]) - 80 / 2)
      .attr('y', (d) -> y(d["Макс. урон за 10 сек"]) - 80 / 2)
      .attr('width', 80)
      .attr('height', 80)
      .attr('xlink:href', (d) -> "assets/tanks/" + d["image"])
      .attr 'tank', (d) -> 
        $('#Лоб *').css({ fill: armor(d["Лоб"]) })
        $('#Борт *').css({ fill: armor(d["Борт"]) })
        $('#Корма').css({ fill: armor(d["Корма"]) })
        $('#Лоб-башни').css({ fill: armor(d["Лоб башни"]) })
        $('#Борт-башни').css({ fill: armor(d["Борт башни"]) })
        $('#Корма-башни').css({ fill: armor(d["Корма башни"]) })
        
      g.append('text')
        .attr('dx', 40)
        .attr('dy', 5)
        .text((d) -> d["name"])
        .attr('x', (d) -> x(d["Скорость"]))
        .attr('y', (d) -> y(d["Макс. урон за 10 сек"]))



$(document).ready(ready)
$(document).on('page:load', ready)
