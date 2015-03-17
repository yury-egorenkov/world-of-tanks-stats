# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

splitDomain = (domain) ->
  [domain[0], (domain[1] - domain[0]) / 2, domain[1]]

tankImageUrl = (d, axis) ->
    # Add armor colors to image url
    params = ['Лоб', 'Борт', 'Корма', 'Лоб-башни', 'Борт-башни', 
      'Корма-башни'].map( (x) ->
        x + "=" + axis(d[x]).replace(/#/, '')
      )

    encodeURI("/home/tank_image/" + d["image"].replace(/\.[^\.]+$/, '') + '?' + params.join('&'))

ready = ->
  tankSize = 150

  margin = 
    top: 10
    right: 50
    bottom: 30
    left: 50

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

  r = d3.scale.linear().range([3, 10])

  armor = d3.scale.linear().range(['#FF0000', '#FFB72B', '#00CE00'])

  d3.json '/data.json', (tanksData) ->

    x_dimension = "Скорость"
    y_dimension = "Макс. урон за 10 сек"

    x.domain( d3.extent( tanksData, (d) -> d[x_dimension] ))
    y.domain( d3.extent( tanksData, (d) -> d[y_dimension] ))
    r.domain( d3.extent( tanksData, (d) -> d["Прочность"] ))

    armorDomain = d3.extent(tanksData, (d) -> d["Бронепр-ть базовая"])
    armor.domain(splitDomain(armorDomain))

    $('.armor-legend .step').each( (d) -> 
      $(this).css('background-color', armor($(this).text()))
    )

    svg.append('g')
      .attr("class", "x axis")
      .attr('transform', 'translate(0,' + height + ')')
      .call(d3.svg.axis().scale(x).orient('bottom'))

    svg.append('g')
      .attr("class", "y axis")
      .call( d3.svg.axis().scale(y).orient('left') )

    tank = svg.selectAll('g.tank')
           .data(tanksData)
           .enter()
           .append('g')
           .attr('class', (d) -> 
            'tank ' + d["country"].toLowerCase() + ' ' + d["tank_type"] + ' level' + d["level"]
           )
           .attr('opacity', (d) -> 
              d["visible"] = d["country"] == "Ru" && d["tank_type"] == "middle"

              if d["visible"] 
                return 1

              return 0
           )

    tank.append("svg:image")
      .attr('class', 'tank-image')
      .attr('x', (d) -> x(d[x_dimension]) - 30)
      .attr('y', (d) -> y(d[y_dimension]) - tankSize / 2 + 20)
      .attr('width', tankSize)
      .attr('height', tankSize)
      .attr('xlink:href', (d) -> tankImageUrl(d, armor))

    tank.append("svg:image")
      .attr('class', 'flag')
      .attr('x', (d) -> x(d[x_dimension]) - 50)
      .attr('y', (d) -> y(d[y_dimension]) - 10)
      .attr('width', 33)
      .attr('height', 20)
      .attr('xlink:href', (d) ->
        "/assets/flag-" + d["country"].toLowerCase() + ".jpg"
      )
        
    tank.append('circle')
      .attr('r', (d) -> r(d["Прочность"]))
      .attr('fill', (d) -> armor(d["Бронепр-ть базовая"]))
      .attr('cx', (d) -> x(d[x_dimension]))
      .attr('cy', (d) -> y(d[y_dimension]))

    tank.append('text')
      .attr('dx', 10)
      .attr('dy', 5)
      .text((d) -> d["name"])
      .attr('x', (d) -> x(d[x_dimension]))
      .attr('y', (d) -> y(d[y_dimension]))
      .attr('class', 'label')

    update = ->
      tank.selectAll(".tank-image")
        .transition()
        .duration(1500)
        .attr('x', (d) -> x(d[x_dimension]) - 30)
        .attr('y', (d) -> y(d[y_dimension]) - tankSize / 2 + 20)
        .attr('width', tankSize)
        .attr('height', tankSize)

      tank.selectAll(".flag")
        .transition()
        .duration(1500)
        .attr('x', (d) -> x(d[x_dimension]) - 50)
        .attr('y', (d) -> y(d[y_dimension]) - 10)
        .attr('width', 33)
        .attr('height', 20)

      tank.selectAll('circle')
        .transition()
        .duration(1500)
        .attr('r', (d) -> r(d["Прочность"]))
        .attr('fill', (d) -> armor(d["Бронепр-ть базовая"]))
        .attr('cx', (d) -> x(d[x_dimension]))
        .attr('cy', (d) -> y(d[y_dimension]))

      tank.selectAll('text')
        .transition()
        .duration(1500)
        .attr('dx', 10)
        .attr('dy', 5)
        .text((d) -> d["name"])
        .attr('x', (d) -> x(d[x_dimension]))
        .attr('y', (d) -> y(d[y_dimension]))
        .attr('class', 'label')        

    increaseExtent = (extent, delta) ->
      diff = (extent[1] - extent[0]) * delta
      return [extent[0] - delta, extent[1] + delta]

    changeAxis = ->
      x_extent = d3.extent( tanksData, (d) -> 
        if d["visible"]
          return d[x_dimension] 

        return null
      )
      x.domain( increaseExtent(x_extent, 0.2) )

      y_extent = d3.extent( tanksData, (d) ->
        if d["visible"]
          return d[y_dimension] 

        return null        
      )
      y.domain( increaseExtent(y_extent, 0.2) )

      svg.selectAll('g.y.axis')
        .transition()
        .duration(1500)
        .ease("sin-in-out")
        .call( d3.svg.axis().scale(y).orient('left') )

      svg.selectAll('g.x.axis')
        .transition()
        .duration(1500)
        .ease("sin-in-out")
        .call( d3.svg.axis().scale(x).orient('bottom') )

      update()



    # Change dimensions
    $('.dropdown-menu li a').click (el) ->
      btn = $(this).parents(".btn-group").find('.btn')
      btn.html( $(this).text() + ' <span class="caret"></span>' )

      axis = btn.attr('axis')
 
      if (axis == 'x')        
        x_dimension = $(this).text()

      if (axis == 'y') 
        y_dimension = $(this).text()

      changeAxis()


    $('.filters .btn').click ->
      $(this).toggleClass('active')

      countries = $.makeArray( $('.countries .active').map (i, d) ->
        $(d).attr 'value'
      )

      tankTypes = $.makeArray( $('.tank-types .active').map (i, d) ->
        $(d).attr 'value'
      )

      levels = $.makeArray( $('.levels .active').map (i, d) ->
        parseInt( $(d).attr('value') )
      )

      svg.selectAll('g.tank')
        .transition()
        .duration(1500)
        .attr('opacity', (d) ->
                    
          d["visible"] = countries.indexOf(d["country"]) != -1 &&
              tankTypes.indexOf(d["tank_type"]) != -1 &&
              levels.indexOf( d["level"] ) != -1
          
          if d["visible"] 
            return 1 

          return 0
        )


      changeAxis()
            



$(document).ready(ready)
$(document).on('page:load', ready)
