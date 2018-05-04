command: "ps aux | awk '{cpu+=$3;mem+=$4} END {print cpu;print mem}'"

refreshFrequency: 1000

render: (output) -> """
  <link rel="stylesheet" href="sys-monitor.widget/lib/epoch/epoch.min.css">
  <div id="sys-monitor", class="dark epoch-theme-dark">
    <ul class="primary">
      <li id="model"></li>
      <li id="processor"></li>
    </ul>
    <ul class="secondary">
      <li>CPU <span id="cpu"></span></li>
      <li>MEM <span id="mem"></span></li>
    </ul>
    <div id="chart" class="epoch category20"></div>
  </div>
"""

chart: null

sysctl:
  logicalcpu: 0
  memsize: 0

getTime: -> new Date().getTime() / 1000

afterRender: (domEl) ->
  $.getScript "sys-monitor.widget/lib/d3/d3.min.js.lib", =>
    $.getScript "sys-monitor.widget/lib/epoch/epoch.min.js.lib", =>
      @chart = $(domEl).find('#chart').epoch
        type: 'time.line'
        fps: 20
        queueSize: 120
        axes: ['bottom', 'right', 'left']
        tickFormats:
          bottom: (value) ->
            date = new Date(value * 1000)
            date.toLocaleTimeString()
          right: (value) ->
            value + ' %'
          left: (value) ->
            value + ' %'
        data: [
          {label: 'CPU', values: [{time: @getTime(), y: 0}]}
          {label: 'MEM', values: [{time: @getTime(), y: 0}]}
        ]

  @run "system_profiler SPHardwareDataType", (err, stdout) =>
    model = stdout.match(/Model Name: ([,\.0-9a-z ]+)/i)[1]
    $(domEl).find('#model').text(model)

    @run "sysctl -n machdep.cpu.brand_string; sysctl -n hw.logicalcpu; sysctl -n hw.memsize", (err, stdout) =>
      [cpubrand, @sysctl.logicalcpu, @sysctl.memsize] = stdout.split("\n")
      $(domEl).find('#processor').text(cpubrand)

update: (output, domEl) ->
  if @sysctl.logicalcpu > 0 and @sysctl.memsize > 0
    [cpu, mem] = output.split("\n")
    mem_per = parseFloat(mem)
    mem_per = 100 if mem_per > 100
    cpu_per = cpu / @sysctl.logicalcpu
    mem_gb = @sysctl.memsize / 1024 / 1024 / 1024
    mem_occ = (mem_per / 100) * mem_gb

    $(domEl).find('#cpu').text("#{cpu_per.toFixed(2)} %")
    $(domEl).find('#mem').text("#{mem_per.toFixed(2)} % / #{mem_occ.toFixed(2)} GB / #{mem_gb.toFixed(2)} GB")

    @chart.push([
      {time: @getTime(), y: cpu_per}
      {time: @getTime(), y: mem_per}
    ]) if @chart?

style: """
  top: 20px
  left: 20px

  *
    box-sizing: border-box

  #sys-monitor
    font-family: "Helvetica Neue"
    font-weight: 300
    font-size: 14px
    border-radius: 5px
    padding: 15px

    &.light
      background: rgba(255, 255, 255, .6)
      color: lighten(#000, 10%)

    &.dark
      background: rgba(0, 0, 0, .6)
      color: darken(#fff, 10%)

    #chart
      margin-top: 15px
      height: 200px

    ul
      list-style: none
      margin: 0 0 5px 0
      padding: 0
      overflow: hidden

      li:first-child
        float: left
        width: 200px
      li:last-child
        float: right
        width: 300px
        text-align: right

      &.primary
        li:last-child
          font-size: 10px

      &.secondary
        li
          font-size: 10px
"""
